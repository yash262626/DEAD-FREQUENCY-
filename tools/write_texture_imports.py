#!/usr/bin/env python3
"""Writes Godot 3 .import settings for every texture under game/assets that has none yet, so the first import
already uses the right flags: repeat + mipmaps + anisotropic + VRAM compression for 3D use; sRGB only for colour
maps; normal-map compression for *_nor_gl / nor_gl maps. Run before tools/import_assets.sh."""
import os, sys
root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game")
n = 0
for d, _, files in [w for b in ("assets", "slice") for w in os.walk(os.path.join(root, b))]:
    for f in files:
        if not f.lower().endswith((".jpg", ".jpeg", ".png")): continue
        p = os.path.join(d, f)
        if os.path.exists(p + ".import") and "--force" not in sys.argv: continue
        low = f.lower()
        normal = "nor" in low
        linear = normal or any(k in low for k in ("arm", "rough", "metal", "_ao", "ao.", "disp", "spec", "mask", "orm"))
        res = "res://" + os.path.relpath(p, root).replace(os.sep, "/")
        open(p + ".import", "w").write(f'''[remap]

importer="texture"
type="StreamTexture"

[deps]

source_file="{res}"

[params]

compress/mode=2
compress/lossy_quality=0.7
compress/hdr_mode=0
compress/bptc_ldr=0
compress/normal_map={1 if normal else 0}
flags/repeat=1
flags/filter=true
flags/mipmaps=true
flags/anisotropic=true
flags/srgb={0 if linear else 1}
process/fix_alpha_border=true
process/premult_alpha=false
process/HDR_as_SRGB=false
process/invert_color=false
process/normal_map_invert_y=false
stream=false
size_limit=0
detect_3d=false
svg/scale=1.0
''')
        n += 1
print(f"wrote {n} import files")
