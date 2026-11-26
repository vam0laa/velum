#!/bin/sh
# Tests the password store against a throwaway keyring on a private message bus.
# Your own keyring is not reachable from here. Usage: tests/run-keyring.sh path/to/test_core
set -eu
command -v gnome-keyring-daemon >/dev/null && command -v dbus-run-session >/dev/null || exit 77
test_core=$(realpath "$1")
work=$(mktemp -d)
trap 'rm -rf "${work:?}"' EXIT
mkdir -m 700 "$work/run" "$work/data"
env -i PATH="$PATH" HOME="$work" XDG_RUNTIME_DIR="$work/run" XDG_DATA_HOME="$work/data" VELUM_TEST_KEYRING="$work" \
    timeout 40 dbus-run-session -- sh -c 'printf test | gnome-keyring-daemon --unlock --components=secrets >/dev/null && "$0" keyring' "$test_core"
