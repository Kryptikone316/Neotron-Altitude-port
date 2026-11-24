#!/bin/bash
# SPDX-License-Identifier: Unlicense
# One headless computer-opponent run under qemu-user: starts 2P Battle on a level with no human input and prints one
# result line. Several can run in parallel (each has its own folder under $RUNS). Needs a finished build_sf3500.sh.
#   tools/bot-run.sh <easy|normal|hard> <level 1-7> <seconds>
# Environment: SF3500_TC and QEMU as for build_sf3500.sh; BUILD (default ./build-sf3500); RUNS (default ./runs)
#   (the timing governor is switched off so results do not depend on host speed)
#   BOT_AVOID_RED=1  the bot ignores red crystals (as if a human took the fire shield)
#   BOT_DEBUG=1      print the bot's diagnostics into the run's run.log (default: production logging only)
#   BOT_VALIDATE=1   compare the bot's collision test with the engine's (with BOT_DEBUG=1)
#   BOT_TRACE=<frame> print the bot's plan around a frame (with BOT_DEBUG=1)
set -u
LEVEL=$1; GL=${2:-1}; SECS=${3:-120}
HERE="$(cd "$(dirname "$0")/.." && pwd)"
: "${SF3500_TC:?set SF3500_TC}"
BUILD="${BUILD:-$HERE/build-sf3500}"; RUNS="${RUNS:-$HERE/runs}"; QEMU="${QEMU:-qemu-mipsel-static}"
SYSROOT="$SF3500_TC/mipsel-buildroot-linux-gnu/sysroot"
D="$RUNS/$LEVEL-L$GL"; rm -rf "$D"; mkdir -p "$D"
for f in "$HERE"/game/*.wav "$HERE"/game/*.mod "$HERE"/game/altitude.fpg "$BUILD"/altitude.dcb "$BUILD"/bgdi.mipsel; do ln -s "$f" "$D/"; done
cp "$HERE/game/score.dat" "$D/"
# keys: 2P Battle (right, right, enter), then right x (level-1) in the level select, then enter
KS="60:R,100:R,140:E"; f=200
for ((k=1;k<GL;k++)); do KS="$KS,$f:R"; f=$((f+35)); done
KS="$KS,$((f+40)):E,$((f+100)):E"
ENVV="SDL_AUDIODRIVER=dummy SDL_VIDEODRIVER=dummy VIDEO_DEPTH=16 SF3500_BOT_NOGOVERNOR=1 SF3500_BOT=$LEVEL SF3500_KEYSCRIPT=$KS"
[ -n "${BOT_DEBUG:-}" ]      && ENVV="$ENVV SF3500_BOT_DEBUG=1 SF3500_BOT_DEBUG_EVERY=50"
[ -n "${BOT_VALIDATE:-}" ]   && ENVV="$ENVV SF3500_BOT_VALIDATE=1"
[ -n "${BOT_AVOID_RED:-}" ]  && ENVV="$ENVV SF3500_BOT_AVOID_RED=1"
[ -n "${BOT_TRACE:-}" ]      && ENVV="$ENVV SF3500_BOT_TRACE=$BOT_TRACE"
cd "$D"
case "$QEMU" in
    flatpak-spawn*) flatpak-spawn --host --directory="$D" env $ENVV timeout -s KILL "$SECS" ${QEMU#flatpak-spawn --host} -L "$SYSROOT" ./bgdi.mipsel altitude.dcb > run.log 2>&1 || true ;;
    *)              env $ENVV timeout -s KILL "$SECS" $QEMU -L "$SYSROOT" ./bgdi.mipsel altitude.dcb > run.log 2>&1 || true ;;
esac
r=$(grep -a "bot: RESULT" run.log | head -1 | sed 's/bot: RESULT //; s/ level=[0-9]*//')
[ -z "$r" ] && r="no result (still flying at the timeout, or the match never started)"
echo "$LEVEL level $GL: $r"
