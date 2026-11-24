#!/bin/sh
# SPDX-License-Identifier: Unlicense
# Compiler launcher for reproducible builds. CMake hands the compiler absolute source paths, and the compiler embeds
# them (through __FILE__) in the binary. This turns every argument under $SRC_ROOT into a path relative to the
# current folder first, so the result does not depend on where the repository is checked out.
# (-ffile-prefix-map would do it, but the SF3500 toolchain's GCC 6.3 is older than that option.)
: "${SRC_ROOT:?set SRC_ROOT to the repository folder}"
for a in "$@"; do
    shift
    case "$a" in
        "$SRC_ROOT"/*) a="$(realpath --relative-to="$PWD" "$a")" ;;
    esac
    set -- "$@" "$a"
done
exec "$@"
