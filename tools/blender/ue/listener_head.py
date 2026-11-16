"""The Listener's head: a fleshy acoustic horn growing out of the top of the neck.

A thin membrane shell (outer skin, rolled lip, inner skin, gullet) stretched over cartilage struts. Between the
struts the membrane sags inward and its edge pulls back, so the rim is scalloped and the struts end in points.
The inside narrows to ribbed rings and a dark gullet. The same parametric surface is generated at any resolution,
so the game mesh (low) and the bake source (high, with relief) line up exactly.

Units are centimetres; the creature faces -Y. Returns vertices, faces and per-vertex parameters:
    theta (0..2pi around the horn), u (0 throat .. 1 rim), layer (0 outer, 1 lip, 2 inner, 3 gullet).
"""
import numpy as np

TAU = 2.0 * np.pi
RNG = np.random.default_rng(1998)

# struts: angle (radians around the horn, 0 = the creature's up side), extension past the rim, strength
STRUTS = [(0.10, 1.00, 1.00), (0.86, 0.85, 0.85), (1.62, 1.10, 1.00), (2.33, 0.75, 0.80), (3.02, 0.95, 0.90),
          (3.74, 1.05, 1.00), (4.47, 0.80, 0.85), (5.20, 1.00, 0.95), (5.73, 0.55, 0.60)]


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def angdiff(a, b):
    return (a - b + np.pi) % TAU - np.pi


def strut_field(theta, width):
    """1 on a strut, falling to 0 between struts (sharpness from width in radians)."""
    f = np.zeros_like(theta)
    for ang, _, k in STRUTS:
        f = np.maximum(f, k * np.exp(-(angdiff(theta, ang) / width) ** 2))
    return f


def tears(theta):
    """Two torn notches in the rim (healed, ragged)."""
    t = np.zeros_like(theta)
    for ang, depth, w in ((2.72, 0.07, 0.035), (5.02, 0.045, 0.025)):
        t += depth * np.exp(-(angdiff(theta, ang) / w) ** 2)
    return t


def strut_extension(theta):
    e = np.zeros_like(theta)
    for ang, ext, _ in STRUTS:
        e = np.maximum(e, ext * np.exp(-(angdiff(theta, ang) / 0.075) ** 2))
    return e


class Horn:
    def __init__(self, base, axis, up, length=36.0, r0=3.1, r1=25.0, bend=0.13):
        self.base = np.asarray(base, float)
        self.D = axis / np.linalg.norm(axis)
        up = np.asarray(up, float)
        self.U = up - np.dot(up, self.D) * self.D
        self.U /= np.linalg.norm(self.U)
        self.S = np.cross(self.D, self.U)           # side
        self.L, self.r0, self.r1, self.bend = length, r0, r1, bend

    def frame_at(self, s):
        """Centreline point and local axes at depth s in [0, 1] (the horn curves upward toward the rim)."""
        c = self.base[None] + self.L * (s[:, None] * self.D[None] + self.bend * s[:, None] ** 2 * self.U[None])
        tan = self.D[None] + 2 * self.bend * s[:, None] * self.U[None]
        tan /= np.linalg.norm(tan, axis=1, keepdims=True)
        u = self.U[None] - (tan @ self.U)[:, None] * tan
        u /= np.linalg.norm(u, axis=1, keepdims=True)
        side = np.cross(tan, u)
        return c, tan, u, side

    def outer(self, theta, u):
        """Outer skin point for grids theta (n,) x u (m,) -> (m, n, 3); u in [-0.08, 1]."""
        T, Uu = np.meshgrid(theta, u)
        smax = (1.0 + 0.028 * strut_extension(T) - 0.022 * (1 - strut_field(T, 0.3))
                + 0.018 * np.sin(7 * T + 0.4) * np.sin(3 * T) - tears(T))
        s = np.clip(Uu, -0.08, 1.0) * smax
        sc = np.clip(s, 0.0, None)
        c, tan, up, side = self.frame_at(sc.reshape(-1))
        R = self.r0 + (self.r1 - self.r0) * sc.reshape(-1) ** 2.35
        th = T.reshape(-1)
        field_w = strut_field(th, 0.20)
        sag = 0.05 * smoothstep(0.25, 1.0, sc.reshape(-1)) * (1 - field_w)
        ridge = 0.55 * smoothstep(0.12, 0.45, sc.reshape(-1)) * strut_field(th, 0.045)
        # asymmetry: an oval mouth, wider on the left, a little lower on the right
        oval = 1.0 + 0.09 * np.cos(2 * th) + 0.05 * np.sin(th + 0.6)
        lip = smoothstep(0.9, 1.0, Uu.reshape(-1))
        Rf = R * oval * (1 - sag) + ridge + 1.1 * lip
        # a slow wave in the membrane so the panels are not perfect
        Rf += 0.35 * sc.reshape(-1) ** 2 * np.sin(3 * th + 1.3) * np.sin(5.0 * sc.reshape(-1) + th)
        ax = -0.9 * lip - 2.2 * np.clip(-Uu.reshape(-1), 0, None) / 0.08     # rim rolls back; u<0 dives into the neck
        P = c + (np.cos(th)[:, None] * up + np.sin(th)[:, None] * side) * Rf[:, None] + ax[:, None] * tan
        return P.reshape(len(u), len(theta), 3), s

    def build(self, n_theta=64, n_u=26, n_lip=4, n_gullet=6, thick=None):
        """Closed shell (open only deep inside the neck). Returns verts, quads, theta, u, layer."""
        theta = np.linspace(0, TAU, n_theta, endpoint=False)
        uu = np.concatenate([[-0.08, -0.03], np.linspace(0.0, 1.0, n_u) ** 0.85])
        P, s = self.outer(theta, uu)
        # normals by finite differences (outward from the axis)
        dth = np.roll(P, -1, axis=1) - np.roll(P, 1, axis=1)
        du = np.gradient(P, axis=0)
        N = np.cross(du, dth)
        N /= np.linalg.norm(N, axis=2, keepdims=True)
        c, _, _, _ = self.frame_at(np.clip(s.reshape(-1), 0, None))
        radial = P.reshape(-1, 3) - c
        flip = (N.reshape(-1, 3) * radial).sum(1) < 0
        N = N.reshape(-1, 3)
        N[flip] *= -1
        N = N.reshape(P.shape)
        T, Uu = np.meshgrid(theta, uu)
        t = (0.32 + 1.3 * np.clip(1 - Uu, 0, 1) ** 4 + 0.55 * smoothstep(0.92, 1.0, Uu) + 0.45 * strut_field(T, 0.05))
        if thick is not None:
            t = t * thick
        inner = P - N * t[..., None]
        # lip: half-circle from the outer rim round to the inner rim
        rim_o, rim_i, rim_n = P[-1], inner[-1], N[-1]
        edge = P[-1] - P[-2]
        edge /= np.linalg.norm(edge, axis=1, keepdims=True)
        lips = []
        for j in range(1, n_lip + 1):
            a = np.pi * j / (n_lip + 1)
            mid = 0.5 * (rim_o + rim_i)
            half = 0.5 * (rim_o - rim_i)
            lips.append(mid + half * np.cos(a) + edge * (0.5 * np.linalg.norm(half, axis=1, keepdims=True)) * np.sin(a))
        lips = np.stack(lips)
        # gullet: the inner skin narrows into a dark tube that closes inside the neck
        base_ring = inner[2]
        cg = base_ring.mean(axis=0)
        gul = []
        for j in range(1, n_gullet + 1):
            f = j / (n_gullet + 1)
            ring = cg + (base_ring - cg) * (1 - 0.85 * f) - self.D * (5.5 * f)
            gul.append(ring)
        gul = np.stack(gul)
        tip = cg - self.D * 6.2
        # assemble rows: outer (throat -> rim), lip, inner (rim -> throat), gullet (-> tip)
        rows = [P[i] for i in range(len(uu))] + [lips[j] for j in range(n_lip)] + \
               [inner[i] for i in range(len(uu) - 1, 1, -1)] + [gul[j] for j in range(n_gullet)]
        u_rows = list(uu) + [1.0] * n_lip + list(uu[len(uu) - 1:1:-1]) + list(-0.08 - 0.02 * np.arange(1, n_gullet + 1))
        layer_rows = [0] * len(uu) + [1] * n_lip + [2] * (len(uu) - 2) + [3] * n_gullet
        V = np.concatenate(rows + [tip[None]])
        nt = n_theta
        quads = []
        for r in range(len(rows) - 1):
            a = r * nt + np.arange(nt)
            b = r * nt + (np.arange(nt) + 1) % nt
            quads.append(np.stack([a, b, b + nt, a + nt], axis=1))
        quads = np.concatenate(quads)
        last = (len(rows) - 1) * nt
        tip_i = len(V) - 1
        tris = np.stack([last + np.arange(nt), last + (np.arange(nt) + 1) % nt, np.full(nt, tip_i)], axis=1)
        theta_v = np.concatenate([np.tile(theta, len(rows)), [0.0]])
        u_v = np.concatenate([np.repeat(u_rows, nt), [-0.3]])
        layer_v = np.concatenate([np.repeat(layer_rows, nt), [3]])
        return V, quads, tris, theta_v, u_v, layer_v


def relief(V, theta, u, layer, horn, seed=7):
    """High-poly relief for the bake: ribbed throat rings, pleats, veins along and between the struts, creases."""
    rng = np.random.default_rng(seed)
    c, tan, up, side = horn.frame_at(np.clip(u, 0, 1))
    radial = V - c
    radial -= (radial * tan).sum(1, keepdims=True) * tan
    radial /= np.maximum(np.linalg.norm(radial, axis=1, keepdims=True), 1e-6)
    d = np.zeros(len(V))
    inner = layer == 2
    outer = layer == 0
    uc = np.clip(u, 0, 1)
    # inside: rings near the throat (cartilage hoops) and radial pleats converging on the gullet
    rings = np.sin(TAU * uc * 21.0) ** 2 * (1 - uc) ** 1.6
    pleats = np.abs(np.sin(theta * 11.0 + 0.9 * np.sin(theta * 3.0) + 6.0 * uc)) ** 6 * smoothstep(0.05, 0.6, uc) * (1 - uc)
    d[inner] += (-0.42 * rings - 0.3 * pleats)[inner]
    # outside: the struts as hard cartilage ridges, creases where the membrane folds onto them
    ridge = strut_field(theta, 0.03) * smoothstep(0.1, 0.4, uc)
    crease = (strut_field(theta, 0.09) - strut_field(theta, 0.035)).clip(0) * smoothstep(0.2, 0.7, uc)
    d[outer] += (0.35 * ridge - 0.22 * crease)[outer]
    # veins: branching random walks in (theta, u) space, raised on both skins
    veins = vein_field(theta, uc, rng, horn=horn)
    d[outer | inner] += 0.16 * veins[outer | inner]
    return V + radial * d[:, None], veins


def vein_field(theta, u, rng, n_roots=18, horn=None):
    """Vein mask in parameter space (theta wraps): 1 on a vein's centre line, 0 away from it.
    Distances are measured in a metric where an angle step counts as the arc length it spans."""
    segs = []
    for i in range(n_roots):
        th = STRUTS[i % len(STRUTS)][0] + rng.normal(0, 0.06)
        uu = rng.uniform(0.05, 0.25)
        dth = rng.choice([-1, 1]) * rng.uniform(0.01, 0.05)
        stack = [(th, uu, dth, 0.0065, 0)]
        while stack:
            th, uu, dth, w, depth = stack.pop()
            for _ in range(int(rng.integers(8, 16))):
                nth = th + dth + rng.normal(0, 0.02)
                nu = uu + rng.uniform(0.02, 0.05)
                segs.append((th, uu, nth, nu, w))
                th, uu = nth, nu
                if nu > 1.02:
                    break
                if depth < 2 and rng.random() < 0.11:
                    stack.append((th, uu, -dth * rng.uniform(0.8, 2.0), w * 0.7, depth + 1))
                dth += rng.normal(0, 0.012)
    L = horn.L if horn is not None else 36.0
    r0 = horn.r0 if horn is not None else 3.1
    r1 = horn.r1 if horn is not None else 25.0
    scale = (r0 + (r1 - r0) * np.clip(u, 0, 1) ** 2.35) / L       # arc length per radian, in units of u
    mask = np.zeros(len(theta))
    order = np.argsort(u)
    us = u[order]
    for a_t, a_u, b_t, b_u, w in segs:
        lo, hi = min(a_u, b_u) - 0.06, max(a_u, b_u) + 0.06
        i0, i1 = np.searchsorted(us, lo), np.searchsorted(us, hi)
        if i1 <= i0:
            continue
        idx = order[i0:i1]
        sc = scale[idx]
        px = angdiff(theta[idx], a_t) * sc
        py = u[idx] - a_u
        ex = angdiff(b_t, a_t) * sc
        ey = b_u - a_u
        h = np.clip((px * ex + py * ey) / (ex * ex + ey * ey + 1e-12), 0.0, 1.0)
        dist = np.hypot(px - h * ex, py - h * ey)
        width = w * (0.6 + 1.5 * u[idx])
        mask[idx] = np.maximum(mask[idx], np.exp(-(dist / width) ** 2))
    return mask


def default_horn(head_base, neck_fwd):
    """The horn as it sits on the Listener: opening forward and up, tilted a little to its left."""
    head_base = np.asarray(head_base, float)
    root = head_base + 0.9 * np.asarray(neck_fwd, float) + np.array([0, 0, 0.6])
    D = np.array([0.10, -0.80, 0.56])
    D /= np.linalg.norm(D)
    return Horn(root + 1.2 * D, D, np.array([0.0, 0.0, 1.0]), length=35.0, r0=3.7, r1=24.0, bend=0.13)
