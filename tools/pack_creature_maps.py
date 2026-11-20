#!/usr/bin/env python3
"""Packs the Listener's Blender bakes (tools/blender/work) into the game's textures (game/assets/creature2):
albedo with cavity darkening (AO-weighted, blood pooling red in the folds), ORM (R ambient occlusion, G roughness with
soft noise, B metal = 0) and the tangent-space normal map. UV islands are dilated so mips never bleed the background.
    python3 tools/pack_creature_maps.py [work_dir] [out_dir]"""
import sys, os
import numpy as np
from PIL import Image, ImageFilter
work = sys.argv[1] if len(sys.argv) > 1 else "tools/blender/work"
out = sys.argv[2] if len(sys.argv) > 2 else "game/assets/creature2"

def save(im, name, **kw):
    # write a new file and swap it in: never write through an existing file (it may be a hardlink shared elsewhere)
    path = os.path.join(out, name); tmp = path + ".tmp" + os.path.splitext(name)[1]
    im.save(tmp, **kw); os.replace(tmp, path)

def dilate(im, mask, n=16):
    for _ in range(n):
        g = im.filter(ImageFilter.MaxFilter(3)); m2 = mask.filter(ImageFilter.MaxFilter(3))
        im = Image.composite(im, g, mask); mask = m2
    return im

def pack(tag, rough_base, rough_var, alb_out, orm_out, cavity=(0.06, 0.0, 0.0)):
    alb = Image.open(os.path.join(work, f"{tag}_albedo.png")).convert("RGB"); ao = Image.open(os.path.join(work, f"{tag}_ao.png")).convert("L")
    mask = alb.convert("L").point(lambda v: 255 if v > 2 else 0)
    alb = dilate(alb, mask); ao = dilate(ao.convert("RGB"), mask).convert("L")
    a = np.asarray(alb, np.float32) / 255; o = np.asarray(ao, np.float32)[..., None] / 255
    a = a * (0.45 + 0.55 * o) + np.array(cavity) * (1 - o)          # folds read darker and redder
    save(Image.fromarray(np.clip(a * 255, 0, 255).astype(np.uint8)), alb_out, quality=93)
    rng = np.random.default_rng(5)
    n = Image.fromarray((rng.random((alb.size[1] // 8, alb.size[0] // 8)) * 255).astype(np.uint8)).resize(alb.size, Image.BICUBIC).filter(ImageFilter.GaussianBlur(6))
    r = np.clip(rough_base + (np.asarray(n, np.float32) / 255 - 0.5) * rough_var, 0, 1)
    orm = np.stack([np.asarray(ao, np.float32) / 255, r, np.zeros_like(r)], -1)
    save(Image.fromarray((orm * 255).astype(np.uint8)), orm_out, quality=93)
    print("packed", tag, alb.size)

pack("listener2", 0.3, 0.32, "skin_albedo.jpg", "skin_orm.jpg", cavity=(0.09, 0.0, 0.005))
pack("membrane", 0.26, 0.28, "membrane_albedo.jpg", "membrane_orm.jpg", cavity=(0.08, 0.0, 0.0))
pack("claws", 0.38, 0.2, "claws_albedo.jpg", "claws_orm.jpg")
save(Image.open(os.path.join(work, "listener2_normal.png")).convert("RGB"), "skin_nor.png")
print("normal map copied")
