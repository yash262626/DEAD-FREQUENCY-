#!/usr/bin/env python3
"""Turns raw PNG captures into the committed evidence images.

    python3 tools/evidence_images.py 4k   <png dir> docs/screenshots/slice4k   # native 3840x2160 → JPEG q90 (no resize)
    python3 tools/evidence_images.py hd   <png dir> docs/screenshots/slice     # downscaled to 1920x1080, JPEG q92
    python3 tools/evidence_images.py pair <left.png> <right.png> <out.jpg>     # side by side, each 1920x1080

4K files are refused unless the source really is 3840x2160, so a mis-sized capture can never be committed as 4K evidence.
"""
import os, sys
from PIL import Image

def save(im, out, q):
    os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
    im.convert("RGB").save(out, "JPEG", quality=q, optimize=True, progressive=True)
    print(f"{out}  {im.size[0]}x{im.size[1]}  {os.path.getsize(out) // 1024} KB")

def main():
    mode = sys.argv[1]
    if mode == "pair":
        a, b = (Image.open(p).convert("RGB").resize((1920, 1080), Image.LANCZOS) for p in sys.argv[2:4])
        im = Image.new("RGB", (3840, 1080)); im.paste(a, (0, 0)); im.paste(b, (1920, 0))
        return save(im, sys.argv[4], 90)
    src, dst = sys.argv[2], sys.argv[3]
    for f in sorted(os.listdir(src)):
        if not f.endswith(".png"): continue
        im = Image.open(os.path.join(src, f))
        out = os.path.join(dst, f[:-4] + ".jpg")
        if mode == "4k":
            if im.size != (3840, 2160): sys.exit(f"{f} is {im.size}, not 3840x2160 — refusing to label it 4K")
            save(im, out, 90)
        else:
            save(im.convert("RGB").resize((1920, 1080), Image.LANCZOS), out, 92)

if __name__ == "__main__":
    main()
