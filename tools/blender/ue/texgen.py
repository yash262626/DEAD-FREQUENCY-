"""Texture composition for the Listener from baked maps (numpy). Colour work is done in linear space.

Body maps out:  BaseColor (sRGB), Normal (DirectX: green flipped, for Unreal), ORM (AO, roughness, metal),
                SSS (subsurface opacity for Unreal's Subsurface Profile shading model).
Head maps out:  the same set for the membrane.
"""
import numpy as np


def srgb_to_lin(c):
    c = np.asarray(c, np.float32) / 255.0
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def lin_to_srgb(x):
    x = np.clip(x, 0.0, 1.0)
    return np.where(x <= 0.0031308, x * 12.92, 1.055 * np.power(x, 1 / 2.4) - 0.055)


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def lerp(a, b, t):
    t = np.asarray(t)[..., None] if np.ndim(t) == 2 else t
    return a * (1 - t) + b * t


def value_noise3(P, scale, seed=0, octaves=4, lac=2.0, gain=0.5):
    """Fractal value noise of 3D positions P (H, W, 3) -> (H, W) in [0, 1]. Continuous across UV seams."""
    rng = np.random.default_rng(seed)
    table = rng.random(256 ** 1 * 64).astype(np.float32)
    perm = rng.permutation(4096)
    out = np.zeros(P.shape[:2], np.float32)
    amp, tot, s = 1.0, 0.0, scale
    for o in range(octaves):
        Q = P * s + o * 17.31
        i = np.floor(Q).astype(np.int64)
        f = (Q - i).astype(np.float32)
        f = f * f * (3 - 2 * f)

        def h(dx, dy, dz):
            k = perm[(i[..., 0] + dx) & 4095] ^ ((i[..., 1] + dy) * 73856093 & 4095) ^ ((i[..., 2] + dz) * 19349663 & 4095)
            return table[k % len(table)]
        c000, c100, c010, c110 = h(0, 0, 0), h(1, 0, 0), h(0, 1, 0), h(1, 1, 0)
        c001, c101, c011, c111 = h(0, 0, 1), h(1, 0, 1), h(0, 1, 1), h(1, 1, 1)
        fx, fy, fz = f[..., 0], f[..., 1], f[..., 2]
        x00 = c000 + (c100 - c000) * fx
        x10 = c010 + (c110 - c010) * fx
        x01 = c001 + (c101 - c001) * fx
        x11 = c011 + (c111 - c011) * fx
        y0 = x00 + (x10 - x00) * fy
        y1 = x01 + (x11 - x01) * fy
        out += amp * (y0 + (y1 - y0) * fz)
        tot += amp
        amp *= gain
        s *= lac
    return out / tot


def blur(x, r=2):
    """Separable box blur (r texels), repeated twice: a cheap soft falloff for masks."""
    for _ in range(2):
        for ax in (0, 1):
            c = np.cumsum(np.pad(x, [(r + 1, r) if a == ax else (0, 0) for a in range(2)], mode="edge"), axis=ax)
            if ax == 0:
                x = (c[2 * r + 1:] - c[:-2 * r - 1]) / (2 * r + 1)
            else:
                x = (c[:, 2 * r + 1:] - c[:, :-2 * r - 1]) / (2 * r + 1)
    return x


def curvature_from_normal(n):
    """Convexity from a tangent-space normal map (H, W, 3 in 0..1): divergence of the xy slope."""
    nx = n[..., 0] * 2 - 1
    ny = n[..., 1] * 2 - 1
    dx = np.zeros_like(nx)
    dy = np.zeros_like(ny)
    dx[:, 1:-1] = (nx[:, 2:] - nx[:, :-2]) * 0.5
    dy[1:-1, :] = (ny[2:, :] - ny[:-2, :]) * 0.5
    return dx + dy


def to_u8(x):
    return (np.clip(x, 0, 1) * 255.0 + np.random.default_rng(0).uniform(-0.5, 0.5, np.shape(x))).clip(0, 255).astype(np.uint8)


def normal_dx(n):
    """Blender bakes OpenGL-style normals (+Y up); Unreal reads DirectX-style (-Y): flip green."""
    out = n.copy()
    out[..., 1] = 1.0 - out[..., 1]
    return out


# ------------------------------------------------------------------------------------------------ body

PAL = {k: srgb_to_lin(v) for k, v in {
    "pale": (206, 196, 188), "cool": (176, 182, 190), "sallow": (198, 188, 160), "flush": (200, 128, 126),
    "bruise": (150, 124, 150), "vein_deep": (122, 136, 170), "vein": (118, 70, 96), "cap": (186, 100, 104),
    "mottle_r": (196, 156, 150), "mottle_b": (168, 170, 186),
    "grime": (112, 100, 86), "blood_dry": (52, 16, 12), "blood_wet": (96, 14, 12), "keratin": (128, 112, 82),
    "keratin_tip": (42, 34, 28), "nail_bed": (150, 88, 82),
}.items()}


def body_maps(normal, ao, thick, pos, part, masks):
    """All inputs at the output size (H, W, ...). Returns dict of float maps."""
    H, W = ao.shape
    covered = np.linalg.norm(pos, axis=2) > 1e-3
    n1 = value_noise3(pos, 0.035, seed=1, octaves=4)
    n2 = value_noise3(pos, 0.12, seed=2, octaves=4)
    n3 = value_noise3(pos, 0.6, seed=3, octaves=3)
    z = pos[..., 2]
    claw = np.abs(part - 20.0) < 0.5
    hand = (np.abs(part - 3) < 0.5) | (np.abs(part - 4) < 0.5)
    foot = (np.abs(part - 7) < 0.5) | (np.abs(part - 8) < 0.5)
    curv = blur(curvature_from_normal(normal), 1) * 6.0
    cavity = np.clip(-curv, 0, 1)
    edges = np.clip(curv, 0, 1)
    thin = np.clip(1.0 - thick, 0, 1)
    R, G, B = masks[..., 0], masks[..., 1], masks[..., 2]
    # skin: pallor with cool and sallow drifts, faint bruise-like mottling
    col = lerp(PAL["pale"], PAL["cool"], smoothstep(0.35, 0.75, n1))
    col = lerp(col, PAL["sallow"], 0.35 * smoothstep(0.45, 0.8, n2))
    col = lerp(col, PAL["bruise"], 0.3 * smoothstep(0.62, 0.82, value_noise3(pos, 0.08, seed=4)))
    mot = value_noise3(pos, 0.32, seed=7, octaves=3)                 # blotchy pallor at the scale of a hand
    col = lerp(col, PAL["mottle_r"], 0.28 * smoothstep(0.55, 0.75, mot))
    col = lerp(col, PAL["mottle_b"], 0.22 * smoothstep(0.55, 0.75, 1 - mot))
    # blood close under thin skin: knuckles, fingertips, toes, the root of the membrane
    head_root = np.clip(1.0 - np.linalg.norm(pos - np.array([0, -1.0, 205.0]), axis=2) / 22.0, 0, 1)
    flush = np.clip(thin ** 1.4 * (0.6 + 0.6 * (hand | foot)) + 0.8 * head_root ** 1.5, 0, 1)
    col = lerp(col, PAL["flush"], 0.55 * flush)
    cap = smoothstep(0.55, 0.75, n3) * flush
    col = lerp(col, PAL["cap"], 0.35 * cap)
    # veins: deep ones as a cold shadow under the skin, raised ones darker and warmer
    vis = 0.45 + 0.55 * smoothstep(0.3, 0.7, value_noise3(pos, 0.2, seed=8, octaves=2))   # veins fade in and out
    col = lerp(col, PAL["vein_deep"], 0.32 * blur(G, 3) * vis)
    col = lerp(col, PAL["vein"], 0.5 * blur(R, 1) * vis)
    # cavities and grime, worse toward the ground and on the hands
    col = col * (0.35 + 0.65 * ao[..., None] ** 0.9)
    col = col * (1.0 - 0.35 * cavity[..., None]) * (1.0 + 0.08 * edges[..., None])
    grime = np.clip(0.4 * cavity + 0.35 * smoothstep(26, 2, z) * n2 + 0.15 * hand * n1, 0, 1)
    col = lerp(col, PAL["grime"], 0.35 * grime)
    # dried blood runs, broken up; still wet near the membrane
    bl = np.clip(blur(B, 1) * (0.55 + 0.6 * value_noise3(pos, 0.5, seed=5, octaves=3)), 0, 1)
    wet = smoothstep(180, 200, z)
    col = lerp(col, lerp(PAL["blood_dry"], PAL["blood_wet"], wet), bl)
    # claws: keratin darkening to the tip, blood in the grooves
    tipness = np.clip(value_noise3(pos, 0.9, seed=6, octaves=2), 0, 1)
    kcol = lerp(PAL["keratin"], PAL["keratin_tip"], 0.5 + 0.5 * tipness)
    kcol = kcol * (0.55 + 0.45 * ao[..., None])
    col = np.where(claw[..., None], kcol, col)
    rough = 0.5 + 0.08 * (n2 - 0.5) + 0.12 * cavity - 0.06 * R + 0.18 * grime
    rough = np.where(bl > 0.2, rough * (1 - bl) + bl * (0.62 - 0.4 * wet), rough)
    rough = rough - 0.2 * head_root ** 2
    rough = np.where(claw, 0.34 + 0.1 * tipness, rough)
    sss = np.clip(0.55 + 0.45 * thin - 0.6 * bl - 0.3 * grime, 0, 1)
    sss = np.where(claw, 0.0, sss)
    col[~covered] = PAL["pale"] * 0.5
    return {"BaseColor": col, "Normal": normal, "ORM": np.stack([ao, np.clip(rough, 0.05, 1), np.zeros_like(ao)], -1),
            "SSS": sss}


# ------------------------------------------------------------------------------------------------ membrane

HPAL = {k: srgb_to_lin(v) for k, v in {
    "outer": (206, 176, 170), "outer_thin": (214, 150, 146), "cartilage": (222, 210, 182), "inner": (118, 22, 26),
    "throat": (34, 6, 8), "pore": (16, 4, 5), "vein_o": (146, 46, 68), "vein_i": (64, 8, 14), "lip": (92, 30, 28),
    "mucus": (150, 120, 96), "blood_dry": (52, 16, 12),
}.items()}


def head_maps(normal, ao, thick, pos, attrs, veins):
    """attrs: R layer/3, G depth u (0 throat, 1 rim), B strut field."""
    layer = np.round(attrs[..., 0] * 3.0)
    u = np.clip(attrs[..., 1], 0, 1)
    strut = np.clip(attrs[..., 2], 0, 1)
    covered = np.linalg.norm(pos, axis=2) > 1e-3
    inner = (layer >= 2)
    lip = np.abs(layer - 1) < 0.5
    n1 = value_noise3(pos, 0.08, seed=11, octaves=4)
    pores = smoothstep(0.83, 0.92, value_noise3(pos, 1.6, seed=12, octaves=1)) * inner * smoothstep(0.05, 0.4, u)
    thin = np.clip(1.0 - thick, 0, 1)
    v = blur(veins, 1)
    outer_col = lerp(HPAL["outer"], HPAL["outer_thin"], 0.6 * thin)
    outer_col = lerp(outer_col, HPAL["cartilage"], 0.75 * strut)
    outer_col = lerp(outer_col, HPAL["vein_o"], 0.75 * v)
    inner_col = lerp(HPAL["throat"], HPAL["inner"], smoothstep(0.0, 0.7, u) * (0.75 + 0.25 * n1))[...]
    inner_col = lerp(inner_col, HPAL["vein_i"], 0.6 * v)
    inner_col = lerp(inner_col, HPAL["pore"], pores)
    col = np.where(inner[..., None], inner_col, outer_col)
    col = np.where(lip[..., None], lerp(outer_col, HPAL["lip"], 0.6), col)
    col = col * (0.4 + 0.6 * ao[..., None] ** 0.8)
    mucus = smoothstep(0.7, 0.85, value_noise3(pos, 0.25, seed=13, octaves=3)) * (inner | lip)
    col = lerp(col, HPAL["mucus"], 0.25 * mucus)
    rough = np.where(inner, 0.16 + 0.1 * pores + 0.05 * n1, 0.42 + 0.08 * (n1 - 0.5) - 0.1 * thin)
    rough = np.where(lip, 0.3, rough) - 0.08 * mucus
    sss = np.clip(np.where(inner, 0.7, 0.95) * (1 - 0.35 * strut), 0, 1)
    col[~covered] = HPAL["inner"] * 0.5
    return {"BaseColor": col, "Normal": normal, "ORM": np.stack([ao, np.clip(rough, 0.05, 1), np.zeros_like(ao)], -1),
            "SSS": sss}
