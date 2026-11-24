#!/bin/bash
# SPDX-License-Identifier: Unlicense
# Assembles the port folder, ready to copy to the card's roms/ports, into package/ (needs a finished build_sf3500.sh):
#   package/Altitude.sh               the launcher entry shown in the Ports tab
#   package/neotron-altitude/...      the port
set -eu
HERE="$(cd "$(dirname "$0")" && pwd)"
BUILD="${BUILD:-$HERE/build-sf3500}"
OUT="${PKG:-$HERE/package}"
for f in bgdi.mipsel altitude.dcb launcher.dcb ui; do [ -e "$BUILD/$f" ] || { echo "package.sh: run build_sf3500.sh first ($f missing)" >&2; exit 1; }; done
rm -rf "$OUT"; P="$OUT/neotron-altitude"; mkdir -p "$P/licenses" "$P/source"

# the game, exactly as the author published it (the script is replaced by its BennuGD bytecode, and shipped under source/)
for f in "$HERE"/game/*.wav "$HERE"/game/*.mod "$HERE"/game/altitude.fpg "$HERE"/game/score.dat; do cp "$f" "$P/"; done
cp "$HERE/game/Readme.txt" "$P/Readme-altitude.txt"
# the port
cp "$BUILD/bgdi.mipsel" "$BUILD/altitude.dcb" "$BUILD/launcher.dcb" "$P/"
cp -r "$BUILD/ui" "$P/ui"
cp "$HERE/launcher/launcher.prg" "$P/"
cp "$HERE/package-src/run.sh" "$HERE/package-src/boxart.png" "$HERE/package-src/README.md" "$P/"
cp "$HERE/package-src/Altitude.sh" "$OUT/Altitude.sh"
cp "$HERE"/licenses/*.txt "$P/licenses/"
cp "$HERE/game/altitude.prg" "$HERE/tools/make-bennu-prg.sh" "$HERE/launcher/make-fonts.py" "$P/source/"
chmod +x "$OUT/Altitude.sh" "$P/run.sh" "$P/bgdi.mipsel"
echo "package/ is ready: $(find "$OUT" -type f | wc -l) files, $(du -sh "$OUT" | cut -f1)"
