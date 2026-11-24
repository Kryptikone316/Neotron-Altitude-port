#!/bin/bash
# SPDX-License-Identifier: Unlicense
# Renders every launcher screen to PNG without a device (qemu-user + the runtime's frame dump), for checking layouts.
#   tools/render-launcher.sh [output folder]      (default ./launcher-screens)
# Environment: SF3500_TC, QEMU, PY (python with Pillow), BUILD as for build_sf3500.sh.
set -eu
HERE="$(cd "$(dirname "$0")/.." && pwd)"
: "${SF3500_TC:?set SF3500_TC}"
BUILD="${BUILD:-$HERE/build-sf3500}"; QEMU="${QEMU:-qemu-mipsel-static}"; PY="${PY:-python3}"
SYSROOT="$SF3500_TC/mipsel-buildroot-linux-gnu/sysroot"
SHOTS="${1:-$HERE/launcher-screens}"; mkdir -p "$SHOTS"; SHOTS="$(cd "$SHOTS" && pwd)"
W="$HERE/.render-tmp"; rm -rf "$W"; mkdir -p "$W"; trap 'rm -rf "$W"' EXIT
cp "$HERE"/game/altitude.fpg "$HERE"/game/alt1.mod "$HERE"/game/select.wav "$HERE"/game/score.dat "$BUILD/launcher.dcb" "$BUILD/bgdi.mipsel" "$W/"
cp -r "$BUILD/ui" "$W/ui"
ENVV="SDL_AUDIODRIVER=dummy SDL_VIDEODRIVER=dummy VIDEO_WIDTH=480 VIDEO_HEIGHT=360 SF3500_SHOT_PREFIX=shot"
case "$QEMU" in
    flatpak-spawn*) flatpak-spawn --host --directory="$W" env $ENVV timeout -s KILL 120 ${QEMU#flatpak-spawn --host} -L "$SYSROOT" ./bgdi.mipsel launcher.dcb shots > "$W/log" 2>&1 || true ;;
    *)              (cd "$W" && env $ENVV timeout -s KILL 120 $QEMU -L "$SYSROOT" ./bgdi.mipsel launcher.dcb shots > "$W/log" 2>&1) || true ;;
esac
"$PY" -I - "$W" "$SHOTS" <<'P'
import glob, sys
from PIL import Image
names = ["main", "main_sel", "options", "options_music", "options_bot", "help1", "help2", "help3", "help4", "help5"]
for i, f in enumerate(sorted(glob.glob(sys.argv[1] + "/shot_*.ppm"))):
    Image.open(f).save(f"{sys.argv[2]}/{names[i]}.png")
print(len(glob.glob(sys.argv[2] + "/*.png")), "screens in", sys.argv[2])
P
