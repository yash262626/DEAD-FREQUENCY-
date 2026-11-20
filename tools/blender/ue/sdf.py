"""Signed-distance sculpting engine (numpy only, no Blender dependency).

Anatomy is described as primitives (round cones, ellipsoids, tori) combined with smooth unions and smooth
subtractions, evaluated on a regular grid (each primitive only touches its own bounding box), and turned into a
quad mesh with naive surface nets plus a projection step back onto the zero level set. Units are whatever the
caller uses (the Listener uses centimetres).
"""
import numpy as np

BIG = 1.0e3


def _norm(v):
    v = np.asarray(v, float)
    return v / np.linalg.norm(v)


def frame(axis, up=(0.0, 0.0, 1.0)):
    """Rotation matrix whose local Z is `axis` (columns = local x, y, z in world space)."""
    z = _norm(axis)
    up = np.asarray(up, float)
    if abs(np.dot(z, _norm(up))) > 0.95:
        up = np.array([1.0, 0.0, 0.0]) if abs(z[0]) < 0.9 else np.array([0.0, 1.0, 0.0])
    x = _norm(np.cross(up, z))
    y = np.cross(z, x)
    return np.stack([x, y, z], axis=1)


def rot_xyz(rx, ry, rz):
    """Rotation matrix from XYZ Euler angles in degrees (applied X, then Y, then Z)."""
    rx, ry, rz = np.radians([rx, ry, rz])
    cx, sx, cy, sy, cz, sz = np.cos(rx), np.sin(rx), np.cos(ry), np.sin(ry), np.cos(rz), np.sin(rz)
    Rx = np.array([[1, 0, 0], [0, cx, -sx], [0, sx, cx]])
    Ry = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]])
    Rz = np.array([[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]])
    return Rz @ Ry @ Rx


# ------------------------------------------------------------------------------------------------ primitives

class RoundCone:
    """Capsule with different end radii (I. Quilez's exact round cone)."""

    def __init__(self, a, b, r1, r2=None):
        self.a = np.asarray(a, float)
        self.b = np.asarray(b, float)
        self.r1 = float(r1)
        self.r2 = float(r1 if r2 is None else r2)
        L = np.linalg.norm(self.b - self.a)
        if abs(self.r1 - self.r2) >= L * 0.98:          # degenerate: keep it a valid cone
            m = 0.5 * (self.r1 + self.r2)
            d = 0.49 * L
            self.r1, self.r2 = m + d * np.sign(self.r1 - self.r2), m - d * np.sign(self.r1 - self.r2)

    def aabb(self):
        lo = np.minimum(self.a - self.r1, self.b - self.r2)
        hi = np.maximum(self.a + self.r1, self.b + self.r2)
        return lo, hi

    def sdf(self, X, Y, Z):
        ba = self.b - self.a
        l2 = float(np.dot(ba, ba))
        rr = self.r1 - self.r2
        a2 = l2 - rr * rr
        il2 = 1.0 / l2
        px, py, pz = X - self.a[0], Y - self.a[1], Z - self.a[2]
        y = px * ba[0] + py * ba[1] + pz * ba[2]
        z = y - l2
        qx, qy, qz = px * l2 - ba[0] * y, py * l2 - ba[1] * y, pz * l2 - ba[2] * y
        x2 = qx * qx + qy * qy + qz * qz
        y2 = y * y * l2
        z2 = z * z * l2
        k = np.sign(rr) * rr * rr * x2
        d_end = np.sqrt(x2 + z2) * il2 - self.r2
        d_start = np.sqrt(x2 + y2) * il2 - self.r1
        d_mid = (np.sqrt(x2 * a2 * il2) + y * rr) * il2 - self.r1
        return np.where(np.sign(z) * a2 * z2 > k, d_end, np.where(np.sign(y) * a2 * y2 < k, d_start, d_mid))


class Ellipsoid:
    """Ellipsoid with radii (rx, ry, rz) in its local frame R (columns = local axes in world)."""

    def __init__(self, c, r, R=None):
        self.c = np.asarray(c, float)
        self.r = np.asarray(r, float)
        self.R = np.eye(3) if R is None else np.asarray(R, float)

    def aabb(self):
        ext = np.abs(self.R) @ self.r
        return self.c - ext, self.c + ext

    def sdf(self, X, Y, Z):
        px, py, pz = X - self.c[0], Y - self.c[1], Z - self.c[2]
        R = self.R
        lx = px * R[0, 0] + py * R[1, 0] + pz * R[2, 0]
        ly = px * R[0, 1] + py * R[1, 1] + pz * R[2, 1]
        lz = px * R[0, 2] + py * R[1, 2] + pz * R[2, 2]
        rx, ry, rz = self.r
        k0 = np.sqrt((lx / rx) ** 2 + (ly / ry) ** 2 + (lz / rz) ** 2)
        k1 = np.sqrt((lx / (rx * rx)) ** 2 + (ly / (ry * ry)) ** 2 + (lz / (rz * rz)) ** 2)
        return k0 * (k0 - 1.0) / np.maximum(k1, 1e-9)


class Torus:
    """Torus around local Z of frame R: major radius `big`, tube radius `small`."""

    def __init__(self, c, big, small, R=None):
        self.c = np.asarray(c, float)
        self.big = float(big)
        self.small = float(small)
        self.R = np.eye(3) if R is None else np.asarray(R, float)

    def aabb(self):
        e = self.big + self.small
        return self.c - e, self.c + e

    def sdf(self, X, Y, Z):
        px, py, pz = X - self.c[0], Y - self.c[1], Z - self.c[2]
        R = self.R
        lx = px * R[0, 0] + py * R[1, 0] + pz * R[2, 0]
        ly = px * R[0, 1] + py * R[1, 1] + pz * R[2, 1]
        lz = px * R[0, 2] + py * R[1, 2] + pz * R[2, 2]
        q = np.sqrt(lx * lx + ly * ly) - self.big
        return np.sqrt(q * q + lz * lz) - self.small


# ------------------------------------------------------------------------------------------------ grid

class Grid:
    def __init__(self, lo, hi, h):
        self.lo = np.asarray(lo, float)
        self.h = float(h)
        self.n = (np.ceil((np.asarray(hi, float) - self.lo) / self.h).astype(int) + 1)
        self.d = np.full(tuple(self.n), BIG, np.float32)

    def axis(self, i, i0, i1):
        return (self.lo[i] + self.h * np.arange(i0, i1)).astype(np.float32)

    def apply(self, prim, k=0.0, op="union", pad=None):
        """Combine one primitive into the field. k = blend radius (smooth union / subtraction)."""
        lo, hi = prim.aabb()
        p = (k + 2.0 * self.h) if pad is None else pad
        i0 = np.clip(np.floor((lo - p - self.lo) / self.h).astype(int), 0, self.n - 1)
        i1 = np.clip(np.ceil((hi + p - self.lo) / self.h).astype(int) + 1, 1, self.n)
        if np.any(i1 <= i0):
            return
        X = self.axis(0, i0[0], i1[0])[:, None, None]
        Y = self.axis(1, i0[1], i1[1])[None, :, None]
        Z = self.axis(2, i0[2], i1[2])[None, None, :]
        dp = prim.sdf(X, Y, Z).astype(np.float32)
        sl = (slice(i0[0], i1[0]), slice(i0[1], i1[1]), slice(i0[2], i1[2]))
        cur = self.d[sl]
        if op == "union":
            self.d[sl] = smin(cur, dp, k)
        elif op == "sub":
            self.d[sl] = smax(cur, -dp, k)
        elif op == "intersect":
            self.d[sl] = smax(cur, dp, k)
        else:
            raise ValueError(op)

    def sample(self, P):
        """Trilinear sample of the field at points P (N, 3)."""
        g = (np.asarray(P, float) - self.lo) / self.h
        i = np.clip(np.floor(g).astype(int), 0, self.n - 2)
        f = np.clip(g - i, 0.0, 1.0)
        d = self.d
        x0, y0, z0 = i[:, 0], i[:, 1], i[:, 2]
        fx, fy, fz = f[:, 0], f[:, 1], f[:, 2]
        c000 = d[x0, y0, z0]; c100 = d[x0 + 1, y0, z0]; c010 = d[x0, y0 + 1, z0]; c110 = d[x0 + 1, y0 + 1, z0]
        c001 = d[x0, y0, z0 + 1]; c101 = d[x0 + 1, y0, z0 + 1]; c011 = d[x0, y0 + 1, z0 + 1]; c111 = d[x0 + 1, y0 + 1, z0 + 1]
        c00 = c000 * (1 - fx) + c100 * fx
        c10 = c010 * (1 - fx) + c110 * fx
        c01 = c001 * (1 - fx) + c101 * fx
        c11 = c011 * (1 - fx) + c111 * fx
        c0 = c00 * (1 - fy) + c10 * fy
        c1 = c01 * (1 - fy) + c11 * fy
        return c0 * (1 - fz) + c1 * fz

    def gradient(self, P):
        e = self.h
        P = np.asarray(P, float)
        g = np.empty_like(P)
        for a in range(3):
            o = np.zeros(3)
            o[a] = e
            g[:, a] = (self.sample(P + o) - self.sample(P - o)) / (2 * e)
        return g


def smin(a, b, k):
    if k <= 0:
        return np.minimum(a, b)
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return b * (1 - h) + a * h - k * h * (1 - h)


def smax(a, b, k):
    if k <= 0:
        return np.maximum(a, b)
    h = np.clip(0.5 - 0.5 * (b - a) / k, 0.0, 1.0)
    return b * (1 - h) + a * h + k * h * (1 - h)


# ------------------------------------------------------------------------------------------------ meshing

def surface_nets(grid, project_steps=2):
    """Quad mesh of the zero level set. Returns (verts (N,3) float64, quads (M,4) int64), outward-facing."""
    d = grid.d
    n = d.shape
    cshape = (n[0] - 1, n[1] - 1, n[2] - 1)
    inside = d < 0.0
    # 1) every sign-changing grid edge gives a crossing point, shared by the (up to) 4 cells around the edge
    cells, pts = [], []
    for axis in range(3):
        a0 = [slice(None)] * 3
        a1 = [slice(None)] * 3
        a0[axis] = slice(0, -1)
        a1[axis] = slice(1, None)
        d0 = d[tuple(a0)]
        d1 = d[tuple(a1)]
        idx = np.nonzero(inside[tuple(a0)] != inside[tuple(a1)])
        v0 = d0[idx].astype(np.float64)
        v1 = d1[idx].astype(np.float64)
        p = np.stack(idx, axis=1).astype(np.float64)
        p[:, axis] += v0 / (v0 - v1)
        others = [o for o in range(3) if o != axis]
        for o1 in (0, 1):
            for o2 in (0, 1):
                c = [idx[0].copy(), idx[1].copy(), idx[2].copy()]
                c[others[0]] -= o1
                c[others[1]] -= o2
                ok = np.ones(len(c[0]), bool)
                for a in range(3):
                    ok &= (c[a] >= 0) & (c[a] < cshape[a])
                cells.append(np.ravel_multi_index((c[0][ok], c[1][ok], c[2][ok]), cshape))
                pts.append(p[ok])
    cells = np.concatenate(cells)
    pts = np.concatenate(pts)
    uniq, inv = np.unique(cells, return_inverse=True)
    cnt = np.bincount(inv)
    verts = np.stack([np.bincount(inv, weights=pts[:, a]) / cnt for a in range(3)], axis=1)
    verts = grid.lo + verts * grid.h
    del cells, pts, inv
    # 2) one quad per sign-changing interior edge, through the 4 cells around it (outward winding)
    quads = []
    for axis in range(3):
        a0 = [slice(None)] * 3
        a1 = [slice(None)] * 3
        a0[axis] = slice(0, -1)
        a1[axis] = slice(1, None)
        s0 = inside[tuple(a0)]
        idx = np.nonzero(s0 != inside[tuple(a1)])
        others = [o for o in range(3) if o != axis]
        ok = np.ones(len(idx[0]), bool)
        for o in others:
            ok &= (idx[o] >= 1) & (idx[o] <= cshape[o] - 1)
        idx = tuple(i[ok] for i in idx)
        s_in = s0[idx]
        corners = []
        for o1, o2 in ((0, 0), (1, 0), (1, 1), (0, 1)):
            c = [idx[0].copy(), idx[1].copy(), idx[2].copy()]
            c[others[0]] -= 1 - o1
            c[others[1]] -= 1 - o2
            flat = np.ravel_multi_index((c[0], c[1], c[2]), cshape)
            pos = np.searchsorted(uniq, flat)
            pos = np.clip(pos, 0, len(uniq) - 1)
            corners.append(np.where(uniq[pos] == flat, pos, -1))
        q = np.stack(corners, axis=1)
        # the cyclic order above has normal +x for x-edges, -y for y-edges, +z for z-edges
        flip = s_in if axis == 1 else ~s_in
        q[flip] = q[flip][:, ::-1]
        quads.append(q)
    quads = np.concatenate(quads, axis=0)
    quads = quads[(quads >= 0).all(axis=1)]
    # 3) pull the vertices onto the zero level set
    for _ in range(project_steps):
        dist = grid.sample(verts)
        g = grid.gradient(verts)
        gl2 = np.maximum((g * g).sum(axis=1), 1e-6)
        step = (dist / gl2)[:, None] * g
        sl = np.linalg.norm(step, axis=1)
        step *= np.minimum(1.0, grid.h / np.maximum(sl, 1e-9))[:, None]
        verts = verts - step
    return verts, quads


def mesh_volume(verts, quads):
    """Signed volume (positive when faces point outward)."""
    v = verts
    tri = np.concatenate([quads[:, [0, 1, 2]], quads[:, [0, 2, 3]]])
    a, b, c = v[tri[:, 0]], v[tri[:, 1]], v[tri[:, 2]]
    return float(np.einsum("ij,ij->i", a, np.cross(b, c)).sum() / 6.0)


def save_npz(path, verts, faces, **extra):
    np.savez_compressed(path, verts=verts.astype(np.float32), faces=faces.astype(np.int32), **extra)
