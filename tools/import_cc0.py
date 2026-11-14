#!/usr/bin/env python3
"""Import ambientCG (CC0) PBR materials into game/textures/<AssetId>/.

Per material it writes:
  albedo.jpg  1024²  (Color)
  normal.jpg  1024²  (NormalGL — Godot uses the OpenGL convention)
  orm.jpg      512²  R = ambient occlusion (white if absent), G = roughness, B = metalness (black if absent)
and appends the asset to docs/THIRD_PARTY_NOTICES.md.
Usage: python3 tools/import_cc0.py <dir-with-zips> game/textures
"""
import sys, os, zipfile, io
from PIL import Image

src, dst = sys.argv[1], sys.argv[2]
done = []
for fn in sorted(os.listdir(src)):
    if not fn.endswith(".zip"): continue
    aid = fn[:-4]
    z = zipfile.ZipFile(os.path.join(src, fn))
    def find(suffix):
        for n in z.namelist():
            if n.endswith("_" + suffix + ".jpg") or n.endswith("_" + suffix + ".png"):
                return Image.open(io.BytesIO(z.read(n)))
        return None
    col, nrm, rgh = find("Color"), find("NormalGL"), find("Roughness")
    met, ao = find("Metalness"), find("AmbientOcclusion")
    if col is None or nrm is None or rgh is None:
        print("skip", aid, "(missing maps)"); continue
    out = os.path.join(dst, aid); os.makedirs(out, exist_ok=True)
    col.convert("RGB").resize((1024, 1024), Image.LANCZOS).save(os.path.join(out, "albedo.jpg"), quality=85)
    nrm.convert("RGB").resize((1024, 1024), Image.LANCZOS).save(os.path.join(out, "normal.jpg"), quality=92)
    S = (512, 512)
    r = (ao.convert("L").resize(S) if ao else Image.new("L", S, 255))
    g = rgh.convert("L").resize(S, Image.LANCZOS)
    b = (met.convert("L").resize(S) if met else Image.new("L", S, 0))
    Image.merge("RGB", (r, g, b)).save(os.path.join(out, "orm.jpg"), quality=90)
    done.append(aid)
    print("imported", aid, "metal" if met else "", "ao" if ao else "")

notice = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(dst))), "docs", "THIRD_PARTY_NOTICES.md")
lines = open(notice).read().splitlines() if os.path.exists(notice) else []
header = "## ambientCG materials (CC0 1.0 Universal)"
if header not in lines:
    lines += ["", header, "", "Source: https://ambientcg.com — released under CC0 1.0 (public domain dedication). Attribution is not required; we credit it anyway.", ""]
for aid in done:
    row = "- %s — https://ambientcg.com/view?id=%s" % (aid, aid)
    if row not in lines: lines.append(row)
open(notice, "w").write("\n".join(lines) + "\n")
print("notices:", notice)
