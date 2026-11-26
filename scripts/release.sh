#!/bin/sh
# Publishes a release for Windows and Linux: builds both on GitHub, signs their
# descriptions here with the release key, and puts everything on the releases page of the
# code repository. Copies up to 0.1.0-beta.2 look in the old releases repository, so the
# same release goes there too.   scripts/release.sh 0.1.0-beta.2 ["what is new"]
# YES=1 answers the last question (only after you have agreed to this very release).
set -eu
version=${1:?usage: release.sh VERSION [notes]}
notes=${2:-"Velum $version"}
code=vam0laa/velum
old=vam0laa/velum-releases
key=${VELUM_KEY:-$HOME/.config/velum-release/signing.pem}
cd "$(dirname "$0")/.."

echo "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+(-beta\.[0-9]+)?$' || { echo "bad version: $version"; exit 1; }
[ -r "$key" ] || { echo "release key not found: $key"; exit 1; }
# the key must be the one the program trusts
[ "$(openssl pkey -in "$key" -pubout -outform DER | tail -c 32 | od -An -tx1 | tr -d ' \n')" = "$(cat data/update.pub)" ] \
    || { echo "this key does not match data/update.pub"; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "commit your changes first"; exit 1; }
if gh release view "v$version" --repo "$code" >/dev/null 2>&1; then echo "v$version is already released"; exit 1; fi
commit=$(git rev-parse HEAD)
git push -q

# build WORKFLOW: the number of a successful run for this commit, starting one if needed
build() {
    run=$(gh run list --repo "$code" --workflow "$1" --commit "$commit" --json databaseId,conclusion \
          --jq '[.[] | select(.conclusion == "success")][0].databaseId // empty')
    if [ -z "$run" ] || [ "${REBUILD:-}" = 1 ]; then
        gh workflow run "$1" --repo "$code" -f version="$version" >&2
        echo "building ($1) on GitHub; this takes a while" >&2
        new=
        n=0
        while [ -z "$new" ]; do
            n=$((n + 1)); [ $n -lt 30 ] || { echo "the build did not start" >&2; return 1; }
            sleep 4
            new=$(gh run list --repo "$code" --workflow "$1" --commit "$commit" --json databaseId,status \
                  --jq '[.[] | select(.status != "completed")][0].databaseId // empty')
        done
        gh run watch "$new" --repo "$code" --exit-status --interval 30 >/dev/null
        run=$new
    fi
    echo "$run"
}

work=$(mktemp -d)
trap 'rm -rf "${work:?}"' EXIT
windows=$(build windows.yml)
linux=$(build linux.yml)
# from the draft releases the builds left behind (the server of build artifacts is not
# reachable from every network)
gh release download "build-$windows" --repo "$code" --pattern '*.exe' --dir "$work"
gh release download "linux-build-$linux" --repo "$code" --pattern '*.AppImage' --dir "$work"
setup="$work/Velum-$version-setup.exe"
image="$work/Velum-$version-x86_64.AppImage"
[ -f "$setup" ] && [ -f "$image" ] || { echo "the builds are not of version $version (run again with REBUILD=1)"; exit 1; }

# describe FILE REPOSITORY: what an installed Velum is told about it
describe() {
    python3 -I - "$version" "$1" "$2" "$notes" <<'PY'
import hashlib, json, os, sys
version, path, repo, notes = sys.argv[1:5]
data = open(path, "rb").read()
print(json.dumps({"version": version,
                  "url": f"https://github.com/{repo}/releases/download/v{version}/{os.path.basename(path)}",
                  "sha256": hashlib.sha256(data).hexdigest(), "size": len(data), "notes": notes}, ensure_ascii=False, indent=1))
PY
}
# each place has descriptions that point at its own files
for repo in "$code" "$old"; do
    mkdir "$work/${repo#*/}"
    describe "$setup" "$repo" > "$work/${repo#*/}/update.json"
    describe "$image" "$repo" > "$work/${repo#*/}/update-linux.json"
done

# the last look before the signature makes these files trusted by every installed Velum
echo "built from $(git rev-parse --short HEAD), by runs $windows (Windows) and $linux (Linux)"
for f in "$setup" "$image"; do
    echo "$(basename "$f"), $(stat -c %s "$f") bytes, sha256 $(sha256sum "$f" | cut -d' ' -f1)"
done
if [ "${YES:-}" != 1 ]; then
    printf 'sign and publish? (type "yes") '
    read -r answer
    [ "$answer" = yes ] || { echo "nothing was signed or published"; exit 1; }
fi

for repo in "$code" "$old"; do
    d="$work/${repo#*/}"
    for m in update.json update-linux.json; do
        openssl pkeyutl -sign -rawin -inkey "$key" -in "$d/$m" | base64 -w0 > "$d/$m.sig"
    done
    # published as an ordinary release: the updater asks GitHub for the latest one
    target=
    [ "$repo" = "$code" ] && target="--target $commit"
    gh release create "v$version" --repo "$repo" $target --title "Velum $version (beta)" --notes "$notes" \
        "$setup" "$image" "$d/update.json" "$d/update.json.sig" "$d/update-linux.json" "$d/update-linux.json.sig"
    echo "released: https://github.com/$repo/releases/tag/v$version"
done
