#!/usr/bin/env bash
# A rehearsal of stop, checkpoint and resume on a toy ninja project: nothing is compiled.
# Takes about half a minute; needs ninja, zstd and python3.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
t=$(mktemp -d)
trap 'rm -rf "$t"' EXIT
w=$t/engine
mkdir -p "$w/src" "$w/build/inner" "$w/state"

{
    echo 'rule slow'
    echo '  command = sleep 1 && cp $in $out && echo $out >> '"$w/state/ran"
    all=
    for i in $(seq 1 30); do
        echo "$i" > "$w/src/$i.in"
        echo "build o$i: slow ../../src/$i.in"
        all="$all o$i"
    done
    echo "build all: phony$all"
} > "$w/build/inner/build.ninja"
find "$w/src" -exec touch -h -d '2020-01-01 00:00:00 UTC' {} +

run() { # minutes, extra arguments
    local minutes=$1
    shift
    python3 -I "$here/supervise.py" --build "$w/build" --state "$w/state" --inner "$w/build/inner" --target all \
        --minutes "$minutes" --interval 0.2 --min-free-disk 0 --min-headroom 0 --max-swap-used 10000 --max-pressure 101 \
        --command "[\"ninja\", \"-C\", \"$w/build/inner\", \"-j3\", \"all\"]" "$@" > "$t/supervise.log"
}
field() { python3 -I -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]])' "$w/state/report.json" "$1"; }
fail() { echo "FAIL: $*" >&2; cat "$t/supervise.log" >&2; exit 1; }

# 1. a stretch that runs out of time stops cleanly, part of the work done
run 0.06
[ "$(field reason)" = time ] || fail "reason $(field reason)"
[ "$(field forced_kill)" = False ] || fail "had to kill"
left=$(field remaining_after)
[ "$left" -gt 0 ] && [ "$left" -lt 30 ] || fail "left $left"
done_first=$(wc -l < "$w/state/ran")
echo "stopped on time with $left of 30 left"

# 2. pack, throw everything away, restore; ninja must see the same work left
"$here/checkpoint.sh" pack "$w" "$t/cp.tar.zst" > /dev/null
sha=$(cat "$t/cp.tar.zst.sha256")
rm -rf "$w"
cp "$t/cp.tar.zst" "$t/spoilt.tar.zst"
printf x >> "$t/spoilt.tar.zst"
if "$here/checkpoint.sh" restore "$w" "$t/spoilt.tar.zst" "$sha" 2> /dev/null; then fail "accepted a spoilt checkpoint"; fi
"$here/checkpoint.sh" restore "$w" "$t/cp.tar.zst" "$sha" > /dev/null
now=$(python3 -I "$here/supervise.py" --count --build "$w/build" --inner "$w/build/inner" --target all)
[ "$now" = "$left" ] || fail "after restore $now left, before $left"
echo "restored: still $now left, spoilt archive refused"

# 3. low disk stops the build, and says so
run 5 --min-free-disk 1000000
[ "$(field reason)" = disk ] || fail "reason $(field reason)"
echo "disk threshold stops the build"

# 4. low memory headroom does too
run 5 --min-headroom 1000000
[ "$(field reason)" = memory ] || fail "reason $(field reason)"
echo "memory threshold stops the build"

# 5. the rest is built, and no finished step is built twice
run 5
[ "$(field reason)" = done ] || fail "reason $(field reason)"
[ "$(field remaining_after)" = 0 ] || fail "left $(field remaining_after)"
total=$(wc -l < "$w/state/ran")
twice=$(sort "$w/state/ran" | uniq -d | wc -l)
[ "$total" = 30 ] && [ "$twice" = 0 ] || fail "$total runs, $twice repeated (first stretch ran $done_first)"
echo "resumed to the end: 30 steps run in all, none twice"

# 6. a failing step is an error, not a timeout
printf 'rule bad\n  command = false\nbuild bad: bad\n' > "$w/build/inner/build.ninja"
python3 -I "$here/supervise.py" --build "$w/build" --state "$w/state" --inner "$w/build/inner" --target bad --minutes 5 \
    --interval 0.2 --min-free-disk 0 --min-headroom 0 --max-swap-used 10000 --max-pressure 101 \
    --command "[\"ninja\", \"-C\", \"$w/build/inner\", \"bad\"]" > "$t/supervise.log"
[ "$(field reason)" = error ] || fail "reason $(field reason)"
echo "a failed step is reported as an error"
echo PASS
