#!/bin/sh
# Runs the interface test without a screen. Usage: tests/run-ui.sh [picture.png]
set -e
here=$(cd "$(dirname "$0")" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/ui"
cp "$here"/../qml/*.qml "$here"/ui/*.qml "$work/ui/"
cp "$here/test_ui.qml" "$work/" && cp -r "$here/extension" "$work/"
mkdir -p "$work/data" && cp -r "$here/../data/velum.svg" "$here/../data/fonts" "$here/../data/sky.jpg" "$here/../data/sky-night.jpg" "$here/../data/logos" "$here/../data/scanline.png" "$work/data/"
{
    for f in Theme Lang Address DesktopColors Shield History Resources Notifier Importer Passwords WebStore DefaultBrowser; do echo "singleton $f $f.qml"; done
    for f in "$here"/../qml/*.qml; do n=$(basename "$f" .qml); [ "$n" = Theme ] || [ "$n" = Lang ] || echo "$n $n.qml"; done
} > "$work/ui/qmldir"
XDG_CONFIG_HOME="$work/config" XDG_DATA_HOME="$work/data" QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
QT_QUICK_CONTROLS_STYLE=Basic QT_FORCE_STDERR_LOGGING=1 QT_LOGGING_RULES="qml.debug=true" \
    timeout 90 "${QML:-qml6}" -a gui "$work/test_ui.qml" -- "${1:-$work/shot.png}" 2>&1 |
    grep -E "PASS|FAIL|RESULT|DEBUG|\.qml:[0-9]+|rror" > "$work/log" || true
cat "$work/log"
grep -q "RESULT all passed" "$work/log"
