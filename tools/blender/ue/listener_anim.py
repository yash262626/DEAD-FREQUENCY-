"""The Listener's animation set, authored as code: postures, gaits with planted feet (IK), key-posed actions,
and secondary motion (springs on the arms, head and membrane struts, noise twitches).

All locomotion is in place: the clip's foot speed matches the Unreal movement speed it is meant for, so the feet
do not slide when the capsule moves at that speed (walk 150, stalk 200, run 440, crawl 100 cm/s).
World-space conventions (Blender): up +Z, the creature faces -Y, its left is +X.
"""
import numpy as np

from anim import FPS, Pose, Spring, axis_angle, keys, noise1, smooth, unit

X, Y, Z = np.eye(3)
FWD = -Y

CLIPS = {
    # name: (frames, loop, playback speed in cm/s for in-place locomotion)
    "Idle": (120, True, 0),
    "Walk": (30, True, 150),
    "Stalk": (30, True, 200),
    "Run": (18, True, 440),
    "Crawl": (36, True, 100),
    "Listen": (72, False, 0),
    "Attack": (54, False, 0),
    "Drag": (84, False, 0),
}


class Ctx:
    def __init__(self, rig):
        self.rig = rig
        r = rig
        self.side = {"l": 1.0, "r": -1.0}
        self.rest_rot = {n: r.rest[i][:3, :3].copy() for n, i in r.index.items()}
        self.struts = sorted(n for n in r.names if n.startswith("membrane_strut_") and n.endswith("_01"))
        self.fingers = ("index", "middle", "ring", "pinky")


def rot_w(P, name, axis, deg):
    """Rotate a bone in armature space about a world axis through its head (FK-style, children follow)."""
    W = P.world(name)
    P.set_world_rot(name, axis_angle(axis, np.radians(deg)) @ W[:3, :3])


def posture(P, c, hunch=1.0, crouch=0.0, neck_lift=1.0, arms=1.0, lean=0.0, yaw=0.0, side_bend=0.0):
    """The Listener's habitual stance: spine curled forward, head craned up and out, arms hanging long."""
    i = P.rig.index["pelvis"]
    P.basis[i][:3, 3] += np.array([0.0, 0.0, 0.0])
    P.solve()
    rot_w(P, "pelvis", X, 6.0 * hunch + 14.0 * crouch + lean * 0.3)
    rot_w(P, "pelvis", Z, yaw * 0.6)
    for name, a in (("spine_01", 5), ("spine_02", 8), ("spine_03", 11), ("spine_04", 11), ("spine_05", 8)):
        rot_w(P, name, X, a * hunch + lean * 0.14)
        rot_w(P, name, Z, -yaw * 0.12)
        rot_w(P, name, -Y, side_bend * 0.2)
    for name, a in (("neck_01", -14), ("neck_02", -16), ("head", -12)):
        rot_w(P, name, X, a * neck_lift * hunch)
    # arms hang under gravity whatever the torso does
    for s in "lr":
        sg = c.side[s]
        P.aim("upperarm_" + s, unit(np.array([sg * 0.18, -0.12, -1.0])) * arms + (1 - arms) * P.world("upperarm_" + s)[:3, 1])
        P.aim("lowerarm_" + s, unit(np.array([sg * 0.06, -0.32, -1.0])))
        relax_hand(P, c, s, 0.35)


def relax_hand(P, c, s, curl=0.35, spread=0.0, twitch=None):
    """Fingers curled toward the palm by `curl` (0 straight, 1 fist)."""
    W = P.world("hand_" + s)
    for f in c.fingers:
        for k, w in ((1, 0.6), (2, 1.0), (3, 0.9), (4, 0.7)):
            nm = "%s_%02d_%s" % (f, k, s)
            Wb = P.world(nm)
            d = Wb[:3, 1]
            n_palm = palm_normal(P, c, s)
            ax = unit(np.cross(d, n_palm))
            amt = curl * 32.0 * w
            if twitch is not None:
                amt += twitch.get((f, k), 0.0)
            rot_w(P, nm, ax, amt)
        if spread:
            nm = "%s_01_%s" % (f, s)
            off = {"index": 1.0, "middle": 0.3, "ring": -0.4, "pinky": -1.0}[f]
            rot_w(P, nm, palm_normal(P, c, s), spread * off * 8.0 * c.side[s])
    for k in (1, 2, 3):
        nm = "thumb_%02d_%s" % (k, s)
        Wb = P.world(nm)
        ax = unit(np.cross(Wb[:3, 1], palm_normal(P, c, s)))
        rot_w(P, nm, ax, curl * 18.0)
    del W


def palm_normal(P, c, s):
    """Palm normal from the hand bone frame: the hand's X axis (perpendicular to the thumb-side Z)."""
    R = P.world("hand_" + s)[:3, :3]
    rest = c.rest_rot["hand_" + s]
    # in the rest pose the palm faces the body: pick the sign of X that matches it
    n_rest = rest[:, 0] if np.dot(rest[:, 0], np.array([-c.side[s], 0, -1])) > 0 else -rest[:, 0]
    sign = 1.0 if np.allclose(n_rest, rest[:, 0]) else -1.0
    return R[:, 0] * sign


def foot_plant(P, c, s, ball_y, pitch, lift=0.0, x_off=0.0, pelvis_shift=None):
    """IK the leg so the foot sits with its ball at forward offset ball_y (cm, -Y forward) and heel pitch (deg,
    positive = heel up, pivoting on the ball; negative = toes up, pivoting on the heel)."""
    r = P.rig
    ball0 = r.head("ball_" + s)
    ank0 = r.head("foot_" + s)
    heel0 = np.array([ank0[0], ank0[1] + 3.0, 0.4])
    ball = np.array([ball0[0] + x_off, ball0[1] + ball_y, ball0[2] + lift])
    shift = ball - ball0
    if pitch >= 0:
        R = axis_angle(X, np.radians(pitch))
        ankle = ball + R @ (ank0 - ball0)
    else:
        heel = heel0 + shift
        R = axis_angle(X, np.radians(pitch))
        ankle = heel + R @ (ank0 - heel0)
    hip = P.world("thigh_" + s)[:3, 3]
    pole = hip + FWD * 40.0 + np.array([c.side[s] * 6.0, 0, -30.0])
    P.ik("thigh_" + s, "calf_" + s, ankle, pole, z_to_pole=True, end="foot_" + s, end_rot=R @ c.rest_rot["foot_" + s])
    if pitch > 0:          # toes stay on the ground while the heel rises
        P.set_world_rot("ball_" + s, c.rest_rot["ball_" + s])
    else:
        P.set_world_rot("ball_" + s, R @ axis_angle(X, np.radians(-6.0)) @ c.rest_rot["ball_" + s])


def gait_foot(phase, duty, stance_len, lift):
    """Foot ball offset (y, cm; -Y forward), lift (cm) and pitch (deg) for a gait phase in [0, 1)."""
    if phase < duty:
        t = phase / duty
        y = -stance_len * (0.5 - t)            # +half forward at contact ... -half behind at toe-off
        y = -y
        y = stance_len * (t - 0.5)              # moves backward relative to the body
        pitch = keys(t, [(0.0, -8.0), (0.14, 0.0), (0.62, 0.0), (1.0, 32.0)])
        return float(y), 0.0, float(pitch)
    t = (phase - duty) / (1 - duty)
    y = stance_len * (0.5 - smooth(t))
    lift_z = lift * np.sin(np.pi * t) ** 0.9
    pitch = keys(t, [(0.0, 34.0), (0.45, 6.0), (1.0, -8.0)])
    return float(y), float(lift_z), float(pitch)


def struts_flare(P, c, amount, ripple=0.0, t=0.0):
    """Open (positive) or fold (negative) the membrane's struts, with a travelling ripple."""
    D = P.world("membrane_throat")[:3, 1]
    for i, nm in enumerate(c.struts):
        base = nm[:-3]
        for j in (1, 2, 3):
            b = "%s_%02d" % (base, j)
            Wb = P.world(b)
            radial = Wb[:3, 1] - D * np.dot(Wb[:3, 1], D)
            ax = unit(np.cross(D, radial)) if np.linalg.norm(radial) > 1e-6 else X
            w = (0.6, 0.3, 0.25)[j - 1]
            rp = ripple * np.sin(2 * np.pi * (t * 1.0) - i * 0.9 - j * 0.6) * (0.5 + 0.5 * j)
            rot_w(P, b, ax, amount * w + rp)


def write_action(arm, name, frames, poses, loop):
    """poses: list of Pose objects, one per frame. Writes quaternion (all bones) and location (pelvis) keys."""
    import bpy
    act = bpy.data.actions.new(name)
    act.use_fake_user = True
    rig = poses[0].rig
    nf = len(poses)
    for pb in arm.pose.bones:
        pb.rotation_mode = "QUATERNION"
    for i, bn in enumerate(rig.names):
        qs = np.array([quat_basis(P, i) for P in poses])
        for k in range(1, nf):                       # keep quaternions on one hemisphere: no flips
            if np.dot(qs[k], qs[k - 1]) < 0:
                qs[k] = -qs[k]
        path = 'pose.bones["%s"].rotation_quaternion' % bn
        for comp in range(4):
            fc = act.fcurves.new(path, index=comp, action_group=bn)
            fc.keyframe_points.add(nf)
            co = np.empty(nf * 2)
            co[0::2] = np.arange(nf)
            co[1::2] = qs[:, comp]
            fc.keyframe_points.foreach_set("co", co)
            fc.update()
        if bn in ("pelvis", "root"):
            ls = np.array([P.basis[i][:3, 3] for P in poses])
            path = 'pose.bones["%s"].location' % bn
            for comp in range(3):
                fc = act.fcurves.new(path, index=comp, action_group=bn)
                fc.keyframe_points.add(nf)
                co = np.empty(nf * 2)
                co[0::2] = np.arange(nf)
                co[1::2] = ls[:, comp]
                fc.keyframe_points.foreach_set("co", co)
                fc.update()
    for fc in act.fcurves:
        for kp in fc.keyframe_points:
            kp.interpolation = "LINEAR"
    act.frame_range = (0, nf - 1 if not loop else nf - 1)
    act["df_loop"] = bool(loop)
    return act


def quat_basis(P, i):
    from anim import quat_from_mat
    return quat_from_mat(P.basis[i][:3, :3])


# ------------------------------------------------------------------------------------------------ clips

def make_clip(rig, name):
    c = Ctx(rig)
    nf, loop, speed = CLIPS[name]
    fn = {"Idle": clip_idle, "Walk": clip_walk, "Stalk": clip_stalk, "Run": clip_run, "Crawl": clip_crawl,
          "Listen": clip_listen, "Attack": clip_attack, "Drag": clip_drag}[name]
    # loops: simulate secondary motion for three cycles and keep the last (periodic)
    reps = 3 if loop else 1
    springs = {}
    poses = []
    for r_ in range(reps):
        for f in range(nf):
            P = fn(rig, c, f, nf, springs)
            if r_ == reps - 1:
                poses.append(P)
    return poses, loop


def spring(springs, key, freq, damp, target):
    if key not in springs:
        springs[key] = Spring(freq, damp, target)
    return springs[key].step(target)


def secondary(P, c, springs, t, head_turn=0.0, flare=0.0, ripple=0.0, arm_target=None):
    """Membrane struts lag the head's motion; fingers twitch; arms swing like heavy pendulums."""
    hd = P.world("head")[:3, 1]
    lag = spring(springs, "head_dir", 2.2, 0.28, hd)
    jig = np.degrees(np.arcsin(np.clip(np.linalg.norm(np.cross(hd, lag)), 0, 1)))
    struts_flare(P, c, flare - 0.6 * jig, ripple, t)
    for s in "lr":
        tw = {(f, k): 6.0 * noise1(t * 1.7 + hash((f, k, s)) % 97, seed=hash((f, s)) % 1000, octaves=2)
              for f in c.fingers for k in (2, 3, 4)}
        relax_hand(P, c, s, 0.0, twitch=tw)


def base_pose(rig):
    P = Pose(rig)
    P.solve()
    return P


def pelvis_offset(P, v):
    i = P.rig.index["pelvis"]
    # pelvis location is in its own rest-local space: convert a world offset
    R = P.rig.rest[i][:3, :3]
    P.basis[i][:3, 3] = R.T @ np.asarray(v, float)
    P.solve()


def clip_idle(rig, c, f, nf, sp):
    t = f / FPS
    ph = f / nf
    P = base_pose(rig)
    breathe = np.sin(2 * np.pi * ph * 3)                 # three breaths per loop
    sway = np.sin(2 * np.pi * ph)
    pelvis_offset(P, [1.2 * sway, 0.0, -9.0 + 0.4 * breathe])
    head_noise = 6.0 * noise1(t * 0.6 + 0.0, seed=11)
    posture(P, c, hunch=1.0 + 0.04 * breathe, yaw=1.5 * sway, side_bend=1.2 * sway)
    rot_w(P, "spine_04", X, -1.2 * breathe)
    rot_w(P, "head", Z, head_noise)
    rot_w(P, "neck_02", X, 2.0 * noise1(t * 0.5, seed=12))
    for s in "lr":
        foot_plant(P, c, s, 0.0, 0.0)
    secondary(P, c, sp, t, flare=4.0 + 3.0 * (0.5 + 0.5 * np.sin(2 * np.pi * ph * 3 + 0.8)), ripple=1.2)
    return P


def locomotion(rig, c, f, nf, sp, speed, duty, lift, drop, bob, sway_amt, yaw_amt, hunch, lean, arm_swing, neck_lift,
               flare, head_bob):
    ph = f / nf
    t = f / FPS
    T = nf / FPS
    stance_len = speed * T * duty
    P = base_pose(rig)
    bob_z = -bob * (0.5 + 0.5 * np.cos(4 * np.pi * ph))
    pelvis_offset(P, [sway_amt * np.sin(2 * np.pi * ph), 0.0, -drop + bob_z])
    yaw = -yaw_amt * np.cos(2 * np.pi * ph)
    posture(P, c, hunch=hunch, lean=lean, yaw=yaw, neck_lift=neck_lift)
    for s, off in (("l", 0.0), ("r", 0.5)):
        y, lz, pitch = gait_foot((ph + off) % 1.0, duty, stance_len, lift)
        foot_plant(P, c, s, y, pitch, lift=lz)
    # arms swing opposite the legs, lagging like pendulums
    for s, sgn in (("l", 1.0), ("r", -1.0)):
        target = sgn * arm_swing * np.cos(2 * np.pi * ph - 0.5)
        a = spring(sp, "arm_" + s, 1.9, 0.3, target)
        rot_w(P, "upperarm_" + s, X, float(a))
        rot_w(P, "lowerarm_" + s, X, float(-0.35 * a) - 8.0)
    # the head stays level and aimed: counter the bob with lag
    rot_w(P, "head", X, head_bob * np.cos(4 * np.pi * ph + 0.6))
    secondary(P, c, sp, t, flare=flare, ripple=0.6)
    return P


def clip_walk(rig, c, f, nf, sp):
    return locomotion(rig, c, f, nf, sp, speed=150, duty=0.6, lift=11, drop=12, bob=2.6, sway_amt=2.2, yaw_amt=7,
                      hunch=1.0, lean=4, arm_swing=14, neck_lift=1.0, flare=2.0, head_bob=2.0)


def clip_stalk(rig, c, f, nf, sp):
    return locomotion(rig, c, f, nf, sp, speed=200, duty=0.66, lift=8, drop=25, bob=1.4, sway_amt=1.4, yaw_amt=5,
                      hunch=1.3, lean=16, arm_swing=6, neck_lift=1.35, flare=7.0, head_bob=1.0)


def clip_run(rig, c, f, nf, sp):
    return locomotion(rig, c, f, nf, sp, speed=440, duty=0.38, lift=22, drop=15, bob=4.5, sway_amt=1.5, yaw_amt=10,
                      hunch=1.25, lean=30, arm_swing=34, neck_lift=1.5, flare=-10.0, head_bob=3.5)


def clip_crawl(rig, c, f, nf, sp):
    """On all fours, torso low and level, membrane forward: a diagonal gait (left hand with right foot)."""
    ph = f / nf
    t = f / FPS
    T = nf / FPS
    duty = 0.72
    stance_len = 100 * T * duty
    P = base_pose(rig)
    pelvis_offset(P, [1.2 * np.sin(2 * np.pi * ph), 6.0, -52.0 - 1.5 * (0.5 + 0.5 * np.cos(4 * np.pi * ph))])
    rot_w(P, "pelvis", X, 52.0)
    for name, a in (("spine_01", 6), ("spine_02", 6), ("spine_03", 5), ("spine_04", 2), ("spine_05", -4)):
        rot_w(P, name, X, a)
        rot_w(P, name, Z, 3.0 * np.cos(2 * np.pi * ph) * (1 if name < "spine_03" else -1))
    for name, a in (("neck_01", -38), ("neck_02", -30), ("head", -14)):
        rot_w(P, name, X, a)
    for s, off in (("l", 0.0), ("r", 0.5)):
        y, lz, pitch = gait_foot((ph + off) % 1.0, duty, stance_len, 9)
        foot_plant(P, c, s, y + 14.0, pitch, lift=lz, x_off=c.side[s] * 4.0)
    # hands are the front feet: planted under the shoulders, palms down
    for s, off in (("l", 0.5), ("r", 0.0)):
        y, lz, pitch = gait_foot((ph + off) % 1.0, duty, stance_len, 10)
        sh = P.world("upperarm_" + s)[:3, 3]
        target = np.array([sh[0] + c.side[s] * 7.0, sh[1] - 26.0 + y, 4.0 + lz])
        pole = sh + np.array([c.side[s] * 30.0, 25.0, 10.0])
        P.ik("upperarm_" + s, "lowerarm_" + s, target, pole, z_to_pole=False)
        hand_dir = unit(np.array([c.side[s] * 0.15, -1.0, -0.15 - 0.5 * lz / 10.0]))
        P.aim("hand_" + s, hand_dir)
    secondary(P, c, sp, t, flare=-4.0, ripple=0.5)
    return P


def clip_listen(rig, c, f, nf, sp):
    """Something made a sound: it freezes, snaps the horn toward it, flares and clicks, then slowly settles."""
    t = f / FPS
    u = f / (nf - 1)
    P = base_pose(rig)
    pelvis_offset(P, [0, 0, -9.0])
    turn = keys(u, [(0.0, 0.0), (0.12, 38.0), (0.7, 34.0), (1.0, 0.0)])
    tilt = keys(u, [(0.0, 0.0), (0.12, 10.0), (0.5, 14.0), (1.0, 0.0)])
    posture(P, c, hunch=1.0, yaw=turn * 0.25)
    rot_w(P, "neck_01", Z, turn * 0.35)
    rot_w(P, "neck_02", Z, turn * 0.35)
    rot_w(P, "head", Z, turn * 0.3)
    rot_w(P, "head", -Y, tilt)
    flare = keys(u, [(0.0, 3.0), (0.14, 22.0), (0.7, 18.0), (1.0, 3.0)])
    clicks = 3.5 * np.sin(2 * np.pi * 11.0 * t) * keys(u, [(0.0, 0.0), (0.16, 1.0), (0.66, 1.0), (0.78, 0.0)])
    for s in "lr":
        foot_plant(P, c, s, 0.0, 0.0)
    secondary(P, c, sp, t, flare=flare + clicks, ripple=0.8)
    for s in "lr":
        relax_hand(P, c, s, -0.15 * keys(u, [(0, 0), (0.15, 1), (0.8, 1), (1, 0)]),
                   spread=keys(u, [(0, 0), (0.15, 1.0), (0.8, 1.0), (1, 0)]))
    return P


def clip_attack(rig, c, f, nf, sp):
    """Rears back, horn flared, then lunges and seizes with both hands; holds, shoves, recovers."""
    t = f / FPS
    u = f / (nf - 1)
    P = base_pose(rig)
    fwd = keys(u, [(0.0, 0.0), (0.22, 8.0), (0.38, -26.0), (0.62, -24.0), (0.78, -10.0), (1.0, 0.0)])
    drop = keys(u, [(0.0, -9.0), (0.22, -4.0), (0.38, -20.0), (0.62, -19.0), (1.0, -9.0)])
    pelvis_offset(P, [0, fwd * 0.6, drop])
    lean = keys(u, [(0.0, 0.0), (0.22, -16.0), (0.38, 26.0), (0.62, 22.0), (1.0, 0.0)])
    posture(P, c, hunch=1.0, lean=lean, neck_lift=1.2)
    for s in "lr":
        foot_plant(P, c, s, keys(u, [(0, 0), (0.3, 0), (0.4, -18.0 if s == "l" else 6.0), (0.8, -18.0 if s == "l" else 6.0), (1, 0)]),
                   keys(u, [(0, 0), (0.3, 0), (0.36, 12.0 if s == "r" else 0), (0.42, 0), (1, 0)]))
    reach = keys(u, [(0.0, 0.0), (0.22, -1.0), (0.38, 1.0), (0.62, 0.9), (0.78, 0.3), (1.0, 0.0)])
    for s in "lr":
        sh = P.world("upperarm_" + s)[:3, 3]
        if reach >= 0:
            tgt = sh + np.array([-c.side[s] * 8.0 * reach, -62.0 * reach, -38.0 + 30.0 * reach])
        else:
            tgt = sh + np.array([c.side[s] * 22.0 * -reach, 10.0 * -reach, -40.0 + 48.0 * -reach])
        pole = sh + np.array([c.side[s] * 20.0, 30.0, -10.0])
        P.ik("upperarm_" + s, "lowerarm_" + s, tgt, pole, z_to_pole=False)
    grip = keys(u, [(0.0, 0.35), (0.22, -0.1), (0.36, -0.2), (0.42, 1.0), (0.66, 1.0), (0.8, 0.3), (1.0, 0.35)])
    secondary(P, c, sp, t, flare=keys(u, [(0, 3), (0.22, 26), (0.4, 14), (0.7, 10), (1, 3)]), ripple=1.5)
    for s in "lr":
        relax_hand(P, c, s, grip, spread=keys(u, [(0, 0), (0.22, 1.2), (0.38, 1.0), (0.42, 0), (1, 0)]))
    return P


def clip_drag(rig, c, f, nf, sp):
    """Reaches low into a hiding place, seizes, hauls backward with its whole weight, lifts and flings."""
    t = f / FPS
    u = f / (nf - 1)
    P = base_pose(rig)
    back = keys(u, [(0.0, 0.0), (0.25, -14.0), (0.4, -16.0), (0.62, 26.0), (0.8, 18.0), (1.0, 0.0)])
    drop = keys(u, [(0.0, -9.0), (0.25, -34.0), (0.42, -36.0), (0.62, -20.0), (0.8, -12.0), (1.0, -9.0)])
    pelvis_offset(P, [0, back, drop])
    lean = keys(u, [(0.0, 0.0), (0.25, 42.0), (0.42, 44.0), (0.62, -6.0), (0.8, -14.0), (1.0, 0.0)])
    posture(P, c, hunch=1.0, lean=lean, neck_lift=1.3)
    for s, st in (("l", -12.0), ("r", 10.0)):
        y = keys(u, [(0.0, 0.0), (0.2, st), (0.6, st), (0.7, st + 16.0), (1.0, 0.0)])
        foot_plant(P, c, s, y, keys(u, [(0, 0), (0.6, 0), (0.66, 10 if s == "l" else 0), (0.72, 0), (1, 0)]))
    for s in "lr":
        sh = P.world("upperarm_" + s)[:3, 3]
        reach = keys(u, [(0.0, 0.0), (0.25, 1.0), (0.42, 1.0), (0.62, 0.35), (0.8, -0.6), (1.0, 0.0)])
        if reach >= 0:
            tgt = sh + np.array([-c.side[s] * 6.0, -70.0 * reach, -60.0 * reach - 30.0 * (1 - reach)])
        else:
            tgt = sh + np.array([c.side[s] * 10.0, 20.0 * -reach, -30.0 + 70.0 * -reach])
        pole = sh + np.array([c.side[s] * 25.0, 30.0, 0.0])
        P.ik("upperarm_" + s, "lowerarm_" + s, tgt, pole, z_to_pole=False)
    grip = keys(u, [(0.0, 0.35), (0.25, -0.1), (0.4, 1.0), (0.75, 1.0), (0.82, -0.2), (1.0, 0.35)])
    secondary(P, c, sp, t, flare=keys(u, [(0, 3), (0.4, 16), (0.62, 24), (0.85, 8), (1, 3)]), ripple=1.2)
    for s in "lr":
        relax_hand(P, c, s, grip, spread=keys(u, [(0, 0), (0.25, 1.0), (0.4, 0), (0.8, 1.0), (1, 0)]))
    return P
