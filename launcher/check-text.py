# SPDX-License-Identifier: Unlicense
"""Checks that every label() in launcher.prg fits its panel, using the real fonts.
Usage: python check-text.py launcher.prg <font-dir>   (exit 1 if anything does not fit)"""
import re, sys
from PIL import ImageFont
prg, fdir = sys.argv[1], sys.argv[2]
FONTS = {"f_head": ("DejaVuSans-Bold.ttf", 44), "f_menu_w": ("DejaVuSans-Bold.ttf", 34), "f_menu_y": ("DejaVuSans-Bold.ttf", 34),
         "f_w": ("DejaVuSansCondensed-Bold.ttf", 25), "f_y": ("DejaVuSansCondensed-Bold.ttf", 25),
         "f_g": ("DejaVuSansCondensed-Bold.ttf", 22), "f_r": ("DejaVuSansCondensed-Bold.ttf", 25)}
cache = {k: ImageFont.truetype(f"{fdir}/{v[0]}", v[1]) for k, v in FONTS.items()}
LEFT, RIGHT, BOTTOM = 34, 598, 438     # inside the body panel (20..620 less its margin)
bad = 0
MAIN_LINES = {"Altitude by Daniel Imerion Eriksson", "Up/Down: choose     A: confirm"}
MAIN_LO, MAIN_HI = 118, 522      # inside the main screen bottom panel (110..530)
extra = [(586, 95, 2, "<  Original shape  >", "f_y"), (586, 95, 2, "<  Fill screen  >", "f_y"), (586, 183, 2, "<  Normal  >", "f_y"), (586, 183, 2, "<  Hard  >", "f_y"), (586, 227, 2, "Press A to confirm", "f_y")]
rows = [(int(m[0]), int(m[1]), int(m[2]), m[3], m[4]) for m in
        re.findall(r'label\((\d+),\s*(\d+),\s*(\d),\s*"([^"]*)",\s*(f_\w+)\)', open(prg).read())] + extra
for x, y, al, text, fn in rows:
    w = cache[fn].getlength(text)
    left = x if al == 0 else (x - w / 2 if al == 1 else x - w)
    right = left + w
    lo, hi = (LEFT, RIGHT)
    if text in MAIN_LINES or text.startswith("High score: "): lo, hi = MAIN_LO, MAIN_HI
    flag = ""
    if left < lo or right > hi: flag = f"  <-- OUT ({left:.0f}..{right:.0f}, allowed {lo}..{hi})"
    if y > 414 and fn == "f_w": flag += "  <-- LOW"
    if flag:
        bad += 1
        print(f"{text!r:58} {w:5.0f}px{flag}")
print("all lines fit" if not bad else f"{bad} problem(s)")
sys.exit(1 if bad else 0)
