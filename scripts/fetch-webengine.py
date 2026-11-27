#!/usr/bin/env python3
"""Adds Qt WebEngine to an installed Qt.

From Qt 6.12 the engine is released on its own, as an "extension" that aqtinstall cannot
install yet. This takes Qt's own archive, checks it against the sum written here, and
unpacks it into the Qt folder.

Usage: fetch-webengine.py linux|windows QT_DIR
"""
import hashlib
import os
import shutil
import subprocess
import sys
import tempfile
import urllib.request

BASE = "https://download.qt.io/online/qtsdkrepository"
STAMP = "6.12.1-0-202611261246"   # Qt WebEngine 6.140.0 for Qt 6.12.1
PACKAGES = {
    "linux": (
        "linux_x64/extensions/qtwebengine/6121/61400/x86_64",
        "extensions.qtwebengine.6121.61400.linux_gcc_64",
        "qtwebengine-Linux-RHEL_9_6-GCC-Linux-RHEL_9_6-X86_64.7z",
        "91f5663985053309aa1e03b9f12a1d5c2c79edeb7dbbd795ee200382cd25887d",
    ),
    "windows": (
        "windows_x86/extensions/qtwebengine/6121/61400/msvc2022_64",
        "extensions.qtwebengine.6121.61400.win64_msvc2022_64",
        "qtwebengine-Windows-Windows_11_24H2-MSVC2022-Windows-Windows_11_24H2-X86_64.7z",
        "4684fdf6dfb7af0c6a68a4e69c2045f111a15f5a386607561b178becf0b66631",
    ),
}


def main():
    if len(sys.argv) != 3 or sys.argv[1] not in PACKAGES:
        sys.exit(__doc__)
    path, package, archive, wanted = PACKAGES[sys.argv[1]]
    qt = os.path.abspath(sys.argv[2])
    if not os.path.isdir(os.path.join(qt, "lib", "cmake")):
        sys.exit(f"not a Qt folder: {qt}")
    with tempfile.TemporaryDirectory() as work:
        target = os.path.join(work, archive)
        url = f"{BASE}/{path}/{package}/{STAMP}{archive}"
        total = hashlib.sha256()
        with urllib.request.urlopen(url, timeout=120) as answer, open(target, "wb") as out:
            while chunk := answer.read(1 << 20):
                total.update(chunk)
                out.write(chunk)
        if total.hexdigest() != wanted:
            sys.exit(f"wrong sum for {archive}: {total.hexdigest()}")
        seven = shutil.which("7z")
        if seven:
            subprocess.run([seven, "x", "-y", f"-o{qt}", target], check=True, stdout=subprocess.DEVNULL)
        else:
            import py7zr
            with py7zr.SevenZipFile(target) as packed:
                packed.extractall(qt)
    if not os.path.isdir(os.path.join(qt, "lib", "cmake", "Qt6WebEngineQuick")):
        sys.exit("the engine did not land in the Qt folder")
    print(f"Qt WebEngine added to {qt}")


if __name__ == "__main__":
    main()
