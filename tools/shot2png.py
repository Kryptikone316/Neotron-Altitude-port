# SPDX-License-Identifier: Unlicense
import sys, glob, os
from PIL import Image
# Converts <prefix>_NNN.ppm frames to PNG (same names). Usage: shot2png.py <prefix>
for f in sorted(glob.glob(sys.argv[1] + "_*.ppm")):
    Image.open(f).save(f[:-4] + ".png"); os.remove(f)
    print(f[:-4] + ".png")
