"""Claws and surface detail geometry for the Listener (numpy; the surface walk needs Blender's BVH tree).

claws_mesh: keratin claws, curved and tapered, flattened sideways, with growth ridges in the high version.
tubes_mesh: tubes along polylines (veins, blood runs) with per-point radius.
walk_surface: random walks over a mesh surface, steered by a goal direction (Blender BVHTree).
"""
import numpy as np


def _unit(v):
    v = np.asarray(v, float)
    return v / np.linalg.norm(v)


def claws_mesh(claws, n_side=10, n_len=9, ridges=False):
    """claws: list of (tip_of_digit, direction, length, base_radius, curl_axis). Returns verts, quads, tris, claw id."""
    V, Q, T, ID = [], [], [], []
    for ci, (base, d, L, r, lat) in enumerate(claws):
        base, d, lat = np.asarray(base, float), _unit(d), _unit(lat)
        up = _unit(np.cross(lat, d))                 # the claw's back (away from the palm/ground)
        start = len(V) and sum(len(v) for v in V)
        rows = []
        p = base - 0.55 * L * 0.25 * d               # root sits inside the fingertip like a nail bed
        heading = d.copy()
        seg = L * 1.1 / (n_len - 1)
        for i in range(n_len):
            t = i / (n_len - 1)
            rad = r * (1.0 - t) ** 0.85 + 0.02
            # cross-section: a laterally flattened teardrop, sharper on the underside
            ang = np.linspace(0, 2 * np.pi, n_side, endpoint=False)
            wid = rad * 0.72
            hgt = rad * (1.0 + 0.25 * np.clip(np.cos(ang), 0, 1))
            off = (np.cos(ang)[:, None] * up[None] * hgt[:, None] + np.sin(ang)[:, None] * lat[None] * wid)
            if ridges:
                off *= (1.0 + 0.04 * np.sin(t * 40.0))   # growth ridges
            rows.append(p[None] + off)
            # curl downward toward the tip (like a raptor's talon)
            heading = _unit(heading * np.cos(np.radians(9.0)) - up * np.sin(np.radians(9.0)))
            up = _unit(np.cross(lat, heading))
            p = p + heading * seg
        tip = p
        rows = np.concatenate(rows)
        n0 = sum(len(v) for v in V)
        V.append(rows)
        V.append(tip[None])
        for i in range(n_len - 1):
            a = n0 + i * n_side + np.arange(n_side)
            b = n0 + i * n_side + (np.arange(n_side) + 1) % n_side
            Q.append(np.stack([a, b, b + n_side, a + n_side], axis=1))
        last = n0 + (n_len - 1) * n_side
        tip_i = n0 + n_len * n_side
        T.append(np.stack([last + np.arange(n_side), last + (np.arange(n_side) + 1) % n_side, np.full(n_side, tip_i)], axis=1))
        ID.append(np.full(n_len * n_side + 1, ci))
        del start
    return np.concatenate(V), np.concatenate(Q), np.concatenate(T), np.concatenate(ID)


def tubes_mesh(paths, n_side=6):
    """paths: list of (points (k,3), radii (k,)). Returns verts, quads (open-ended tubes)."""
    V, Q = [], []
    n = 0
    for pts, rad in paths:
        pts = np.asarray(pts, float)
        if len(pts) < 2:
            continue
        tan = np.gradient(pts, axis=0)
        tan /= np.maximum(np.linalg.norm(tan, axis=1, keepdims=True), 1e-9)
        ref = np.array([0.0, 0.0, 1.0])
        rows = []
        prev = None
        for i, (p, t, r) in enumerate(zip(pts, tan, rad)):
            if prev is None:
                a = np.cross(t, ref)
                if np.linalg.norm(a) < 1e-3:
                    a = np.cross(t, [1.0, 0, 0])
            else:                                    # parallel transport: no twisting along the tube
                a = prev - t * np.dot(prev, t)
            a = _unit(a)
            b = np.cross(t, a)
            prev = a
            ang = np.linspace(0, 2 * np.pi, n_side, endpoint=False)
            rows.append(p[None] + r * (np.cos(ang)[:, None] * a[None] + np.sin(ang)[:, None] * b[None]))
        rows = np.concatenate(rows)
        k = len(pts)
        for i in range(k - 1):
            a_ = n + i * n_side + np.arange(n_side)
            b_ = n + i * n_side + (np.arange(n_side) + 1) % n_side
            Q.append(np.stack([a_, b_, b_ + n_side, a_ + n_side], axis=1))
        V.append(rows)
        n += len(rows)
    return np.concatenate(V), np.concatenate(Q)


def walk_surface(bvh, start, goal, length, step=0.7, wander=0.35, rng=None, stop=None, gravity=None):
    """Random walk on the surface from `start`, drifting toward `goal` (a direction, or a callable p -> direction).
    Returns points (k,3) and normals (k,3)."""
    from mathutils import Vector
    rng = rng or np.random.default_rng()
    hit = bvh.find_nearest(Vector(start))
    if hit[0] is None:
        return np.zeros((0, 3)), np.zeros((0, 3))
    p, n = np.array(hit[0]), np.array(hit[1])
    g0 = goal(p) if callable(goal) else np.asarray(goal, float)
    d = _unit(g0 - n * np.dot(g0, n) + 1e-6)
    pts, nrm = [p], [n]
    travelled = 0.0
    while travelled < length:
        g = goal(p) if callable(goal) else np.asarray(goal, float)
        if gravity is not None:
            g = g + gravity
        jitter = rng.normal(0, 1, 3)
        d = d + 0.35 * _unit(g) + wander * jitter
        d = d - n * np.dot(d, n)
        if np.linalg.norm(d) < 1e-6:
            break
        d = _unit(d)
        q = p + d * step
        hit = bvh.find_nearest(Vector(q))
        if hit[0] is None:
            break
        p_new, n_new = np.array(hit[0]), np.array(hit[1])
        if np.linalg.norm(p_new - p) < step * 0.2:
            break
        p, n = p_new, n_new
        pts.append(p)
        nrm.append(n)
        travelled += step
        if stop is not None and stop(p):
            break
    return np.array(pts), np.array(nrm)
