#!/bin/sh
# SPDX-License-Identifier: Unlicense
# Build-time transform: original altitude.prg (never edited) + Bennu import block after the
# 'program' line. Usage: make-bennu-prg.sh original.prg out.prg
IMPORTS='import "mod_video"; import "mod_key"; import "mod_text"; import "mod_sound"; import "mod_map"; import "mod_grproc"; import "mod_proc"; import "mod_rand"; import "mod_file"; import "mod_screen"; import "mod_math"; import "mod_string"; import "mod_time"; import "mod_say"; import "mod_scroll"; import "mod_draw"; import "mod_timers"; import "mod_sys";'
{ head -n 1 "$1"; printf '%s\r\n' "$IMPORTS"; tail -n +2 "$1"; } > "$2"
