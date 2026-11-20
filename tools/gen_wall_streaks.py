#!/usr/bin/env python3
"""Generates game/slice/tex/wall_streaks.png: a tileable mask of water running down a wall (white = wet).
Thin vertical runs of varying width and length that start under random points (pipe joints, cracks) and fade out,
plus a few broad damp patches. Tiles in both directions. Deterministic (fixed seed)."""
import numpy as np
from PIL import Image, ImageFilter
W, H = 512, 1024
rng = np.random.default_rng(23)
m = np.zeros((H, W), np.float32)
ys = np.arange(H)
for _ in range(70):                                   # runs
    x0 = rng.uniform(0, W); y0 = rng.uniform(0, H); length = rng.uniform(120, 900); w = rng.uniform(0.6, 4.5)
    strength = rng.uniform(0.35, 1.0); wander = rng.uniform(0.5, 3.0); phase = rng.uniform(0, 6.28)
    for k in range(int(length)):
        y = int(y0 + k) % H
        x = x0 + wander * np.sin(k / 37.0 + phase) + 0.6 * np.sin(k / 9.0 + phase * 2)
        fade = (1.0 - k / length) ** 0.6 * min(1.0, k / 25.0 + 0.2)
        xs = np.arange(int(x - w * 2) - 1, int(x + w * 2) + 2)
        prof = np.exp(-((xs - x) / max(0.5, w)) ** 2) * strength * fade
        m[y, xs % W] = np.maximum(m[y, xs % W], prof)
for _ in range(9):                                    # damp patches
    cx, cy = rng.uniform(0, W), rng.uniform(0, H); rx, ry = rng.uniform(25, 70), rng.uniform(60, 220)
    yy, xx = np.mgrid[0:H, 0:W]
    dx = np.minimum(np.abs(xx - cx), W - np.abs(xx - cx)); dy = np.minimum(np.abs(yy - cy), H - np.abs(yy - cy))
    m = np.maximum(m, 0.45 * np.exp(-((dx / rx) ** 2 + (dy / ry) ** 2)))
img = Image.fromarray((np.clip(m, 0, 1) * 255).astype(np.uint8))
big = Image.new("L", (W * 3, H * 3))
for i in range(3):
    for j in range(3): big.paste(img, (i * W, j * H))
big = big.filter(ImageFilter.GaussianBlur(1.6)).crop((W, H, 2 * W, 2 * H))      # blur across the seams so it tiles
big.save("game/slice/tex/wall_streaks.png"); print("wrote game/slice/tex/wall_streaks.png", big.size)
