#!/bin/sh
# Publishes a Windows release: builds it on GitHub, signs its description here with the
# release key, and puts both in the public releases repository.
#   scripts/release.sh 0.1.0-beta.1 ["what is new"]
set -eu
version=${1:?usage: release.sh VERSION [notes]}
notes=${2:-"Velum $version"}
code=vam0laa/velum
releases=vam0laa/velum-releases
key=${VELUM_KEY:-$HOME/.config/velum-release/signing.pem}
cd "$(dirname "$0")/.."

echo "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+(-beta\.[0-9]+)?$' || { echo "bad version: $version"; exit 1; }
[ -r "$key" ] || { echo "release key not found: $key"; exit 1; }
# the key must be the one the program trusts
[ "$(openssl pkey -in "$key" -pubout -outform DER | tail -c 32 | od -An -tx1 | tr -d ' \n')" = "$(cat data/update.pub)" ] \
    || { echo "this key does not match data/update.pub"; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "commit your changes first"; exit 1; }
if gh release view "v$version" --repo "$releases" >/dev/null 2>&1; then echo "v$version is already released"; exit 1; fi

run=$(gh run list --repo "$code" --workflow windows.yml --commit "$(git rev-parse HEAD)" --json databaseId,conclusion,displayTitle \
      --jq '[.[] | select(.conclusion == "success")][0].databaseId // empty')
if [ -z "$run" ] || [ "${REBUILD:-}" = 1 ]; then
    git push -q
    gh workflow run windows.yml --repo "$code" -f version="$version"
    echo "building on GitHub; this takes a while"
    n=0
    while [ -z "${new:-}" ]; do
        n=$((n + 1)); [ $n -lt 30 ] || { echo "the build did not start"; exit 1; }
        sleep 4
        new=$(gh run list --repo "$code" --workflow windows.yml --commit "$(git rev-parse HEAD)" --json databaseId,status \
              --jq '[.[] | select(.status != "completed")][0].databaseId // empty')
    done
    gh run watch "$new" --repo "$code" --exit-status >/dev/null
    run=$new
fi

work=$(mktemp -d)
trap 'rm -rf "${work:?}"' EXIT
gh run download "$run" --repo "$code" --name velum-windows --dir "$work"
setup="$work/Velum-$version-setup.exe"
[ -f "$setup" ] || { echo "the build is not of version $version (run again with REBUILD=1)"; exit 1; }

python3 - "$version" "$setup" "$releases" "$notes" > "$work/update.json" <<'PY'
import hashlib, json, os, sys
version, setup, repo, notes = sys.argv[1:5]
data = open(setup, "rb").read()
print(json.dumps({"version": version,
                  "url": f"https://github.com/{repo}/releases/download/v{version}/{os.path.basename(setup)}",
                  "sha256": hashlib.sha256(data).hexdigest(), "size": len(data), "notes": notes}, ensure_ascii=False, indent=1))
PY
openssl pkeyutl -sign -rawin -inkey "$key" -in "$work/update.json" | base64 -w0 > "$work/update.json.sig"

# published as an ordinary release: the updater asks GitHub for the latest one
gh release create "v$version" --repo "$releases" --title "Velum $version (beta)" --notes "$notes" \
    "$setup" "$work/update.json" "$work/update.json.sig"
echo "released: https://github.com/$releases/releases/tag/v$version"
