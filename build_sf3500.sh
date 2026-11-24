#!/bin/bash
# SPDX-License-Identifier: Unlicense
# Builds everything the SF3500 needs into build-sf3500/ (or $OUT):
#   bgdi.mipsel    the runtime (BennuGD with SF3500 display/audio/input, tracker music, computer opponent)
#   bgdc/bgdc      the compiler, built for the same CPU and run under qemu-user
#   altitude.dcb   the author's altitude.prg compiled for BennuGD (see tools/make-bennu-prg.sh)
#   launcher.dcb   the launcher, and ui/*.fnt, its fonts
#
# Needs: the SF3500 MIPS toolchain, cmake, make, python3 with Pillow, qemu-user for mipsel, and three
# upstream tarballs in $DEPS (see README.md for where to get them).
#
#   SF3500_TC=/path/to/toolchain/host  ./build_sf3500.sh
#
# Environment:
#   SF3500_TC   toolchain "host" directory: bin/mips-mti-linux-gnu-gcc and mipsel-buildroot-linux-gnu/sysroot (required)
#   DEPS        folder with SDL2-2.0.14.tar.gz, SDL2_mixer-2.6.3.tar.gz, libxmp-lite-4.6.0.tar.gz (default ./deps)
#   OUT         build folder (default ./build-sf3500)
#   QEMU        how to run a mipsel program, e.g. "qemu-mipsel-static" (default) or "flatpak-spawn --host qemu-mipsel-static"
#   PY          python with Pillow (default python3)
#   FONT_DIR    folder with DejaVuSans-Bold.ttf and DejaVuSansCondensed-Bold.ttf (default /usr/share/fonts/truetype/dejavu)
set -eu

HERE="$(cd "$(dirname "$0")" && pwd)"
: "${SF3500_TC:?set SF3500_TC to the toolchain host directory}"
DEPS="${DEPS:-$HERE/deps}"
OUT="${OUT:-$HERE/build-sf3500}"
QEMU="${QEMU:-qemu-mipsel-static}"
PY="${PY:-python3}"
FONT_DIR="${FONT_DIR:-/usr/share/fonts/truetype/dejavu}"
JOBS="${JOBS:-$(nproc)}"
export SF3500_TC
SYSROOT="$SF3500_TC/mipsel-buildroot-linux-gnu/sysroot"
RUNTIME="$HERE/runtime"
TOOLCHAIN="$RUNTIME/sf3500/cmake/sf3500-toolchain.cmake"
STRIP="$SF3500_TC/bin/mips-mti-linux-gnu-strip"
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"

die() { echo "build_sf3500.sh: $*" >&2; exit 1; }
[ -x "$SF3500_TC/bin/mips-mti-linux-gnu-gcc" ] || die "no mips-mti-linux-gnu-gcc in $SF3500_TC/bin"

# Runs a mipsel program from folder $1 (the rest is the command line) under qemu-user.
run_mips() {
    local dir="$1"; shift
    case "$QEMU" in
        flatpak-spawn*) ( cd "$dir" && flatpak-spawn --host --directory="$dir" ${QEMU#flatpak-spawn --host} -L "$SYSROOT" "$@" ) ;;
        *)              ( cd "$dir" && $QEMU -L "$SYSROOT" "$@" ) ;;
    esac
}

# Checks an upstream tarball against its known checksum.
need_tar() {
    local file="$DEPS/$1" sum="$2"
    [ -f "$file" ] || die "missing $file (see README.md)"
    echo "$sum  $file" | sha256sum -c --quiet - || die "$1 does not match the expected checksum"
}
need_tar SDL2-2.0.14.tar.gz       d8215b571a581be1332d2106f8036fcb03d12a70bae01e20f424976d275432bc
need_tar SDL2_mixer-2.6.3.tar.gz  7a6ba86a478648ce617e3a5e9277181bc67f7ce9876605eea6affd4a0d6eea8f
need_tar libxmp-lite-4.6.0.tar.gz 71a93eb0119824bcc56eca95db154d1cdf30304b33d89a4732de6fef8a2c6f38

SDL="$OUT/prefix-sdl2"; XMP="$OUT/prefix-xmp"; MIX="$OUT/prefix-mixer"

# 1. SDL2 with the SF3500 patch (audio pacing, input bridge, divide-by-zero guard), static.
if [ ! -f "$SDL/lib/libSDL2.a" ]; then
    echo "== SDL2"
    rm -rf "$OUT/sdl2-src" "$OUT/sdl2-build"; mkdir -p "$OUT/sdl2-src" "$OUT/sdl2-build"
    tar xzf "$DEPS/SDL2-2.0.14.tar.gz" -C "$OUT/sdl2-src" --strip-components=1
    (cd "$OUT/sdl2-src" && patch -p1 -s < "$RUNTIME/sf3500/sdl2-2.0.14-sf3500.patch")
    (cd "$OUT/sdl2-build" && cmake "$OUT/sdl2-src" -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" -DCMAKE_INSTALL_PREFIX="$SDL" \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DSDL_SHARED=OFF -DSDL_STATIC=ON -DSDL_STATIC_PIC=OFF -DSDL_TEST=OFF \
        -DSDL_HAPTIC=OFF -DSDL_POWER=OFF -DSDL_SENSOR=OFF -DPKG_CONFIG_EXECUTABLE=/nonexistent/pkg-config \
        -DVIDEO_KMSDRM=OFF -DVIDEO_KMSDRM_SHARED=OFF -DALSA=OFF -DPULSEAUDIO=OFF -DJACK=OFF \
        -DESD=OFF -DARTS=OFF -DNAS=OFF -DSNDIO=OFF -DVIDEO_WAYLAND=OFF -DVIDEO_X11=OFF \
        -DVIDEO_OPENGL=OFF -DVIDEO_OPENGLES=OFF -DVIDEO_VULKAN=OFF -DVIDEO_RPI=OFF \
        -DVIDEO_VIVANTE=OFF -DVIDEO_DIRECTFB=OFF > cmake.log 2>&1 && make -j"$JOBS" > make.log 2>&1 && make install > install.log 2>&1) \
        || die "SDL2 build failed, see $OUT/sdl2-build/*.log"
fi

# 2. libxmp-lite (MOD/S3M/XM/IT playback), static. Its installed CMake config has a typo that stops it being found.
if [ ! -f "$XMP/lib/libxmp-lite.a" ]; then
    echo "== libxmp-lite"
    rm -rf "$OUT/xmp-src" "$OUT/xmp-build"; mkdir -p "$OUT/xmp-src" "$OUT/xmp-build"
    tar xzf "$DEPS/libxmp-lite-4.6.0.tar.gz" -C "$OUT/xmp-src" --strip-components=1
    (cd "$OUT/xmp-build" && cmake "$OUT/xmp-src" -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" -DCMAKE_INSTALL_PREFIX="$XMP" \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DBUILD_SHARED=OFF -DCMAKE_BUILD_TYPE=Release > cmake.log 2>&1 \
        && make -j"$JOBS" > make.log 2>&1 && make install > install.log 2>&1) || die "libxmp-lite build failed, see $OUT/xmp-build/*.log"
    sed -i 's/CMAKE_CURRENT_LISTDIR/CMAKE_CURRENT_LIST_DIR/g' "$XMP/lib/cmake/libxmp-lite/libxmp-lite-config.cmake"
fi

# 3. SDL2_mixer with libxmp-lite for the tracker music (the game's two songs are .mod files). Ogg through stb_vorbis.
if [ ! -f "$MIX/lib/libSDL2_mixer.a" ]; then
    echo "== SDL2_mixer"
    rm -rf "$OUT/mixer-src" "$OUT/mixer-build"; mkdir -p "$OUT/mixer-src" "$OUT/mixer-build"
    tar xzf "$DEPS/SDL2_mixer-2.6.3.tar.gz" -C "$OUT/mixer-src" --strip-components=1
    (cd "$OUT/mixer-src" && patch -p1 -s < "$RUNTIME/sf3500/sdl2-mixer-2.6.3-xmp-lite.patch")
    (cd "$OUT/mixer-build" && cmake "$OUT/mixer-src" -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" -DCMAKE_INSTALL_PREFIX="$MIX" \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_FIND_PACKAGE_PREFER_CONFIG=ON -Dlibxmp-lite_DIR="$XMP/lib/cmake/libxmp-lite" \
        -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DSDL2MIXER_VENDORED=ON -DSDL2MIXER_DEPS_SHARED=OFF \
        -DSDL2MIXER_VORBIS=STB -DSDL2MIXER_FLAC=OFF -DSDL2MIXER_MP3=OFF -DSDL2MIXER_MIDI=OFF -DSDL2MIXER_OPUS=OFF \
        -DSDL2MIXER_MOD=ON -DSDL2MIXER_MOD_MODPLUG=OFF -DSDL2MIXER_MOD_XMP=ON -DSDL2MIXER_MOD_XMP_LITE=ON -DSDL2MIXER_MOD_XMP_SHARED=OFF \
        -DSDL2MIXER_CMD=OFF -DSDL2MIXER_WAVE=ON -DSDL2MIXER_SAMPLES=OFF -DSDL2MIXER_INSTALL=ON \
        -DSDL2_DIR="$SDL/lib/cmake/SDL2" -DSDL2_INCLUDE_DIR="$SDL/include/SDL2" -DSDL2_LIBRARY="$SDL/lib/libSDL2.a" > cmake.log 2>&1 \
        && make -j"$JOBS" > make.log 2>&1 && make install > install.log 2>&1) || die "SDL2_mixer build failed, see $OUT/mixer-build/*.log"
fi

# 4. The runtime. The binary's name must start with "bgdi": the engine uses that to read the game from a separate file.
echo "== runtime"
mkdir -p "$OUT/rt-build"
(cd "$OUT/rt-build" && cmake "$RUNTIME" -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" -DCMAKE_MODULE_PATH="$RUNTIME/sf3500/cmake" \
    -DCMAKE_FIND_PACKAGE_PREFER_CONFIG=OFF -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DSDL2_INCLUDE_DIR="$SDL/include/SDL2" -DSDL2_LIBRARY="$SDL/lib/libSDL2.a" \
    -DSDL2_MIXER_INCLUDE_DIR="$MIX/include/SDL2" -DSDL2_MIXER_LIBRARY="$MIX/lib/libSDL2_mixer.a" \
    -DCMAKE_C_STANDARD_LIBRARIES="$XMP/lib/libxmp-lite.a" > cmake.log 2>&1 && make -j"$JOBS" > make.log 2>&1) \
    || die "runtime build failed, see $OUT/rt-build/*.log"
"$STRIP" -o "$OUT/bgdi.mipsel" "$OUT/rt-build/bgdi"

# 5. The compiler, from the same source tree, for the same CPU.
echo "== compiler"
mkdir -p "$OUT/bgdc"
(cd "$OUT/bgdc" && cmake "$HERE/tools/bgdc" -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" -DRUNTIME_DIR="$RUNTIME" -DSDL2_INC="$SDL/include/SDL2" \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 > cmake.log 2>&1 && make -j"$JOBS" > make.log 2>&1) || die "bgdc build failed, see $OUT/bgdc/*.log"

# 6. Fonts for the launcher (checked first: every text line must fit its panel), then the two programs.
echo "== launcher fonts and bytecode"
mkdir -p "$OUT/ui" "$OUT/dcb"
"$PY" -I "$HERE/launcher/make-fonts.py" "$FONT_DIR" "$OUT/ui" > /dev/null
"$PY" -I "$HERE/launcher/check-text.py" "$HERE/launcher/launcher.prg" "$FONT_DIR"
cp "$HERE/launcher/launcher.prg" "$OUT/dcb/launcher.prg"
# The author's script is not edited: BennuGD wants import lines after its first line, so a compile copy gets them.
sh "$HERE/tools/make-bennu-prg.sh" "$HERE/game/altitude.prg" "$OUT/dcb/altitude.prg"
for prg in launcher altitude; do
    rm -f "$OUT/dcb/$prg.dcb"
    # bgdc's exit status is not reliable (it is non-zero after a good compile), so judge by its message and the output file
    run_mips "$OUT/dcb" "$OUT/bgdc/bgdc" "$prg.prg" > "$OUT/dcb/$prg.log" 2>&1 || true
    if ! grep -q "compiled (" "$OUT/dcb/$prg.log" || [ ! -s "$OUT/dcb/$prg.dcb" ]; then cat "$OUT/dcb/$prg.log"; die "compiling $prg.prg failed"; fi
    cp "$OUT/dcb/$prg.dcb" "$OUT/$prg.dcb"
done

echo
echo "Built into $OUT:"
ls -l "$OUT/bgdi.mipsel" "$OUT/altitude.dcb" "$OUT/launcher.dcb" "$OUT/ui" | sed 's/^/  /'
