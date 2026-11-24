# SPDX-License-Identifier: Unlicense
"""Builds the launcher's bitmap fonts (.fnt, 16-bit, proportional) from DejaVu Sans.

Every glyph is antialiased and pre-blended against the launcher's panel colour, because the
launcher only ever draws text on solid panels of that colour; fully transparent pixels are
written as 0, which is the engine's colour key. That gives smooth text without any alpha.

Usage: python make-fonts.py <font-dir> <out-dir>
  <font-dir> holds DejaVuSans-Bold.ttf and DejaVuSansCondensed-Bold.ttf (DejaVu licence).
The engine reads the result with fnt_load(). The format is the engine's FNX layout:
8-byte header, charset, 256 glyph records of 7 ints, then rows of RGB565 pixels.
"""
import struct
import sys
from PIL import Image, ImageDraw, ImageFont

FONT_DIR, OUT = sys.argv[1], sys.argv[2]

PANEL = (16, 16, 26)          # must equal c_panel in launcher.prg
WHITE, YELLOW, GREY, GREEN = (255, 255, 255), (255, 215, 60), (228, 228, 236), (140, 255, 140)

# name: (ttf file, pixel size, text colour). The launcher draws at 480x360 (3/4 of the 640x480
# design layout in launcher.prg), so these are 3/4 of the design sizes.
FONTS = {
    "head":   ("DejaVuSans-Bold.ttf",          33, YELLOW),
    "menu_w": ("DejaVuSans-Bold.ttf",          26, WHITE),
    "menu_y": ("DejaVuSans-Bold.ttf",          26, YELLOW),
    "body_w": ("DejaVuSansCondensed-Bold.ttf", 19, WHITE),
    "body_y": ("DejaVuSansCondensed-Bold.ttf", 19, YELLOW),
    "body_g": ("DejaVuSansCondensed-Bold.ttf", 17, GREY),
    "body_r": ("DejaVuSansCondensed-Bold.ttf", 19, GREEN),
}


def rgb565(r, g, b):
    return ((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3)


def build(name, ttf, size, color):
    f = ImageFont.truetype(f"{FONT_DIR}/{ttf}", size)
    asc, desc = f.getmetrics()
    pad = 2
    height = asc + desc + 2 * pad
    records = [(0, 0, 0, 0, 0, 0, 0)] * 256   # width height xadv yadv xoff yoff fileoffset
    bitmaps = {}
    for c in range(32, 127):
        adv = int(round(f.getlength(chr(c))))
        w = adv + 4 * pad + size // 4
        mask = Image.new("L", (w, height), 0)
        ImageDraw.Draw(mask).text((2 * pad, pad + asc), chr(c), font=f, fill=255, anchor="ls")
        bbox = mask.getbbox()
        if c == 32 or bbox is None:
            records[c] = (0, 0, adv, height, 0, 0, 0)
            continue
        x0, _, x1, _ = bbox
        gw = x1 - x0
        rows = bytearray()
        for y in range(height):
            for x in range(x0, x1):
                a = mask.getpixel((x, y))
                if a == 0:
                    rows += struct.pack("<H", 0)               # colour key
                else:
                    r = (color[0] * a + PANEL[0] * (255 - a)) // 255
                    g = (color[1] * a + PANEL[1] * (255 - a)) // 255
                    b = (color[2] * a + PANEL[2] * (255 - a)) // 255
                    rows += struct.pack("<H", rgb565(r, g, b) or 1)
        bitmaps[c] = bytes(rows)
        records[c] = (gw, height, adv, height, x0 - 2 * pad, 0, 0)

    offset = 8 + 4 + 256 * 28
    out_records = []
    data = b""
    for c in range(256):
        w, h, xa, ya, xo, yo, _ = records[c]
        if c in bitmaps:
            out_records.append((w, h, xa, ya, xo, yo, offset + len(data)))
            data += bitmaps[c]
        else:
            out_records.append((w, h if w else 0, xa, ya, xo, yo, 0))
    blob = b"fnx\x1a\r\n\x00" + bytes([16]) + struct.pack("<i", 0)
    for rec in out_records:
        blob += struct.pack("<7i", *rec)
    blob += data
    with open(f"{OUT}/{name}.fnt", "wb") as fh:
        fh.write(blob)
    print(f"{name}.fnt  {ttf} {size}px  glyph height {height}  {len(blob) // 1024} KB")


for name, (ttf, size, color) in FONTS.items():
    build(name, ttf, size, color)
