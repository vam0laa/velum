#!/usr/bin/env bash
# Keeps and brings back the state of the engine build: sources, build folder and notes, with
# the times of every file to the nanosecond, so that ninja goes on where it stopped.
#   checkpoint.sh pack    WORK_DIR ARCHIVE      writes ARCHIVE and ARCHIVE.sha256
#   checkpoint.sh restore WORK_DIR ARCHIVE SHA  checks the digest, unpacks, removes ARCHIVE
# WORK_DIR must have the same path on the machine that packs and the one that restores.
set -euo pipefail

mode=$1 work=$2 archive=$3
parent=$(dirname "$work") name=$(basename "$work")

case $mode in
pack)
    tar -C "$parent" --format=posix -cf - "$name" | zstd -q -T0 -3 -o "$archive"
    zstd -q -t "$archive"
    sha256sum "$archive" | cut -d' ' -f1 > "$archive.sha256"
    echo "packed $(stat -c %s "$archive") bytes, sha256 $(cat "$archive.sha256")"
    ;;
restore)
    want=$4
    have=$(sha256sum "$archive" | cut -d' ' -f1)
    if [ -z "$want" ] || [ "$have" != "$want" ]; then
        echo "checkpoint digest is $have, expected ${want:-none}" >&2
        exit 1
    fi
    [ ! -e "$work" ] || { echo "$work is already there" >&2; exit 1; }
    zstd -q -d -c "$archive" | tar -C "$parent" -xf -
    rm -f "$archive"
    echo "restored $work from a checkpoint with sha256 $have"
    ;;
*)
    echo "unknown mode $mode" >&2
    exit 2
    ;;
esac
