"""The Listener's skeleton for Unreal: names, hierarchy and rest positions from the sculpt's landmarks.

Unreal conventions: a single `root` bone at the origin (the armature object is named "Armature", which the FBX
importer drops), mannequin-style names (pelvis, spine_01..05, neck_01..02, head, clavicle_l, upperarm_l,
lowerarm_l, hand_l, index_metacarpal_l, index_01_l.., thigh_l, calf_l, foot_l, ball_l) plus the membrane's strut
chains (membrane_strut_<n>_01..03). The creature faces -Y in Blender (+Y in Unreal after the axis conversion).
"""
import numpy as np

FINGER_NAMES = ("index", "middle", "ring", "pinky")


def unit(v):
    v = np.asarray(v, float)
    n = np.linalg.norm(v)
    return v / n if n > 1e-9 else v


def define(J, head_frame, struts):
    """J: joints dict (np arrays). head_frame: horn base/D/U/S/L/r0/r1/bend. Returns list of bone dicts."""
    B = []

    def bone(name, parent, head, tail, up):
        B.append({"name": name, "parent": parent, "head": np.asarray(head, float), "tail": np.asarray(tail, float),
                  "up": unit(up)})

    fwd = np.array([0.0, -1.0, 0.0])
    up = np.array([0.0, 0.0, 1.0])
    bone("root", None, [0, 0, 0], [0, -12.0, 0], up)
    bone("pelvis", "root", J["pelvis"], J["spine_01"], fwd)
    chain = ["spine_01", "spine_02", "spine_03", "spine_04", "spine_05", "neck_01", "neck_02", "head"]
    parent = "pelvis"
    for a, b in zip(chain[:-1], chain[1:]):
        bone(a, parent, J[a], J[b], fwd)
        parent = a
    base, D, Uh = np.asarray(head_frame["base"]), np.asarray(head_frame["D"]), np.asarray(head_frame["U"])
    bone("head", "neck_02", J["head"], base + D * 6.0, fwd)
    # membrane: a throat bone along the horn, then three-bone chains along each strut to its tip
    L, r0, r1, bend = head_frame["L"], head_frame["r0"], head_frame["r1"], head_frame["bend"]
    S = np.cross(D, Uh)

    def horn_point(theta, s, out=0.0):
        c = base + L * (s * D + bend * s * s * Uh)
        R = r0 + (r1 - r0) * s ** 2.35 + out
        return c + (np.cos(theta) * Uh + np.sin(theta) * S) * R

    throat_tail = base + L * (0.22 * D + bend * 0.22 ** 2 * Uh)
    bone("membrane_throat", "head", base + D * 6.0, throat_tail, Uh)
    for i, (ang, ext, _) in enumerate(struts):
        prev = "membrane_throat"
        pts = [horn_point(ang, 0.22), horn_point(ang, 0.5), horn_point(ang, 0.78), horn_point(ang, 1.0 + 0.045 * ext)]
        for j in range(3):
            nm = "membrane_strut_%02d_%02d" % (i + 1, j + 1)
            radial = np.cos(ang) * Uh + np.sin(ang) * S
            bone(nm, prev, pts[j], pts[j + 1], radial)
            prev = nm
    for s in "lr":
        bone("clavicle_" + s, "spine_05", J["clavicle_" + s], J["upperarm_" + s], up)
        bone("upperarm_" + s, "clavicle_" + s, J["upperarm_" + s], J["lowerarm_" + s], fwd)
        bone("lowerarm_" + s, "upperarm_" + s, J["lowerarm_" + s], J["hand_" + s], fwd)
        a, t, n = np.asarray(J["hand_axes_" + s], float)
        bone("hand_" + s, "lowerarm_" + s, J["hand_" + s], J["hand_" + s] + a * 10.0, t)
        for f in FINGER_NAMES:
            kn = J["%s_01_%s" % (f, s)]
            bone("%s_metacarpal_%s" % (f, s), "hand_" + s, J["metacarpal_%s_%s" % (f, s)], kn, t)
            prev = "%s_metacarpal_%s" % (f, s)
            for k in range(1, 5):
                h = J["%s_%02d_%s" % (f, k, s)]
                tl = J["%s_%02d_%s" % (f, k + 1, s)] if k < 4 else J["%s_tip_%s" % (f, s)]
                nm = "%s_%02d_%s" % (f, k, s)
                bone(nm, prev, h, tl, t)
                prev = nm
        prev = "hand_" + s
        for k in range(1, 4):
            h = J["thumb_%02d_%s" % (k, s)]
            tl = J["thumb_%02d_%s" % (k + 1, s)] if k < 3 else J["thumb_tip_" + s]
            nm = "thumb_%02d_%s" % (k, s)
            bone(nm, prev, h, tl, n)
            prev = nm
        bone("thigh_" + s, "pelvis", J["thigh_" + s], J["calf_" + s], fwd)
        bone("calf_" + s, "thigh_" + s, J["calf_" + s], J["foot_" + s], fwd)
        bone("foot_" + s, "calf_" + s, J["foot_" + s], J["ball_" + s], up)
        bone("ball_" + s, "foot_" + s, J["ball_" + s], J["toe_tip_" + s], up)
    return B


def membrane_weights(theta, u, layer, struts):
    """Weights for the horn shell from its own parameters: head at the throat, then the two nearest struts
    (by angle) and the chain bones along the strut (by depth). Returns dict bone -> weights array."""
    W = {}
    angs = np.array([a for a, _, _ in struts])
    order = np.argsort(angs)
    angs_sorted = angs[order]
    uc = np.clip(u, -0.3, 1.1)
    # throat -> head, gullet -> head
    head_w = np.clip((0.2 - uc) / 0.12, 0.0, 1.0)
    head_w[layer == 3] = 1.0
    W["head"] = head_w
    throat_w = np.clip(1.0 - np.abs(uc - 0.18) / 0.12, 0.0, 1.0) * (1 - head_w)
    W["membrane_throat"] = throat_w
    rest = 1.0 - head_w - throat_w
    # angular interpolation between neighbouring struts
    th = np.mod(theta, 2 * np.pi)
    idx = np.searchsorted(angs_sorted, th) % len(angs_sorted)
    prev_i = (idx - 1) % len(angs_sorted)
    a0 = angs_sorted[prev_i]
    a1 = angs_sorted[idx]
    span = np.mod(a1 - a0, 2 * np.pi)
    f = np.mod(th - a0, 2 * np.pi) / np.maximum(span, 1e-6)
    f = f * f * (3 - 2 * f)
    for strut_rank, frac in ((prev_i, 1 - f), (idx, f)):
        sid = order[strut_rank]
        # along the chain: 01 (0.22-0.5), 02 (0.5-0.78), 03 (0.78-tip), smooth hand-offs
        seg = [np.clip(1 - np.abs(uc - c) / w, 0, 1) for c, w in ((0.36, 0.2), (0.64, 0.2), (0.92, 0.2))]
        seg[2] = np.maximum(seg[2], (uc > 0.92).astype(float))
        tot = seg[0] + seg[1] + seg[2] + 1e-9
        for j in range(3):
            nm = "membrane_strut_%02d_%02d" % (sid + 1, j + 1)
            W[nm] = W.get(nm, 0.0) + rest * frac * seg[j] / tot
    return W


def two_bone_ik(a, b, c, target, pole):
    """Joint chain a (root) -> b -> c; returns new b, c so that c reaches toward target, bending toward pole."""
    l1 = np.linalg.norm(b - a)
    l2 = np.linalg.norm(c - b)
    d = target - a
    dist = np.clip(np.linalg.norm(d), abs(l1 - l2) + 1e-3, l1 + l2 - 1e-3)
    dn = unit(d)
    # law of cosines for the angle at the root
    cos_a = (l1 * l1 + dist * dist - l2 * l2) / (2 * l1 * dist)
    ang = np.arccos(np.clip(cos_a, -1, 1))
    pv = pole - a
    pv = unit(pv - dn * np.dot(pv, dn))
    nb = a + dn * np.cos(ang) * l1 + pv * np.sin(ang) * l1
    nc = a + dn * dist
    return nb, nc
