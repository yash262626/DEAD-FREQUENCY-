"""The Listener's body as anatomy: bones, cartilage, stringy muscle and tendon under tight skin.

Centimetres, Z up, the creature faces -Y, its left side is +X. Rest pose is an A-pose (arms 47 degrees below
horizontal) for rigging; the hunched stance comes from animation. The skeleton is human-derived but elongated:
long shins and forearms, an extra finger phalanx, a long cervical spine ending in the membrane's root.

build(h) evaluates everything on a grid of cell size h and returns the grid; JOINTS gives the rig landmarks.
"""
import numpy as np

import sdf
from sdf import Ellipsoid, RoundCone, Torus, frame, rot_xyz

V = lambda *a: np.array(a, float)
unit = lambda v: np.asarray(v, float) / np.linalg.norm(v)

OPS = []          # (primitive, blend radius, op, layer)
LAYER = ["P"]     # current layer: P primary mass, B bone landmark, M muscle detail, C cord/tendon
# how far each secondary layer may push the skin out beyond the primary masses (cm), and how it blends in
LAYERS = {"B": (1.0, 0.6), "M": (0.6, 1.4), "C": (0.4, 0.5)}
JOINTS = {}       # name -> position (rest pose), for the rig
CLAWS = []        # (base, direction, length, radius, curl axis) for the claw meshes


def add(prim, k=1.2, op="union", layer=None):
    OPS.append((prim, k, op, layer or LAYER[0]))
    return prim


class layer:
    """with layer("B"): ... tags every primitive added inside."""

    def __init__(self, name):
        self.name = name

    def __enter__(self):
        self.prev = LAYER[0]
        LAYER[0] = self.name

    def __exit__(self, *a):
        LAYER[0] = self.prev


def rc(a, b, r1, r2=None, k=1.2, op="union"):
    return add(RoundCone(a, b, r1, r2), k, op)


def ell(c, r, R=None, k=1.2, op="union"):
    return add(Ellipsoid(c, r, R), k, op)


def chain(points, radii, k=1.0):
    for i in range(len(points) - 1):
        rc(points[i], points[i + 1], radii[i], radii[i + 1], k)


def lerp(a, b, t):
    return np.asarray(a, float) * (1 - t) + np.asarray(b, float) * t


def bezier(p0, p1, p2, n):
    t = np.linspace(0.0, 1.0, n)[:, None]
    return (1 - t) ** 2 * p0 + 2 * (1 - t) * t * p1 + t * t * p2


def rotate_about(v, axis, deg):
    axis = unit(axis)
    a = np.radians(deg)
    v = np.asarray(v, float)
    return v * np.cos(a) + np.cross(axis, v) * np.sin(a) + axis * np.dot(axis, v) * (1 - np.cos(a))


# ------------------------------------------------------------------------------------------------ spine

SPINE = {
    "S1": V(0, 7.6, 124.0),
    "L5": V(0, 5.6, 127.6), "L4": V(0, 4.1, 131.6), "L3": V(0, 3.3, 135.6), "L2": V(0, 3.5, 139.6), "L1": V(0, 4.3, 143.6),
    "T12": V(0, 5.5, 147.4), "T11": V(0, 6.7, 151.0), "T10": V(0, 7.8, 154.5), "T9": V(0, 8.7, 157.9),
    "T8": V(0, 9.4, 161.2), "T7": V(0, 9.9, 164.5), "T6": V(0, 10.2, 167.7), "T5": V(0, 10.3, 170.8),
    "T4": V(0, 10.1, 173.8), "T3": V(0, 9.6, 176.7), "T2": V(0, 8.9, 179.5), "T1": V(0, 8.0, 182.2),
    "C7": V(0, 6.9, 184.9), "C6": V(0, 5.7, 187.7), "C5": V(0, 4.5, 190.5), "C4": V(0, 3.4, 193.3),
    "C3": V(0, 2.4, 196.1), "C2": V(0, 1.6, 198.9), "C1": V(0, 1.0, 201.5),
}
HEAD_BASE = V(0, 0.4, 204.8)
ORDER = ["S1", "L5", "L4", "L3", "L2", "L1"] + ["T%d" % i for i in range(12, 0, -1)] + ["C%d" % i for i in range(7, 0, -1)]
NECK = {}


def spine():
    with layer("B"):
        for name in ORDER[1:]:
            c = SPINE[name]
            if name.startswith("L"):
                sp, r = V(0, 3.3, -0.5), (0.8, 0.6)
            elif name.startswith("T"):
                sp, r = V(0, 3.7, -1.6), (0.6, 0.45)
            else:
                sp, r = V(0, 2.6, -0.7), (0.5, 0.4)
            if name == "C7":
                sp, r = V(0, 3.7, -0.9), (0.66, 0.52)                  # vertebra prominens
            rc(c + V(0, 1.0, 0), c + sp, r[0], r[1], k=0.5)           # spinous process: the bumps down the back
        ell(V(0, 8.4, 120.2), V(4.0, 1.5, 5.6), rot_xyz(-22, 0, 0), k=1.2)   # sacrum
        rc(V(0, 9.4, 116.0), V(0, 8.8, 113.0), 0.8, 0.45, k=0.8)            # coccyx
    # erector spinae: twin ridges with the spinous bumps in the groove between them
    for s in (-1, 1):
        pts, rad = [], []
        for name in ORDER[:-4]:
            c = SPINE[name]
            t = (c[2] - 124.0) / 66.0
            pts.append(c + V(s * (3.5 - 0.4 * t), 2.6 + 0.4 * t, 0))
            rad.append(2.6 * (1 - t) + 1.25 * t)
        chain(pts, rad, k=1.6)
    # neck: masses along the cervical axis; "fwd" is the throat side
    ax = unit(HEAD_BASE - SPINE["C7"])
    fwd = unit(np.cross(ax, V(1, 0, 0)))
    if fwd[1] > 0:
        fwd = -fwd
    NECK.update(ax=ax, fwd=fwd)

    def nk(name, f, side=0.0):
        return SPINE[name] + f * fwd + V(side, 0, 0)
    rc(nk("C7", -2.0) + V(0, 0, -1.5), HEAD_BASE - 1.6 * fwd, 4.1, 3.0, k=2.4)        # posterior neck
    rc(nk("C7", 1.6) + V(0, 0, -2.0), HEAD_BASE + 0.8 * fwd, 3.5, 2.8, k=2.4)         # anterior neck
    ell(HEAD_BASE + 0.9 * fwd + V(0, 0, 0.6), V(5.6, 5.6, 4.8), frame(ax, -fwd), k=2.4)   # membrane root
    ell(HEAD_BASE + 1.6 * fwd + V(0, 0, 3.0), V(4.6, 4.6, 3.6), frame(unit(V(0.1, -0.8, 0.56)), -fwd), k=2.2)  # collar
    with layer("M"):
        rc(nk("C7", 4.0) + V(0, 0, -5.0), nk("C2", 3.6), 1.25, 1.05, k=0.9)         # trachea
        for s in (-1, 1):
            mast = HEAD_BASE + V(s * 3.9, 2.0, -1.6)
            rc(V(s * 1.8, -0.2, 179.6), mast, 0.72, 0.8, k=1.6)                      # sternocleidomastoid
            rc(V(s * 4.8, 0.6, 180.2), mast + V(0, 0.2, -0.4), 0.6, 0.65, k=1.6)
    with layer("B"):
        ell(nk("C4", 4.6) + V(0, 0, -1.2), V(1.45, 1.1, 1.95), frame(ax, -fwd), k=0.8)  # larynx
    JOINTS.update({
        "pelvis": V(0, 2.6, 119.5),
        "spine_01": SPINE["L4"], "spine_02": SPINE["L1"], "spine_03": SPINE["T10"],
        "spine_04": SPINE["T6"], "spine_05": SPINE["T2"],
        "neck_01": SPINE["C7"], "neck_02": SPINE["C4"], "head": HEAD_BASE,
    })


# ------------------------------------------------------------------------------------------------ ribcage

RIB_A = [5.6, 8.6, 10.9, 12.4, 13.5, 14.1, 14.5, 14.6, 14.4, 13.7, 12.3, 10.3]
RIB_B = [5.0, 7.0, 8.4, 9.3, 9.9, 10.3, 10.5, 10.5, 10.2, 9.7, 8.7, 7.4]
RIB_DROP = [3.5, 6.0, 8.0, 9.3, 10.0, 10.5, 10.8, 10.4, 9.6, 8.6, 6.0, 4.5]
RIB_END = [2.80, 2.78, 2.76, 2.74, 2.72, 2.70, 2.66, 2.40, 2.20, 2.02, 1.70, 1.45]
STERNUM = {}


def rib_curve(i, s, n=26, phi0=0.38):
    """Rib i (1-12) on side s: from the vertebra round the side to its front end."""
    v = SPINE["T%d" % i]
    A, B = RIB_A[i - 1] * (1.0 + 0.012 * s), RIB_B[i - 1]          # slightly uneven ribcage
    yc = v[1] + 3.0 - np.cos(phi0) * B
    phi = np.linspace(phi0, RIB_END[i - 1], n)
    t = (phi - phi0) / (RIB_END[i - 1] - phi0)
    x = s * A * np.sin(phi)
    y = yc + B * np.cos(phi)
    z = v[2] - 0.9 - RIB_DROP[i - 1] * t ** 1.25
    return np.stack([x, y, z], axis=1)


def ribcage():
    fronts = {}
    with layer("B"):
        for s in (-1, 1):
            for i in range(1, 13):
                pts = rib_curve(i, s)
                v = SPINE["T%d" % i]
                r0 = 0.5 if i in (1, 12) else 0.62 if i in (2, 11) else 0.72
                rc(v + V(s * 1.2, 1.2, 0), pts[0], 0.5, r0, k=0.6)        # rib head and neck
                chain(pts, np.linspace(r0, r0 * 0.85, len(pts)), k=0.7)
                fronts[(i, s)] = pts[-1]
        top = 0.5 * (fronts[(1, 1)] + fronts[(1, -1)])
        low = 0.5 * (fronts[(7, 1)] + fronts[(7, -1)])
        top = V(0, top[1] - 1.6, top[2] + 0.4)
        low = V(0, low[1] - 1.2, low[2] - 1.0)
        STERNUM.update(top=top, low=low)
        n = unit(low - top)
        ell(lerp(top, low, 0.12), V(2.3, 0.85, 2.2), frame(n, V(0, -1, 0)), k=0.9)      # manubrium
        ell(lerp(top, low, 0.58), V(1.55, 0.75, 7.0), frame(n, V(0, -1, 0)), k=0.9)     # sternal body
        rc(low, low + V(0, -0.2, -3.0), 0.7, 0.35, k=0.6)                              # xiphoid
        for s in (-1, 1):
            for i in range(1, 8):                     # costal cartilage of the true ribs
                t = (i - 1) / 6.0
                rc(fronts[(i, s)], lerp(top, low, 0.05 + 0.92 * t) + V(s * 1.5, 0.3, 0), 0.62, 0.5, k=0.6)
            for i in range(8, 11):                    # false ribs climb to the cartilage above: the costal arch
                f, up = fronts[(i, s)], fronts[(i - 1, s)]
                mid = lerp(f, up, 0.55) + V(-s * 1.2, -0.6, 0.6)
                chain([f, mid, lerp(up, lerp(top, low, 0.97), 0.35)], [0.6, 0.55, 0.5], k=0.6)
    # the barrel the ribs are stretched over: a soft ring just inside every rib (skin dips a little between
    # ribs but never into the chest), then a core that closes the inside
    for s in (-1, 1):
        for i in range(1, 13):
            pts = rib_curve(i, s, n=14)
            v = SPINE["T%d" % i]
            cy = v[1] + 3.0 - np.cos(0.38) * RIB_B[i - 1]
            inner = []
            for q in pts:
                rad = q - V(0, cy, q[2])
                inner.append(q - rad * (2.2 / max(np.linalg.norm(rad[:2]), 1e-3)))
            chain(inner, [2.45] * len(inner), k=2.4)
    for i in range(1, 12):
        v = SPINE["T%d" % i]
        A, B = RIB_A[i - 1], RIB_B[i - 1]
        ell(V(0, v[1] + 3.0 - np.cos(0.38) * B - 0.6, v[2] - 0.9 - RIB_DROP[i - 1] * 0.45),
            V(max(A - 3.0, 2.0), max(B - 2.6, 2.0), 3.4), k=2.0)
    JOINTS.update(sternum_top=STERNUM["top"], sternum_low=STERNUM["low"])


# ------------------------------------------------------------------------------------------------ shoulders and arms

def arm(s):
    side = "rl"[s > 0]
    sc = V(s * 2.2, STERNUM["top"][1] + 0.6, STERNUM["top"][2] + 0.4)
    acrom = V(s * 17.6, 2.2, 177.6 - (0.9 if s < 0 else 0.0))           # the right shoulder sits lower
    shoulder = acrom + V(s * 1.4, 0.2, -2.9)
    d_up = unit(V(s * np.sin(np.radians(43)), -np.sin(np.radians(8)), -np.cos(np.radians(43))))
    elbow = shoulder + 41.0 * d_up
    d_fore = unit(d_up + V(0, -0.2, 0.06))
    wrist = elbow + 39.0 * d_fore
    # arm frame: fwd = thumb side (front), med = toward the body (palm side in the A-pose), back = elbow point
    fwd = unit(V(0, -1, 0) - np.dot(V(0, -1, 0), d_up) * d_up)
    med = unit(np.cross(d_up, fwd))
    if np.dot(med, V(-s, 0, -1)) < 0:
        med = -med
    back = -fwd
    # shoulder girdle masses: trapezius slope, upper chest, the cap of the shoulder, the armpit folds
    neck_base = V(s * 2.4, 5.4, 186.0)
    tr = 0.5 * (neck_base + acrom)
    ell(tr + V(0, 0.8, -0.6), V(2.9, 3.6, np.linalg.norm(acrom - neck_base) * 0.56),
        frame(acrom - neck_base, V(0, 1, 0.4)), k=2.6)                                  # trapezius, upper
    rc(SPINE["T5"] + V(s * 1.5, 2.4, 0), acrom + V(-s * 4.0, 2.6, -0.6), 2.2, 1.4, k=2.4)   # middle trapezius
    ell(V(s * 8.2, -2.0, 171.6), V(8.0, 1.8, 4.6), rot_xyz(0, -s * 17, 0), k=3.0)        # pectoral
    ell(shoulder + 3.2 * d_up + V(s * 0.4, 0, 1.2), V(4.5, 4.9, 7.4), frame(d_up, V(0, 0, 1)), k=3.0)   # deltoid
    ell(acrom + V(s * 0.6, -0.2, -1.4), V(4.0, 4.6, 3.4), k=3.0)                         # shoulder cap
    rc(V(s * 12.4, -4.4, 171.0), shoulder + 7.5 * d_up + 1.4 * fwd, 2.3, 1.7, k=2.8)    # front armpit fold
    rc(V(s * 12.0, 7.0, 163.5), shoulder + 8.0 * d_up + 1.6 * back, 2.6, 1.7, k=2.0)    # back armpit fold
    rc(V(s * 8.0, 9.4, 141.0), V(s * 15.4, 4.6, 164.0), 2.2, 1.9, k=2.4)                 # latissimus
    ell(V(s * 10.4, 10.4, 166.0), V(4.6, 1.9, 6.6), rot_xyz(0, 0, -s * 26), k=2.2)       # infraspinatus
    # upper arm and forearm masses (wiry)
    ell(shoulder, V(2.2, 2.2, 2.2), k=1.6)
    rc(shoulder, elbow, 1.5, 1.3, k=1.4)                                              # humerus
    rc(shoulder + 8.0 * d_up + 1.5 * fwd, elbow - 2.0 * d_up + 1.0 * fwd, 3.0, 1.7, k=2.4)       # biceps
    rc(shoulder + 7.0 * d_up + 1.7 * back, elbow - 2.5 * d_up + 1.5 * back, 3.4, 1.9, k=2.4)     # triceps
    ell(elbow + 0.2 * back, V(3.0, 3.2, 4.2), frame(d_up, fwd), k=2.4)                         # the elbow as one mass
    olec = elbow + 1.35 * back
    w_ulna = wrist + 1.0 * back
    w_rad = wrist + 1.1 * fwd
    rc(elbow - 0.9 * med + 0.4 * fwd, w_rad, 0.85, 1.15, k=1.0)                         # radius
    rc(elbow - 3.0 * d_up + 1.2 * med, elbow + 23.0 * d_fore + 1.0 * med, 2.6, 1.0, k=2.4)          # flexors
    rc(elbow - 3.5 * d_up - 1.1 * med, elbow + 22.0 * d_fore - 0.9 * med, 2.5, 1.0, k=2.4)          # extensors
    rc(elbow - 4.0 * d_up - 1.0 * med + 1.1 * fwd, elbow + 17.0 * d_fore - 0.6 * med + 0.9 * fwd, 2.2, 0.8, k=2.0)  # brachioradialis
    rc(elbow + 20.0 * d_fore, wrist, 1.6, 1.25, k=1.4)                                  # wrist mass
    with layer("B"):
        rc(V(s * 2.2, STERNUM["top"][1] + 0.6, STERNUM["top"][2] + 0.4), V(s * 6.5, sc[1] - 0.5, 180.6), 0.85, 0.8, k=0.7)
        chain([V(s * 6.5, sc[1] - 0.5, 180.6), V(s * 11.5, -2.8, 179.6), acrom], [0.8, 0.72, 0.65], k=0.7)   # clavicle
        R = rot_xyz(4, 0, -s * 26) @ frame(V(0, 1, 0), V(0, 0, 1))
        ell(V(s * 9.6, 12.4, 167.5), V(5.0, 7.6, 0.8), R, k=1.0)                       # scapula, winged
        rc(V(s * 5.2, 13.4, 173.4), acrom + V(0, 1.2, 0.2), 0.62, 0.95, k=0.7)         # spine of the scapula
        ell(acrom + V(s * 0.3, 0.2, 0.3), V(2.4, 2.0, 0.8), rot_xyz(0, -s * 10, 0), k=0.8)   # acromion
        ell(elbow + 1.25 * med, V(1.15, 1.15, 1.15), k=0.6)                            # medial epicondyle
        ell(elbow - 1.05 * med, V(0.95, 0.95, 0.95), k=0.6)                            # lateral epicondyle
        ell(olec, V(1.0, 1.0, 1.2), frame(d_fore), k=0.6)                               # olecranon
        rc(olec, w_ulna, 1.0, 0.75, k=0.8)                                              # ulna
        ell(w_ulna + 0.5 * back, V(0.7, 0.7, 0.7), k=0.45)                             # ulnar styloid
    with layer("M"):
        ell(V(s * 10.7, 9.0, 158.5), V(2.5, 1.5, 3.5), rot_xyz(0, s * 35, s * 20), k=1.4)   # teres
    with layer("C"):
        for off in (-1.3, -0.4, 0.5, 1.3):                                             # wrist tendons, both faces
            rc(elbow + 21.0 * d_fore + off * fwd + 1.25 * med, wrist + off * 0.7 * fwd + 1.05 * med, 0.36, 0.3, k=0.4)
            rc(elbow + 22.5 * d_fore + off * fwd - 1.2 * med, wrist + off * 0.7 * fwd - 1.0 * med, 0.32, 0.28, k=0.4)
    hand(s, wrist, d_fore, fwd, med)
    JOINTS.update({"clavicle_" + side: sc, "upperarm_" + side: shoulder, "lowerarm_" + side: elbow, "hand_" + side: wrist})


FINGERS = {               # lengths of the four phalanges, spread (deg), knuckle offset along the thumb axis
    "index": ([5.4, 4.0, 3.0, 2.3], 9.0, 2.5),
    "middle": ([6.1, 4.6, 3.4, 2.5], 2.0, 0.85),
    "ring": ([5.7, 4.3, 3.2, 2.4], -5.0, -0.8),
    "pinky": ([4.7, 3.5, 2.6, 2.0], -12.0, -2.35),
}


def hand(s, wrist, a, fwd, med):
    """a: along the hand; t: toward the thumb (front); n: palm normal, out of the palm (toward the body)."""
    t = unit(fwd - np.dot(fwd, a) * a)
    n = unit(med - np.dot(med, a) * a - np.dot(med, t) * t)
    d = -n                                       # dorsal
    side = "rl"[s > 0]
    ell(wrist + 1.6 * a, V(2.5, 1.2, 1.8), np.stack([t, d, a], axis=1), k=0.8)          # carpus
    ell(wrist + 6.3 * a + 0.6 * n, V(3.0, 1.1, 4.5), np.stack([t, n, a], axis=1), k=1.0)  # palm
    ell(wrist + 4.5 * a + 2.1 * t + 0.6 * n, V(1.3, 1.0, 2.7), frame(unit(a + 0.5 * t), n), k=0.9)  # thenar
    for name, (lens, spread, off) in FINGERS.items():
        base = wrist + 2.6 * a + off * 0.55 * t
        kn = wrist + 11.0 * a + off * t + (0.25 if name in ("middle", "ring") else 0.0) * d
        rc(base, kn, 0.66, 0.7, k=0.6)                                  # metacarpal
        JOINTS["metacarpal_%s_%s" % (name, side)] = base
        with layer("B"):
            ell(kn, V(1.0, 1.0, 1.0), k=0.4)                             # knuckle
        with layer("C"):
            rc(wrist + 1.4 * a + 0.9 * d + off * 0.3 * t, kn + 0.8 * d, 0.32, 0.28, k=0.35)   # extensor tendon
        sgn = 1.0 if np.dot(np.cross(n, a), t) > 0 else -1.0             # positive spread fans toward the thumb
        fd = unit(rotate_about(a, n, sgn * spread))
        p, r = kn, 0.8
        lat = unit(np.cross(fd, n))
        for j, L in enumerate(lens):
            fd = unit(rotate_about(fd, lat, 10.0 + 3.0 * j))            # natural curl toward the palm
            q = p + L * fd
            r2 = 0.8 - 0.085 * (j + 1)
            rc(p, q, r, r2, k=0.4)
            if j < 3:
                with layer("B"):
                    ell(q, V(r2 + 0.14, r2 + 0.14, r2 + 0.1), k=0.32)    # joint knuckle
            JOINTS["%s_%02d_%s" % (name, j + 1, side)] = p
            p, r = q, r2
        JOINTS["%s_tip_%s" % (name, side)] = p
        CLAWS.append((p, fd, 3.6, 0.42, lat))
    tb = wrist + 2.2 * a + 1.9 * t + 0.4 * n                            # thumb
    td = unit(0.62 * a + 0.72 * t + 0.32 * n)
    p, r = tb, 0.88
    lat = unit(np.cross(td, n))
    for j, L in enumerate([4.4, 3.6, 2.8]):
        td = unit(rotate_about(td, lat, 8.0))
        q = p + L * td
        r2 = 0.88 - 0.1 * (j + 1)
        rc(p, q, r, r2, k=0.45)
        if j < 2:
            with layer("B"):
                ell(q, V(r2 + 0.12, r2 + 0.12, r2 + 0.1), k=0.32)
        JOINTS["thumb_%02d_%s" % (j + 1, side)] = p
        p, r = q, r2
    JOINTS["thumb_tip_" + side] = p
    CLAWS.append((p, td, 3.0, 0.42, lat))
    JOINTS["hand_axes_" + side] = np.stack([a, t, n])


# ------------------------------------------------------------------------------------------------ pelvis and legs

def pelvis():
    ell(V(0, 1.6, 135.0), V(11.0, 6.9, 10.8), k=3.2)                # sunken abdomen
    ell(V(0, -1.4, 147.5), V(10.6, 5.6, 6.0), k=3.6)                # under the costal margin: no shelf
    ell(V(0, -3.4, 128.0), V(7.0, 2.6, 7.5), k=3.0)                  # lower belly wall
    ell(V(0, 1.4, 118.0), V(11.0, 7.2, 8.4), k=3.0)                 # lower pelvis
    for s in (-1, 1):
        rc(V(s * 9.4, 2.6, 146.0), V(s * 10.6, 3.0, 127.0), 3.4, 3.8, k=3.0)    # flanks: obliques and quadratus
        ell(V(s * 8.6, -2.2, 126.5), V(4.4, 3.4, 6.4), k=3.2)                    # lower flank around the hip bone
        ell(V(s * 11.2, 1.8, 113.0), V(5.0, 6.0, 8.6), k=3.2)                   # gluteus medius / hip
        ell(V(s * 7.8, 7.4, 114.5), V(6.5, 4.2, 8.0), rot_xyz(0, 0, s * 8), k=2.6)     # gluteal, wasted
        with layer("B"):
            asis, top, psis = V(s * 10.6, -4.6, 124.6), V(s * 13.1, 1.6, 130.4), V(s * 4.6, 9.2, 127.2)
            chain([asis, top + V(0, -1.6, 0.2), top, psis], [0.55, 0.55, 0.55, 0.5], k=1.4)   # iliac crest
        with layer("M"):
            for j, z in enumerate((166.0, 162.5, 159.0, 155.5)):                     # serratus slips
                ell(V(s * (13.4 - 0.25 * j), -2.0 - 0.3 * j, z), V(1.1, 0.8, 1.9), rot_xyz(0, s * 30, 0), k=1.0)


def leg(s):
    side = "rl"[s > 0]
    hip = V(s * 10.0, 0.6, 116.0)
    knee = V(s * 11.0, -1.0, 62.0)
    ankle = V(s * 11.4, 3.4, 9.6)
    if s < 0:
        knee = knee + V(0.3, 0, 0)
    ell(hip, V(2.4, 2.4, 2.4), k=1.2)
    rc(hip, knee, 1.6, 1.4, k=1.4)                                                  # femur
    rc(V(s * 11.4, -2.4, 108.0), V(s * 11.2, -3.2, 66.0), 6.2, 3.4, k=2.8)          # quadriceps
    rc(V(s * 10.8, 3.4, 108.0), V(s * 11.0, 2.0, 67.0), 5.4, 2.7, k=2.8)            # hamstrings
    rc(V(s * 7.0, 0.5, 110.0), V(s * 9.6, -0.4, 72.0), 4.8, 2.0, k=2.8)             # adductors
    ell(knee + V(0, -0.6, 1.5), V(4.3, 4.1, 6.0), k=2.6)                            # the knee as one mass
    rc(knee + V(0, -0.6, -2.0), ankle + V(0, -0.8, 2.0), 2.0, 1.25, k=1.6)          # tibia
    rc(knee + V(s * 1.6, -0.6, -4.0), ankle + V(s * 1.0, -0.8, 10.0), 2.9, 1.25, k=2.4)  # tibialis / peroneal mass
    ell(V(s * 9.9, 3.4, 49.5), V(3.7, 4.3, 11.0), k=2.6)                           # gastrocnemius heads
    ell(V(s * 12.5, 3.6, 50.5), V(3.4, 4.0, 10.4), k=2.6)
    rc(V(s * 11.0, 3.4, 47.0), V(s * 11.5, 5.0, 22.0), 3.8, 1.5, k=2.4)             # soleus
    rc(V(s * 11.4, 5.6, 27.0), V(s * 11.6, 6.9, 6.0), 1.05, 0.85, k=1.0)            # achilles
    for x in (9.0, 13.0):
        ell(knee + V(s * (x - 11.0), 0.4, 0.4), V(2.3, 2.3, 2.3), k=1.2)            # condyles (mass)
    with layer("B"):
        troch = V(s * 14.0, 1.0, 113.6)
        rc(hip, troch, 1.4, 1.5, k=0.9)
        ell(troch, V(2.0, 2.2, 2.4), k=1.0)                                           # greater trochanter
        ell(knee + V(0, -3.3, 1.4), V(2.2, 0.9, 2.6), k=0.8)                          # patella
        ell(knee + V(0, -2.1, -7.2), V(1.0, 0.8, 1.3), k=0.8)                         # tibial tuberosity
        rc(knee + V(0, -2.4, -7.0), ankle + V(0, -1.9, 9.0), 0.6, 0.5, k=0.6)         # shin crest
        rc(knee + V(s * 2.6, 1.0, -3.0), ankle + V(s * 2.4, 0.8, 1.0), 0.62, 0.55, k=0.8)   # fibula
        ell(ankle + V(-s * 1.9, -0.3, 0.0), V(1.25, 1.25, 1.35), k=0.7)             # malleoli
        ell(ankle + V(s * 2.2, 0.6, -1.0), V(1.15, 1.15, 1.3), k=0.7)
    with layer("M"):
        ell(V(s * 8.6, -3.0, 71.0), V(2.2, 2.2, 3.8), k=1.4)                          # vastus medialis
        chain([V(s * 10.4, -4.4, 121.0), V(s * 8.4, -4.8, 100.0), V(s * 8.8, -1.6, 66.0)], [0.8, 0.75, 0.65], k=2.0)   # sartorius
        rc(V(s * 15.2, 0.2, 110.0), V(s * 14.2, -0.4, 66.0), 0.85, 0.8, k=2.2)        # iliotibial band
    with layer("C"):
        for x in (9.0, 13.0):                                                       # hamstring tendons
            rc(V(s * x, 4.0, 72.0), V(s * (x + 0.4 * (1 if x < 11 else -1)), 2.2, 58.5), 0.62, 0.52, k=0.6)
        rc(knee + V(0, -3.1, -1.0), knee + V(0, -2.2, -6.6), 0.8, 0.7, k=0.5)          # patellar tendon
    foot(s, ankle)
    JOINTS.update({"thigh_" + side: hip, "calf_" + side: knee, "foot_" + side: ankle})


TOES = [9.2, 11.2, 13.0, 14.6]


def foot(s, ankle):
    side = "rl"[s > 0]
    heel = V(s * 11.6, 6.2, 2.6)
    ell(heel, V(2.3, 3.4, 2.5), k=1.0)                                # calcaneus
    ell(V(s * 11.6, 1.2, 5.4), V(2.8, 3.3, 2.3), k=1.2)               # tarsus
    ell(V(s * 11.9, -4.2, 1.5), V(3.8, 9.0, 1.05), k=1.3)             # sole pad
    balls = []
    for j, x in enumerate(TOES):
        b = V(s * x, -14.2 + 0.6 * abs(j - 1), 2.0)
        rc(V(s * (11.6 + (x - 11.9) * 0.45), -1.8, 4.9), b, 0.9, 0.78, k=0.7)   # metatarsal
        ell(b, V(1.0, 1.0, 0.95), k=0.55)
        with layer("C"):
            rc(ankle + V(s * (x - 11.6) * 0.3, -2.6, -1.4), b + V(0, 0, 0.8), 0.32, 0.28, k=0.35)   # extensor tendons
        p, d, r = b, unit(V(s * (j - 1.5) * 0.06, -1.0, 0.05)), 0.76
        for k_, L in enumerate([3.4, 2.5, 1.9]):
            d = unit(rotate_about(d, V(1, 0, 0), 4.0 + 8.0 * k_))
            q = p + L * d
            r2 = r - 0.09
            rc(p, q, r, r2, k=0.4)
            if k_ < 2:
                with layer("B"):
                    ell(q, V(r2 + 0.1, r2 + 0.1, r2 + 0.1), k=0.3)
            p, r = q, r2
        CLAWS.append((p, d, 2.4, 0.4, V(1, 0, 0)))
        balls.append(b)
    JOINTS["ball_" + side] = sum(balls) / len(balls)
    JOINTS["toe_tip_" + side] = p


# ------------------------------------------------------------------------------------------------ build

BOUNDS = (V(-100.0, -32.0, -2.0), V(100.0, 22.0, 212.0))


def build(h=0.25, log=print):
    OPS.clear()
    JOINTS.clear()
    CLAWS.clear()
    spine()
    ribcage()
    pelvis()
    for s in (1, -1):
        arm(s)
        leg(s)
    grids = {}
    for name in ("P", "B", "M", "C"):
        grids[name] = sdf.Grid(BOUNDS[0], BOUNDS[1], h)
    g = grids["P"]
    log("grid %s = %.1fM cells, %d primitives (%s)" % (tuple(g.n), np.prod(g.n) / 1e6, len(OPS),
        ", ".join("%s %d" % (n, sum(1 for o in OPS if o[3] == n)) for n in grids)))
    for prim, k, op, lay in OPS:
        grids[lay].apply(prim, k, op)
    # secondary layers may only raise the skin a limited height above the primary masses: anything placed
    # further out is clipped away instead of floating as a rod
    D = grids["P"].d
    for name in ("B", "M", "C"):
        m, kb = LAYERS[name]
        S = grids[name].d
        clipped = sdf.smax(S, D - m, 0.4 * m)
        D = sdf.smin(D, clipped, kb).astype(np.float32)
        grids[name].d = None
    g.d = D - 0.3                    # skin over everything: a thin layer that softens bone edges
    return g
