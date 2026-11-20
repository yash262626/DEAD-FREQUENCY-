"""Procedural-but-authored animation for the Listener: poses as world-space intentions (aims, IK targets,
spine curves) converted to local bone rotations and written as keyframes. Loops are made periodic by running
secondary motion (springs) for several cycles and keeping the last.

Pose math: armature-space frames W (4x4). For bone b with parent p and rest frames Rb, Rp (bone.matrix_local):
    W_b = W_p @ (Rp^-1 @ Rb) @ Basis_b        Basis_b = (Rp^-1 @ Rb)^-1 @ W_p^-1 @ W_b
"""
import numpy as np

FPS = 30


def unit(v):
    v = np.asarray(v, float)
    n = np.linalg.norm(v)
    return v / n if n > 1e-12 else v


def axis_angle(axis, ang):
    axis = unit(axis)
    x, y, z = axis
    c, s = np.cos(ang), np.sin(ang)
    C = 1 - c
    return np.array([[c + x * x * C, x * y * C - z * s, x * z * C + y * s],
                     [y * x * C + z * s, c + y * y * C, y * z * C - x * s],
                     [z * x * C - y * s, z * y * C + x * s, c + z * z * C]])


def rot_between(a, b):
    """Smallest rotation taking direction a to direction b."""
    a, b = unit(a), unit(b)
    v = np.cross(a, b)
    s = np.linalg.norm(v)
    c = np.dot(a, b)
    if s < 1e-9:
        if c > 0:
            return np.eye(3)
        perp = unit(np.cross(a, [1, 0, 0] if abs(a[0]) < 0.9 else [0, 1, 0]))
        return axis_angle(perp, np.pi)
    return axis_angle(v / s, np.arctan2(s, c))


def mat4(R, t):
    M = np.eye(4)
    M[:3, :3] = R
    M[:3, 3] = t
    return M


def quat_from_mat(R):
    m = R
    tr = m[0, 0] + m[1, 1] + m[2, 2]
    if tr > 0:
        s = np.sqrt(tr + 1.0) * 2
        w, x, y, z = 0.25 * s, (m[2, 1] - m[1, 2]) / s, (m[0, 2] - m[2, 0]) / s, (m[1, 0] - m[0, 1]) / s
    elif m[0, 0] > m[1, 1] and m[0, 0] > m[2, 2]:
        s = np.sqrt(1.0 + m[0, 0] - m[1, 1] - m[2, 2]) * 2
        w, x, y, z = (m[2, 1] - m[1, 2]) / s, 0.25 * s, (m[0, 1] + m[1, 0]) / s, (m[0, 2] + m[2, 0]) / s
    elif m[1, 1] > m[2, 2]:
        s = np.sqrt(1.0 + m[1, 1] - m[0, 0] - m[2, 2]) * 2
        w, x, y, z = (m[0, 2] - m[2, 0]) / s, (m[0, 1] + m[1, 0]) / s, 0.25 * s, (m[1, 2] + m[2, 1]) / s
    else:
        s = np.sqrt(1.0 + m[2, 2] - m[0, 0] - m[1, 1]) * 2
        w, x, y, z = (m[1, 0] - m[0, 1]) / s, (m[0, 2] + m[2, 0]) / s, (m[1, 2] + m[2, 1]) / s, 0.25 * s
    q = np.array([w, x, y, z])
    return q / np.linalg.norm(q)


class Rig:
    """Rest data copied from a Blender armature (armature space, centimetres)."""

    def __init__(self, arm_obj):
        bones = arm_obj.data.bones
        self.names = [b.name for b in bones]
        self.index = {n: i for i, n in enumerate(self.names)}
        self.parent = [self.index[b.parent.name] if b.parent else -1 for b in bones]
        self.rest = np.array([np.array(b.matrix_local) for b in bones])
        self.length = np.array([b.length for b in bones])
        self.children = {n: [] for n in self.names}
        for b in bones:
            if b.parent:
                self.children[b.parent.name].append(b.name)
        self.rel = np.empty_like(self.rest)
        for i, p in enumerate(self.parent):
            self.rel[i] = self.rest[i] if p < 0 else np.linalg.inv(self.rest[p]) @ self.rest[i]

    def head(self, n):
        return self.rest[self.index[n]][:3, 3]

    def tail(self, n):
        i = self.index[n]
        return self.rest[i][:3, 3] + self.rest[i][:3, 1] * self.length[i]


class Pose:
    """World frames built top-down. Set local rotations (bone-local axis-angle or matrices) or world aims."""

    def __init__(self, rig):
        self.rig = rig
        self.basis = np.tile(np.eye(4), (len(rig.names), 1, 1))
        self.W = None

    def local(self, name, R=None, t=None):
        i = self.rig.index[name]
        if R is not None:
            self.basis[i][:3, :3] = R @ self.basis[i][:3, :3]
        if t is not None:
            self.basis[i][:3, 3] += t

    def rot(self, name, axis, deg):
        """Rotate a bone about one of its own rest axes ('x', 'y', 'z') or a local vector."""
        ax = {"x": [1, 0, 0], "y": [0, 1, 0], "z": [0, 0, 1]}.get(axis, axis)
        self.local(name, axis_angle(ax, np.radians(deg)))

    def solve(self):
        r = self.rig
        W = np.empty_like(r.rest)
        for i in range(len(r.names)):
            p = r.parent[i]
            W[i] = (r.rel[i] if p < 0 else W[p] @ r.rel[i]) @ self.basis[i]
        self.W = W
        return W

    def world(self, name):
        if self.W is None:
            self.solve()
        return self.W[self.rig.index[name]]

    def set_world_rot(self, name, Rw):
        """Give a bone this armature-space orientation (keeps its solved head position)."""
        r = self.rig
        i = r.index[name]
        p = r.parent[i]
        if self.W is None:
            self.solve()
        Wp = np.eye(4) if p < 0 else self.W[p]
        target = mat4(Rw, self.W[i][:3, 3])
        B = np.linalg.inv(r.rel[i]) @ np.linalg.inv(Wp) @ target
        self.basis[i][:3, :3] = B[:3, :3]
        self.solve_from(i)

    def solve_from(self, i):
        r = self.rig
        stack = [i]
        while stack:
            k = stack.pop()
            p = r.parent[k]
            self.W[k] = (r.rel[k] if p < 0 else self.W[p] @ r.rel[k]) @ self.basis[k]
            stack.extend(r.index[c] for c in r.children[r.names[k]])

    def aim(self, name, direction, twist_ref=None):
        """Point the bone along a world direction with the smallest swing from its current frame."""
        W = self.world(name)
        R = W[:3, :3]
        Rn = rot_between(R[:, 1], direction) @ R
        if twist_ref is not None:                      # roll about the bone so its Z leans toward twist_ref
            y = Rn[:, 1]
            z = unit(twist_ref - y * np.dot(twist_ref, y))
            x = np.cross(y, z)
            Rn = np.stack([x, y, z], axis=1)
        self.set_world_rot(name, Rn)

    def ik(self, upper, lower, target, pole, z_to_pole=True, end=None, end_rot=None):
        """Two-bone IK (upper -> lower) bending toward `pole`, then optionally orient the end bone (world rotation).
        z_to_pole: the bones' Z axes face the pole side (legs: knee front) or away from it (arms: elbow points back)."""
        a = self.world(upper)[:3, 3]
        lu = self.rig.length[self.rig.index[upper]]
        ll = self.rig.length[self.rig.index[lower]]
        d = np.asarray(target, float) - a
        dist = np.clip(np.linalg.norm(d), abs(lu - ll) + 1e-3, lu + ll - 1e-3)
        dn = unit(d)
        cos_a = (lu * lu + dist * dist - ll * ll) / (2 * lu * dist)
        ang = np.arccos(np.clip(cos_a, -1, 1))
        pv = np.asarray(pole, float) - a
        pv = unit(pv - dn * np.dot(pv, dn))
        knee = a + dn * np.cos(ang) * lu + pv * np.sin(ang) * lu
        tip = a + dn * dist
        zref = pv if z_to_pole else -pv
        self.aim(upper, knee - a, twist_ref=zref)
        self.aim(lower, tip - knee, twist_ref=zref)
        if end is not None and end_rot is not None:
            self.set_world_rot(end, end_rot)
        return knee, tip

    def basis_quats(self):
        out = {}
        for i, n in enumerate(self.rig.names):
            out[n] = (quat_from_mat(self.basis[i][:3, :3]), self.basis[i][:3, 3].copy())
        return out


# ------------------------------------------------------------------------------------------------ helpers

def smooth(x):
    x = np.clip(x, 0.0, 1.0)
    return x * x * (3 - 2 * x)


def smoother(x):
    x = np.clip(x, 0.0, 1.0)
    return x * x * x * (x * (6 * x - 15) + 10)


def keys(t, pts):
    """Piecewise smooth interpolation through (time, value) keys; value may be scalar or array."""
    ts = [p[0] for p in pts]
    if t <= ts[0]:
        return np.asarray(pts[0][1], float)
    for (t0, v0), (t1, v1) in zip(pts[:-1], pts[1:]):
        if t <= t1:
            f = smoother((t - t0) / max(t1 - t0, 1e-9))
            return np.asarray(v0, float) * (1 - f) + np.asarray(v1, float) * f
    return np.asarray(pts[-1][1], float)


class Spring:
    """Damped spring following a target (critically-ish damped), for lag and overshoot."""

    def __init__(self, freq=3.0, damp=0.35, value=0.0):
        self.w = 2 * np.pi * freq
        self.z = damp
        self.x = np.asarray(value, float)
        self.v = np.zeros_like(self.x)

    def step(self, target, dt=1.0 / FPS):
        a = self.w * self.w * (np.asarray(target, float) - self.x) - 2 * self.z * self.w * self.v
        self.v = self.v + a * dt
        self.x = self.x + self.v * dt
        return self.x


def noise1(t, seed=0, octaves=3):
    """Smooth 1D value noise in [-1, 1]."""
    rng = np.random.default_rng(seed)
    lat = rng.uniform(-1, 1, 512)
    out, amp, f, tot = 0.0, 1.0, 1.0, 0.0
    for _ in range(octaves):
        x = t * f
        i = int(np.floor(x)) % 511
        fr = x - np.floor(x)
        out += amp * (lat[i] * (1 - smooth(fr)) + lat[i + 1] * smooth(fr))
        tot += amp
        amp *= 0.5
        f *= 2.0
    return out / tot
