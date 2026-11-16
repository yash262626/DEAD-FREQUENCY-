"""Anatomical UV seams for the Listener's body game mesh.

Parts come from the nearest bone segment (torso, arms, hands, legs, feet); the torso is split into front and back
along the sides, each limb is opened along its inner side, hands and feet are split into back and palm/sole.
Seams are the edges between those regions. Pure numpy over (verts, edges); Blender does the unwrap.
"""
import numpy as np

PARTS = ["torso", "arm_l", "arm_r", "hand_l", "hand_r", "leg_l", "leg_r", "foot_l", "foot_r"]


def seg_dist(P, a, b):
    ab = b - a
    t = np.clip(((P - a) @ ab) / max(ab @ ab, 1e-9), 0.0, 1.0)
    q = a + t[:, None] * ab
    return np.linalg.norm(P - q, axis=1), t, q


def bone_segments(J):
    j = {k: np.asarray(v, float) for k, v in J.items() if not k.startswith("hand_axes")}
    segs = []   # (part, a, b, radius-ish weight)
    spine = ["pelvis", "spine_01", "spine_02", "spine_03", "spine_04", "spine_05", "neck_01", "neck_02", "head"]
    for a, b in zip(spine[:-1], spine[1:]):
        segs.append(("torso", j[a], j[b], 1.0))
    for s in "lr":
        segs.append(("torso", j["spine_05"], j["clavicle_" + s], 1.0))
        segs.append(("torso", j["clavicle_" + s], j["upperarm_" + s] * 0.7 + j["clavicle_" + s] * 0.3, 1.0))
        segs.append(("arm_" + s, j["upperarm_" + s], j["lowerarm_" + s], 1.0))
        segs.append(("arm_" + s, j["lowerarm_" + s], j["hand_" + s], 1.0))
        for f in ("index", "middle", "ring", "pinky", "thumb"):
            names = ["hand_" + s] + sorted(k for k in j if k.startswith(f + "_") and k.endswith("_" + s))
            pts = [j[n] for n in names]
            for a, b in zip(pts[:-1], pts[1:]):
                segs.append(("hand_" + s, a, b, 0.6))
        segs.append(("torso", j["pelvis"], j["thigh_" + s], 1.0))
        segs.append(("leg_" + s, j["thigh_" + s], j["calf_" + s], 1.0))
        segs.append(("leg_" + s, j["calf_" + s], j["foot_" + s], 1.0))
        segs.append(("foot_" + s, j["foot_" + s], j["ball_" + s], 0.7))
        segs.append(("foot_" + s, j["ball_" + s], j["toe_tip_" + s], 0.6))
    return segs


def smooth_labels(lab, nbrs, n_iter=3, n_labels=None):
    n_labels = n_labels or lab.max() + 1
    for _ in range(n_iter):
        votes = np.zeros((len(lab), n_labels))
        np.add.at(votes, (nbrs[:, 0], lab[nbrs[:, 1]]), 1)
        np.add.at(votes, (nbrs[:, 1], lab[nbrs[:, 0]]), 1)
        votes[np.arange(len(lab)), lab] += 1.5
        lab = votes.argmax(axis=1)
    return lab


def labels_for(P, J, segs=None):
    segs = segs or bone_segments(J)
    D = np.full((len(P), len(PARTS)), np.inf)
    for part, a, b, w in segs:
        d, _, _ = seg_dist(P, a, b)
        pi = PARTS.index(part)
        D[:, pi] = np.minimum(D[:, pi], d / w)
    return D.argmin(axis=1)


def compute(V, E, J, F=None, EF=None):
    """V verts, E edges (m,2), J joints. F: face centroids (k,3) and EF: (m,2) faces on each edge (-1 = none).
    Regions are assigned to faces, so seams are the edges ALONG region boundaries (closed cuts).
    Returns (seam per edge, part label per vertex, region per face)."""
    segs = bone_segments(J)
    vlab = smooth_labels(labels_for(V, J, segs), E, 4, len(PARTS))
    if F is None:
        return np.zeros(len(E), bool), vlab, None
    # face labels: majority of the face's smoothed vertex labels is approximated by the centroid's nearest bone,
    # then smoothed over face adjacency
    flab = labels_for(F, J, segs)
    fe = EF[(EF[:, 0] >= 0) & (EF[:, 1] >= 0)]
    flab = smooth_labels(flab, fe, 6, len(PARTS))
    region = flab * 4
    jj = {k: np.asarray(v, float) for k, v in J.items() if not k.startswith("hand_axes")}
    # torso: front / back halves, split at the centre line of each height band
    t = flab == 0
    zs = F[t, 2]
    bins = np.linspace(zs.min(), zs.max(), 60)
    idx = np.clip(np.digitize(F[:, 2], bins) - 1, 0, len(bins) - 2)
    cy = np.full(len(bins) - 1, np.nan)
    for i in range(len(bins) - 1):
        m = t & (idx == i)
        if m.sum() > 8:
            cy[i] = 0.5 * (F[m, 1].min() + F[m, 1].max())
    good = ~np.isnan(cy)
    cy = np.interp(np.arange(len(cy)), np.nonzero(good)[0], cy[good])
    region[t & (F[:, 1] > cy[idx])] += 1
    # limbs: opened along the inner side
    ang_f = {}
    for part, (j0, j1), inner in (("arm_l", ("upperarm_l", "hand_l"), (-1, 0, -1)), ("arm_r", ("upperarm_r", "hand_r"), (1, 0, -1)),
                                  ("leg_l", ("thigh_l", "foot_l"), (-1, 0, 0)), ("leg_r", ("thigh_r", "foot_r"), (1, 0, 0))):
        m = flab == PARTS.index(part)
        a, b = jj[j0], jj[j1]
        ax = (b - a) / np.linalg.norm(b - a)
        inn = np.asarray(inner, float)
        inn = inn - (inn @ ax) * ax
        inn /= np.linalg.norm(inn)
        oth = np.cross(ax, inn)
        r = F - a
        ang = np.arctan2(r @ oth, r @ inn)
        region[m & (ang > 0)] += 1
        ang_f[part] = ang
        # upper and lower segment as separate islands (seam round the elbow / knee)
        mid_joint = jj[("lowerarm_" if part.startswith("arm") else "calf_") + part[-1]]
        t_joint = np.dot(mid_joint - a, ax)
        region[m & ((r @ ax) > t_joint)] += 2
    # hands: back / palm; feet: top / sole
    for sd in "lr":
        m = flab == PARTS.index("hand_" + sd)
        n = np.asarray(J["hand_axes_" + sd], float)[2]
        # split by which side of the local finger/hand axis the face lies on
        side = np.zeros(len(F))
        best = np.full(len(F), np.inf)
        for part, a, b, w in segs:
            if part != "hand_" + sd:
                continue
            d, tt, q = seg_dist(F, a, b)
            upd = d < best
            best[upd] = d[upd]
            side[upd] = ((F - q) @ n)[upd]
        region[m & (side > 0)] += 1
        m = flab == PARTS.index("foot_" + sd)
        region[m & (F[:, 2] < 1.8)] += 1
    ok = (EF[:, 0] >= 0) & (EF[:, 1] >= 0)
    seam = np.zeros(len(E), bool)
    seam[ok] = region[EF[ok, 0]] != region[EF[ok, 1]]
    # limb splits: keep the cut on the inner side only (drop the outer line where the angle wraps)
    mid = 0.5 * (V[E[:, 0]] + V[E[:, 1]])
    for part, ang in ang_f.items():
        pi = PARTS.index(part)
        both = ok & (flab[np.maximum(EF[:, 0], 0)] == pi) & (flab[np.maximum(EF[:, 1], 0)] == pi)
        outer = both & (np.abs(ang[np.maximum(EF[:, 0], 0)]) > np.pi * 0.5) & (np.abs(ang[np.maximum(EF[:, 1], 0)]) > np.pi * 0.5)
        seam[outer] = False
    del mid
    return seam, vlab, region
