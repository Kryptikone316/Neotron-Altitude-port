# SPDX-License-Identifier: Unlicense
# The BennuGD compiler (bgdc), cross-built for the SF3500's MIPS CPU from the same source tree as the runtime, so
# that the bytecode it writes is exactly what that runtime reads. It is run under qemu-user at build time.
# Configure with -DRUNTIME_DIR=<repo>/runtime -DSDL2_INC=<SDL2 include dir> and the SF3500 toolchain file.
cmake_minimum_required(VERSION 3.5)
project(bgdc C)
set(SRC ${RUNTIME_DIR})
add_definitions(-D__BGDC__ -D__MONOLITHIC__ -DTARGET_LINUX -DVERSION="1.0.0"
  -DNO_MODCHIPMUNK -DNO_MODICONV -DNO_MODFMODEX -DNO_MODCURL -DNO_MODMATHI -DNO_MODSENSOR
  -DNO_FSOCK -DNO_MODIAP -DNO_MODIMAGE)
file(GLOB SOURCES ${SRC}/core/bgdc/src/*.c ${SRC}/core/common/debug.c ${SRC}/core/common/files.c ${SRC}/core/common/xctype.c)
file(GLOB MODDIRS LIST_DIRECTORIES true ${SRC}/modules/*)
include_directories(${SRC}/core/bgdc/include ${SRC}/core/include ${MODDIRS} ${SDL2_INC})
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=gnu11 -fno-strict-aliasing -O2 -w")
add_executable(bgdc ${SOURCES})
target_link_libraries(bgdc z)
