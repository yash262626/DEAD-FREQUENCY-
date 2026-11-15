"""The Listener, version 2 — original creature for DEAD FREQUENCY, aimed at the owner's reference sheet
(gaunt, asymmetric, wet veined flesh, multi-jointed clawed fingers, a pleated acoustic membrane with sensory
openings). Procedural sculpt -> 4K bakes -> 78-bone rig -> animations -> 3 LODs -> glTF.
   blender -b --factory-startup --python tools/blender/listener_v2.py -- <work_dir> <stage: mesh|all|anim>
   (anim: re-key the animations on <work_dir>/listener2_rigged.blend and re-export, without rebuilding or re-baking)
Godot axes via G(); faces -Z, feet on y = 0, about 2.3 m to the top of the membrane."""
import sys, os, math, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dflib import *
import bmesh
from mathutils import Vector, Euler

STAGE = sys.argv[-1] if sys.argv[-1] in ("mesh", "all", "anim") else "all"
OUT = sys.argv[-2] if sys.argv[-1] in ("mesh", "all", "anim") else sys.argv[-1]
random.seed(19)
reset()
TEX = 4096          # body maps
MTEX = 2048         # membrane maps

# ================================================================== skeleton (asymmetric on purpose)
J = {
 "pelvis": (0.0, 1.06, 0.04), "spine1": (0.012, 1.22, 0.035), "spine2": (0.022, 1.41, -0.015), "chest": (0.016, 1.6, -0.095),
 "upperchest": (0.004, 1.72, -0.16), "neck1": (-0.004, 1.83, -0.235), "neck2": (-0.014, 1.92, -0.315), "head": (-0.022, 1.98, -0.385),
}
SIDES = {"L": dict(sx=1, sh=1.70, arm=1.04, leg=1.0), "R": dict(sx=-1, sh=1.655, arm=0.97, leg=0.97)}
for s, p in SIDES.items():
    sx, a, l = p["sx"], p["arm"], p["leg"]
    J.update({
     f"hip_{s}": (sx * 0.12, 1.02 - (0.02 if s == "R" else 0), 0.05),
     f"knee_{s}": (sx * 0.15, 0.6 * l + 0.02, -0.10 + (0.04 if s == "R" else 0)),
     f"ankle_{s}": (sx * 0.17, 0.14, 0.06 + (0.02 if s == "R" else 0)),
     f"ball_{s}": (sx * 0.18, 0.042, -0.07),
     f"clav_{s}": (sx * 0.03, p["sh"] + 0.03, -0.17),
     f"shoulder_{s}": (sx * 0.215, p["sh"], -0.125),
     f"elbow_{s}": (sx * 0.31, p["sh"] - 0.42 * a, -0.04),
     f"wrist_{s}": (sx * 0.355, p["sh"] - 0.84 * a, -0.125),
     f"palm_{s}": (sx * 0.365, p["sh"] - 0.95 * a, -0.155),
    })
    pw = J[f"palm_{s}"]
    for k in range(4):                                       # four long, four-jointed fingers
        dz = -0.045 + k * 0.03; dx = sx * (0.006 * (k - 1.5))
        L = (0.095, 0.085, 0.075, 0.06)
        x, y, z = pw[0] + dx, pw[1] - 0.03, pw[2] + dz
        J[f"f{k}0_{s}"] = (x, y, z)
        for j in range(4):
            y -= L[j] * a * (1.0 - 0.07 * abs(k - 1.5)); z -= 0.012 * (j + 1); x += sx * 0.004
            J[f"f{k}{j + 1}_{s}"] = (x, y, z)
    J[f"t0_{s}"] = (pw[0] - sx * 0.022, pw[1] + 0.005, pw[2] - 0.03)
    J[f"t1_{s}"] = (pw[0] - sx * 0.035, pw[1] - 0.06, pw[2] - 0.075)
    J[f"t2_{s}"] = (pw[0] - sx * 0.04, pw[1] - 0.12, pw[2] - 0.1)
    J[f"t3_{s}"] = (pw[0] - sx * 0.042, pw[1] - 0.17, pw[2] - 0.115)
    bl = J[f"ball_{s}"]
    for k in range(4):                                       # four toes, two joints each
        ox = sx * (0.035 - k * 0.022)
        J[f"o{k}0_{s}"] = (bl[0] + ox, 0.035, bl[2] - 0.01)
        J[f"o{k}1_{s}"] = (bl[0] + ox * 1.25, 0.022, bl[2] - 0.085 + 0.01 * k)
        J[f"o{k}2_{s}"] = (bl[0] + ox * 1.45, 0.012, bl[2] - 0.15 + 0.015 * k)
EDGES = [("pelvis", "spine1"), ("spine1", "spine2"), ("spine2", "chest"), ("chest", "upperchest"), ("upperchest", "neck1"), ("neck1", "neck2"), ("neck2", "head")]
for s in "LR":
    EDGES += [("pelvis", f"hip_{s}"), (f"hip_{s}", f"knee_{s}"), (f"knee_{s}", f"ankle_{s}"), (f"ankle_{s}", f"ball_{s}"),
              ("upperchest", f"clav_{s}"), (f"clav_{s}", f"shoulder_{s}"), (f"shoulder_{s}", f"elbow_{s}"), (f"elbow_{s}", f"wrist_{s}"), (f"wrist_{s}", f"palm_{s}"),
              (f"palm_{s}", f"t0_{s}"), (f"t0_{s}", f"t1_{s}"), (f"t1_{s}", f"t2_{s}"), (f"t2_{s}", f"t3_{s}")]
    for k in range(4):
        EDGES += [(f"palm_{s}", f"f{k}0_{s}")] + [(f"f{k}{j}_{s}", f"f{k}{j + 1}_{s}") for j in range(4)]
        EDGES += [(f"ball_{s}", f"o{k}0_{s}"), (f"o{k}0_{s}", f"o{k}1_{s}"), (f"o{k}1_{s}", f"o{k}2_{s}")]
RAD = {"pelvis": (0.13, 0.095), "spine1": (0.09, 0.075), "spine2": (0.118, 0.088), "chest": (0.158, 0.112), "upperchest": (0.162, 0.1),
       "neck1": 0.05, "neck2": 0.042, "head": 0.05}
for s in "LR":
    RAD.update({f"hip_{s}": 0.08, f"knee_{s}": 0.052, f"ankle_{s}": 0.031, f"ball_{s}": 0.028, f"clav_{s}": 0.038, f"shoulder_{s}": 0.055,
                f"elbow_{s}": 0.04, f"wrist_{s}": 0.025, f"palm_{s}": (0.04, 0.018), f"t0_{s}": 0.014, f"t1_{s}": 0.011, f"t2_{s}": 0.009, f"t3_{s}": 0.006})
    for k in range(4):
        RAD[f"f{k}0_{s}"] = 0.0155
        for j, r in enumerate((0.0145, 0.012, 0.0098, 0.0068)): RAD[f"f{k}{j + 1}_{s}"] = r
        RAD.update({f"o{k}0_{s}": 0.012, f"o{k}1_{s}": 0.0095, f"o{k}2_{s}": 0.006})

def skin_body():
    names = list(J.keys()); idx = {n: i for i, n in enumerate(names)}
    me = bpy.data.meshes.new("skel"); me.from_pydata([G(*J[n]) for n in names], [(idx[a], idx[b]) for a, b in EDGES], [])
    ob = bpy.data.objects.new("skel", me); bpy.context.scene.collection.objects.link(ob)
    ob.modifiers.new("skin", 'SKIN')
    for n in names:
        r = RAD[n]; d = me.skin_vertices[0].data[idx[n]]
        d.radius = r if isinstance(r, tuple) else (r, r)
    me.skin_vertices[0].data[idx["pelvis"]].use_root = True
    sub = ob.modifiers.new("sub", 'SUBSURF'); sub.levels = 2
    return realize(ob)

def mid(a, b, t=0.5, off=(0, 0, 0)):
    pa, pb = Vector(J[a] if isinstance(a, str) else a), Vector(J[b] if isinstance(b, str) else b)
    p = pa.lerp(pb, t); return (p.x + off[0], p.y + off[1], p.z + off[2])

def anatomy():
    parts = []
    T = lambda *a, **k: parts.append(tapered(*a, **k))
    for s, p in SIDES.items():
        sx = p["sx"]
        # arm: deltoid, biceps, triceps, twisting forearm strands, knuckles of the elbow
        parts.append(ellipsoid("deltoid", mid(f"shoulder_{s}", f"elbow_{s}", 0.1, (sx * 0.014, 0.0, 0.0)), (0.062, 0.075, 0.062), "skin"))
        T("biceps", [mid(f"shoulder_{s}", f"elbow_{s}", 0.1, (0, 0, -0.025)), mid(f"shoulder_{s}", f"elbow_{s}", 0.45, (0, 0, -0.035)), mid(f"shoulder_{s}", f"elbow_{s}", 0.9, (0, 0, -0.02))], [0.016, 0.04, 0.016], "skin")
        T("triceps", [mid(f"shoulder_{s}", f"elbow_{s}", 0.15, (0, 0, 0.028)), mid(f"shoulder_{s}", f"elbow_{s}", 0.55, (sx * 0.004, 0, 0.03)), mid(f"shoulder_{s}", f"elbow_{s}", 0.95, (0, 0, 0.02))], [0.02, 0.036, 0.013], "skin")
        T("flexor", [mid(f"elbow_{s}", f"wrist_{s}", 0.02, (sx * 0.018, 0, -0.015)), mid(f"elbow_{s}", f"wrist_{s}", 0.4, (sx * 0.006, 0, -0.022)), mid(f"elbow_{s}", f"wrist_{s}", 0.95, (-sx * 0.008, 0, -0.01))], [0.027, 0.021, 0.009], "skin")
        T("extensor", [mid(f"elbow_{s}", f"wrist_{s}", 0.02, (-sx * 0.012, 0, 0.012)), mid(f"elbow_{s}", f"wrist_{s}", 0.5, (sx * 0.012, 0, 0.016)), mid(f"elbow_{s}", f"wrist_{s}", 0.97, (sx * 0.01, 0, 0.004))], [0.023, 0.017, 0.008], "skin")
        parts.append(ellipsoid("olecranon", mid(f"elbow_{s}", f"elbow_{s}", 0, (0, 0.005, 0.028)), (0.02, 0.022, 0.018), "skin"))
        # leg: quadriceps, hamstring, calf, kneecap, Achilles
        T("quad", [mid(f"hip_{s}", f"knee_{s}", 0.1, (0, 0, -0.03)), mid(f"hip_{s}", f"knee_{s}", 0.5, (0, 0, -0.045)), mid(f"hip_{s}", f"knee_{s}", 0.9, (0, 0, -0.03))], [0.042, 0.058, 0.026], "skin")
        T("hamstring", [mid(f"hip_{s}", f"knee_{s}", 0.1, (0, 0, 0.035)), mid(f"hip_{s}", f"knee_{s}", 0.5, (0, 0, 0.04)), mid(f"hip_{s}", f"knee_{s}", 0.95, (0, 0, 0.025))], [0.04, 0.046, 0.016], "skin")
        T("calf", [mid(f"knee_{s}", f"ankle_{s}", 0.05, (0, 0, 0.03)), mid(f"knee_{s}", f"ankle_{s}", 0.3, (0, 0, 0.042)), mid(f"knee_{s}", f"ankle_{s}", 0.75, (0, 0, 0.022)), mid(f"knee_{s}", f"ankle_{s}", 1.0, (0, 0.02, 0.022))], [0.032, 0.048, 0.02, 0.012], "skin")
        parts.append(ellipsoid("patella", mid(f"knee_{s}", f"knee_{s}", 0, (0, 0.01, -0.035)), (0.026, 0.03, 0.016), "skin"))
        # shoulder blade, collarbone, hip crest
        parts.append(ellipsoid("scapula", (sx * 0.115, 1.6, 0.045), (0.07, 0.09, 0.012), "skin"))
        T("clavicle", [(0.0, 1.76, -0.2), (sx * 0.1, 1.77, -0.19), (sx * 0.2, p["sh"] + 0.02, -0.14)], [0.012, 0.012, 0.014], "skin")
        T("iliac", [(sx * 0.03, 1.13, -0.07), (sx * 0.11, 1.12, -0.05), (sx * 0.15, 1.08, 0.02), (sx * 0.1, 1.1, 0.08)], [0.012, 0.016, 0.016, 0.01], "skin")
        # neck cords
        T("neckcord", [(sx * 0.03, 1.95, -0.33), (sx * 0.035, 1.85, -0.25), (sx * 0.02, 1.76, -0.2)], [0.011, 0.017, 0.012], "skin")
        # obliques, pectoral sheet
        T("oblique", [(sx * 0.09, 1.45, -0.09), (sx * 0.1, 1.3, -0.06), (sx * 0.09, 1.16, -0.04)], [0.012, 0.016, 0.01], "skin")
    # ribcage: uneven, deep gaps, a broken rib on the right
    for k in range(8):
        for s, sx in (("L", 1), ("R", -1)):
            y = 1.72 - k * 0.055 + (0.012 if sx < 0 else 0) + random.uniform(-0.006, 0.006)
            w = 0.142 + 0.014 * math.sin(k * 0.8) + (0.008 if sx > 0 else -0.004) - 0.006 * max(0, k - 4)
            pts = []; rr = []
            span = 150 if not (sx < 0 and k == 5) else 85
            for t in range(0, span + 1, 15):
                a = math.radians(t)
                pts.append((sx * w * math.sin(a) * 1.02, y - 0.08 * max(0.0, math.cos(a)) ** 1.4 - 0.02 * (1 - math.cos(a)), -0.1 + k * 0.009 - (0.112 - k * 0.004) * math.cos(a) + 0.075))
                rr.append(0.0085 - 0.0004 * k)
            pts = [(x, yy, z - 0.075) for x, yy, z in pts]
            T(f"rib{k}{s}", pts, rr, "skin", res=4)
    T("sternum", [(0.0, 1.75, -0.215), (0.0, 1.6, -0.205), (0.0, 1.46, -0.185)], [0.014, 0.012, 0.006], "skin")
    for k in range(17):                                      # spine processes
        t = k / 16.0; y = 1.14 + t * 0.78; z = 0.11 - 0.06 * t - 0.17 * t * t
        parts.append(ellipsoid(f"vert{k}", (0.004 * math.sin(k), y, z + 0.006), (0.013, 0.016, 0.014), "skin", seg=12))
    # surgical scars: raised keloid ridges with stitch bars
    for (a, b) in [((0.05, 1.5, -0.165), (-0.06, 1.28, -0.12)), ((0.14, 1.66, -0.08), (0.16, 1.45, -0.05))]:
        pa, pb = Vector(a), Vector(b)
        T("scar", [tuple(pa), tuple(pa.lerp(pb, 0.5) + Vector((0, 0, -0.008))), tuple(pb)], [0.004, 0.005, 0.004], "skin")
        for i in range(7):
            c = pa.lerp(pb, (i + 0.5) / 7); d = (pb - pa).normalized().cross(Vector((0, 0, 1))).normalized() * 0.012
            T("stitch", [tuple(c - d), tuple(c + Vector((0, 0, -0.005))), tuple(c + d)], [0.0018, 0.002, 0.0018], "skin", res=2, bevel_res=2)
    # skull bulb behind the membrane, asymmetric
    parts.append(ellipsoid("skull", (-0.02, 2.0, -0.35), (0.058, 0.07, 0.092), "skin", seg=24))
    return parts

def claws():
    out = []
    for s in "LR":
        for k in range(4):
            a, b = Vector(J[f"f{k}3_{s}"]), Vector(J[f"f{k}4_{s}"])
            d = (b - a).normalized()
            tip = b + d * 0.065 + Vector((0, 0, -0.02))
            out.append(tapered(f"claw_f{k}_{s}", [tuple(b - d * 0.012), tuple(b + d * 0.03 + Vector((0, 0, -0.006))), tuple(tip)], [0.0058, 0.0042, 0.0004], "claw", res=6))
        a, b = Vector(J[f"t2_{s}"]), Vector(J[f"t3_{s}"]); d = (b - a).normalized()
        out.append(tapered(f"claw_t_{s}", [tuple(b - d * 0.01), tuple(b + d * 0.025), tuple(b + d * 0.05 + Vector((0, 0, -0.015)))], [0.0055, 0.004, 0.0004], "claw"))
        for k in range(4):
            a, b = Vector(J[f"o{k}1_{s}"]), Vector(J[f"o{k}2_{s}"]); d = (b - a).normalized()
            out.append(tapered(f"claw_o{k}_{s}", [tuple(b - d * 0.008), tuple(b + d * 0.02), tuple(b + d * 0.04 + Vector((0, -0.012, 0)))], [0.0055, 0.004, 0.0004], "claw"))
    return out

# ================================================================== acoustic membrane
MC = Vector((-0.02, 2.02, -0.43))
def MP(u, v, w):                      # membrane-local (u right, v up, w forward) -> Godot
    return (MC.x + u, MC.y + v, MC.z - w)
def outline(th):
    # v3: one trumpet bell, a little taller than wide, with a lumpy fleshy lip
    r = 0.25 * (1.0 + 0.06 * math.cos(2 * th))
    r *= 1.0 + 0.05 * math.sin(th * 5 + 0.7) + 0.035 * math.sin(th * 11 + 0.3) + 0.02 * math.sin(th * 17)
    return r
N_PLEAT = 17
def surf(r, th, R):
    # a deep funnel opening forward (about 0.37 m deep), the lip flaring outward like a trumpet's bell
    t = r / R
    flare = 1.0 + 0.32 * max(0.0, (t - 0.62) / 0.38) ** 2
    w = 0.30 * t ** 1.35 + 0.07 * max(0.0, (t - 0.8) / 0.2) ** 2 + 0.012 * t ** 1.1 * math.sin(N_PLEAT * th)
    return (r * flare * math.sin(th), r * flare * math.cos(th) * 0.97, w)
def membrane():
    rings, segs = 30, 180
    th0, th1 = -math.pi, math.pi                                   # a closed bell
    bm = bmesh.new(); grid = []
    for i in range(rings + 1):
        row = []
        for j in range(segs):
            th = th0 + (th1 - th0) * j / segs; R = outline(th); r = 0.036 + (R - 0.036) * i / rings
            row.append(bm.verts.new(G(*MP(*surf(r, th, R)))))
        row.append(row[0])
        grid.append(row)
    for i in range(rings):
        for j in range(segs):
            th = th0 + (th1 - th0) * (j + 0.5) / segs; t = (i + 0.5) / rings
            valley = math.sin(N_PLEAT * th) < -0.55
            slit = valley and 0.4 < t < 0.63 and (int((th - th0) / (2 * math.pi / N_PLEAT)) % 2 == 0)
            pore = 0.16 < t < 0.24 and abs(math.sin(N_PLEAT * th * 0.5)) > 0.93
            if slit or pore: continue                          # sensory openings
            bm.faces.new((grid[i][j], grid[i][j + 1], grid[i + 1][j + 1], grid[i + 1][j]))
    me = bpy.data.meshes.new("membrane"); bm.to_mesh(me); bm.free()
    ob = bpy.data.objects.new("membrane", me); bpy.context.scene.collection.objects.link(ob)
    me.materials.append(mat("membrane"))
    so = ob.modifiers.new("thick", 'SOLIDIFY'); so.thickness = 0.0055; so.use_rim = True
    sub = ob.modifiers.new("sub", 'SUBSURF'); sub.levels = 1
    parts = [realize(ob)]
    # cartilage rods along every pleat crest (behind), and a lumpy rim
    for k in range(-8, 9):
        th = (math.pi / 2 + 2 * math.pi * k) / N_PLEAT
        R = outline(th); pts = []; rr = []
        for t in (0.1, 0.3, 0.55, 0.8, 0.97):
            u, v, w = surf(R * t, th, R); pts.append(MP(u, v, w - 0.009)); rr.append(0.0075 * (1.0 - 0.6 * t) + 0.002)
        parts.append(tapered(f"rod{k}", pts, rr, "cartilage", res=5))
    rim = []
    for j in range(73):
        th = -math.pi + 2 * math.pi * j / 72; R = outline(th); u, v, w = surf(R, th, R); rim.append(MP(u, v, w))
    parts.append(tapered("rim", rim, [0.0065 + 0.003 * math.sin(j * 1.7) for j in range(73)], "cartilage", res=3))
    # veins on the front surface, branching outward between the rods
    for k in range(26):                     # veins inside the bell and, every other one, raised on its outside
        th = random.uniform(-math.pi, math.pi); R = outline(th); pts = []; rr = []; side = 0.0045 if k % 2 == 0 else -0.0115
        for t in (0.12, 0.3, 0.5, 0.72, 0.9):
            th2 = th + random.uniform(-0.06, 0.06); u, v, w = surf(R * t, th2, R); pts.append(MP(u, v, w + side)); rr.append(0.003 * (1.1 - t))
        parts.append(tapered(f"vein{k}", pts, rr, "membrane", res=5, bevel_res=2))
    # the pit: papillae around the central opening, and a dark throat behind it
    for k in range(16):
        a = 2 * math.pi * k / 16 + random.uniform(-0.1, 0.1); r = 0.044 + random.uniform(-0.004, 0.008)
        base = MP(r * math.sin(a), r * math.cos(a), 0.004); tip = MP(r * 0.75 * math.sin(a), r * 0.75 * math.cos(a), 0.03 + random.uniform(0, 0.015))
        parts.append(tapered(f"papilla{k}", [base, tip], [0.0055, 0.0008], "cartilage", res=2))
    parts.append(ellipsoid("throat", MP(0, 0, -0.03), (0.045, 0.05, 0.035), "throat", seg=16))
    # wet strands hanging from the lower rim and the pit
    for k, th in enumerate((-2.95, -2.6, -2.2, -1.75, 1.8, 2.25, 2.7, 3.05, 0.0)):    # mucus hanging from the lower lip
        if th == 0.0: start = MP(0.0, -0.05, 0.01)
        else:
            R = outline(th); u, v, w = surf(R * 0.97, th, R); start = MP(u, v, w)
        L = random.uniform(0.08, 0.3); s0 = Vector(start)
        parts.append(tapered(f"drip{k}", [tuple(s0), tuple(s0 + Vector((0.004, -L * 0.5, -0.004))), tuple(s0 + Vector((0.006, -L, -0.006)))], [0.0035, 0.0018, 0.0028], "membrane", res=4))
    ms = [realize(p) if (p.type == 'CURVE' or p.modifiers) else p for p in parts]
    return join("membrane", ms)

# ================================================================== build
def build():
    body = skin_body()
    parts = [body] + anatomy()
    parts = [realize(p) if (p.type == 'CURVE' or p.modifiers) else p for p in parts]
    hi = join("body_hi", parts)
    select_only(hi); hi.data.remesh_voxel_size = 0.0032
    bpy.ops.object.voxel_remesh()
    sm = hi.modifiers.new("smooth", 'CORRECTIVE_SMOOTH'); sm.iterations = 6; sm.use_only_smooth = True
    t1 = bpy.data.textures.new("veins", 'VORONOI'); t1.noise_scale = 0.045; t1.distance_metric = 'DISTANCE'
    d1 = hi.modifiers.new("veins", 'DISPLACE'); d1.texture = t1; d1.strength = -0.0026; d1.mid_level = 0.35
    t2 = bpy.data.textures.new("wrinkle", 'VORONOI'); t2.noise_scale = 0.009
    d2 = hi.modifiers.new("wrinkle", 'DISPLACE'); d2.texture = t2; d2.strength = -0.0012
    t3 = bpy.data.textures.new("lumps", 'CLOUDS'); t3.noise_scale = 0.05
    d3 = hi.modifiers.new("lumps", 'DISPLACE'); d3.texture = t3; d3.strength = 0.004
    hi = realize(hi)
    print("body_hi faces", len(hi.data.polygons))
    # game mesh: coarse re-mesh fitted back onto the sculpt
    lo = hi.copy(); lo.data = hi.data.copy(); lo.name = "body_lo"; bpy.context.scene.collection.objects.link(lo)
    select_only(lo); lo.data.remesh_voxel_size = 0.0085
    bpy.ops.object.voxel_remesh()
    sw = lo.modifiers.new("fit", 'SHRINKWRAP'); sw.target = hi; sw.wrap_method = 'NEAREST_SURFACEPOINT'
    sm2 = lo.modifiers.new("relax", 'CORRECTIVE_SMOOTH'); sm2.iterations = 2; sm2.use_only_smooth = True
    lo = realize(lo)
    for p in lo.data.polygons: p.use_smooth = True
    lo.data.materials.clear(); lo.data.materials.append(mat("M_CreatureSkin"))
    print("body_lo faces", len(lo.data.polygons))
    select_only(lo); bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(70), island_margin=0.002)
    bpy.ops.object.mode_set(mode='OBJECT')
    cl = [realize(c) for c in claws()]
    cl = join("claws", cl); cl.data.materials.clear(); cl.data.materials.append(mat("M_CreatureClaw"))
    for p in cl.data.polygons: p.use_smooth = True
    select_only(cl); bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(70), island_margin=0.01); bpy.ops.object.mode_set(mode='OBJECT')
    mem = membrane()
    mem.data.materials.clear(); mem.data.materials.append(mat("M_CreatureMembrane")); mem.data.materials.append(mat("M_CreatureCartilage"))
    # cartilage/papilla/throat faces get the second material
    for p in mem.data.polygons: p.material_index = 0
    print("membrane faces", len(mem.data.polygons))
    select_only(mem); bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(70), island_margin=0.003); bpy.ops.object.mode_set(mode='OBJECT')
    for p in mem.data.polygons: p.use_smooth = True
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "listener2_mesh.blend"))
    print("SAVED mesh stage")
    return hi, lo, cl, mem

# ================================================================== bake
def skin_nodes(m, kind):
    m.use_nodes = True; nt = m.node_tree; nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputMaterial'); bsdf = nt.nodes.new('ShaderNodeBsdfPrincipled'); nt.links.new(bsdf.outputs[0], out.inputs[0])
    tc = nt.nodes.new('ShaderNodeTexCoord')
    def noise(scale, detail=6.0):
        n = nt.nodes.new('ShaderNodeTexNoise'); n.inputs['Scale'].default_value = scale; n.inputs['Detail'].default_value = detail
        nt.links.new(tc.outputs['Object'], n.inputs['Vector']); return n
    def ramp(src, c0, c1, p0=0.0, p1=1.0):
        r = nt.nodes.new('ShaderNodeValToRGB'); nt.links.new(src, r.inputs['Fac'])
        r.color_ramp.elements[0].position = p0; r.color_ramp.elements[0].color = c0
        r.color_ramp.elements[1].position = p1; r.color_ramp.elements[1].color = c1
        return r
    def mul(a, b, fac=1.0):
        m_ = nt.nodes.new('ShaderNodeMixRGB'); m_.blend_type = 'MULTIPLY'; m_.inputs['Fac'].default_value = fac
        nt.links.new(a, m_.inputs[1]); nt.links.new(b, m_.inputs[2]); return m_
    def warp(amount, scale):                # object coordinates pushed around by noise: organic, branching vein lines
        n = noise(scale, 4.0)
        sub = nt.nodes.new('ShaderNodeVectorMath'); sub.operation = 'SUBTRACT'; nt.links.new(n.outputs['Color'], sub.inputs[0]); sub.inputs[1].default_value = (0.5, 0.5, 0.5)
        sc_ = nt.nodes.new('ShaderNodeVectorMath'); sc_.operation = 'SCALE'; sc_.inputs['Scale'].default_value = amount; nt.links.new(sub.outputs['Vector'], sc_.inputs[0])
        add = nt.nodes.new('ShaderNodeVectorMath'); add.operation = 'ADD'; nt.links.new(tc.outputs['Object'], add.inputs[0]); nt.links.new(sc_.outputs['Vector'], add.inputs[1])
        return add.outputs['Vector']
    def vor(scale, c_line, width, warped=0.0):
        v = nt.nodes.new('ShaderNodeTexVoronoi'); v.feature = 'DISTANCE_TO_EDGE'; v.inputs['Scale'].default_value = scale
        nt.links.new(warp(warped, 2.5) if warped else tc.outputs['Object'], v.inputs['Vector'])
        return ramp(v.outputs['Distance'], c_line, (1, 1, 1, 1), 0.0, width)
    def dots(scale, c_dot, size):           # pores / dark spots
        v = nt.nodes.new('ShaderNodeTexVoronoi'); v.feature = 'F1'; v.inputs['Scale'].default_value = scale
        nt.links.new(tc.outputs['Object'], v.inputs['Vector'])
        return ramp(v.outputs['Distance'], c_dot, (1, 1, 1, 1), size, size + 0.07)
    def streaks(c):                          # blood that has run down the body and dried
        mp = nt.nodes.new('ShaderNodeMapping'); mp.inputs['Scale'].default_value = (9.0, 9.0, 0.7); nt.links.new(tc.outputs['Object'], mp.inputs['Vector'])
        n = nt.nodes.new('ShaderNodeTexNoise'); n.inputs['Scale'].default_value = 3.0; n.inputs['Detail'].default_value = 4.0; nt.links.new(mp.outputs['Vector'], n.inputs['Vector'])
        return ramp(n.outputs['Fac'], (1, 1, 1, 1), c, 0.6, 0.74)
    if kind == "skin":
        # v3: pale, translucent, corpse-white flesh with pink blotches, red veins and dried blood running down
        base = ramp(noise(3.0).outputs['Fac'], (0.66, 0.58, 0.53, 1), (0.86, 0.81, 0.76, 1), 0.3, 0.75)
        c = mul(base.outputs['Color'], ramp(noise(1.2, 3.0).outputs['Fac'], (0.86, 0.6, 0.58, 1), (1, 1, 1, 1), 0.35, 0.65).outputs['Color'], 1.0)
        c = mul(c.outputs['Color'], vor(4.5, (0.42, 0.04, 0.05, 1), 0.022, 0.16).outputs['Color'], 0.95)
        c = mul(c.outputs['Color'], vor(11.0, (0.62, 0.2, 0.2, 1), 0.02, 0.1).outputs['Color'], 0.8)
        c = mul(c.outputs['Color'], streaks((0.5, 0.06, 0.06, 1)).outputs['Color'], 0.9)
    elif kind == "membrane":
        # outside pale and veined like the body; inside the bell (facing forward) raw dark red with black pores
        outer = ramp(noise(5.0).outputs['Fac'], (0.7, 0.52, 0.5, 1), (0.88, 0.74, 0.7, 1), 0.3, 0.8)
        outer = mul(outer.outputs['Color'], vor(8.0, (0.45, 0.04, 0.06, 1), 0.035, 0.12).outputs['Color'], 0.95)
        inner = ramp(noise(7.0).outputs['Fac'], (0.34, 0.07, 0.07, 1), (0.6, 0.24, 0.22, 1), 0.3, 0.8)
        inner = mul(inner.outputs['Color'], dots(26.0, (0.1, 0.01, 0.015, 1), 0.08).outputs['Color'], 1.0)
        inner = mul(inner.outputs['Color'], vor(14.0, (0.3, 0.02, 0.03, 1), 0.03, 0.08).outputs['Color'], 0.8)
        geo = nt.nodes.new('ShaderNodeNewGeometry'); sep = nt.nodes.new('ShaderNodeSeparateXYZ'); nt.links.new(geo.outputs['Normal'], sep.inputs[0])
        side = ramp(sep.outputs['Y'], (0, 0, 0, 1), (1, 1, 1, 1), -0.1, 0.35)          # Blender +Y is the creature's forward
        c = nt.nodes.new('ShaderNodeMixRGB'); nt.links.new(side.outputs['Color'], c.inputs['Fac'])
        nt.links.new(outer.outputs['Color'], c.inputs[1]); nt.links.new(inner.outputs['Color'], c.inputs[2])
    elif kind == "cartilage":   # the bell's rods, lip and papillae: darker, redder flesh
        c = ramp(noise(9.0).outputs['Fac'], (0.38, 0.1, 0.09, 1), (0.62, 0.32, 0.29, 1), 0.3, 0.8)
    elif kind == "throat":
        c = ramp(noise(9.0).outputs['Fac'], (0.05, 0.005, 0.008, 1), (0.16, 0.02, 0.025, 1), 0.3, 0.8)
    else:   # claw: dark keratin
        c = ramp(noise(14.0).outputs['Fac'], (0.07, 0.055, 0.045, 1), (0.22, 0.18, 0.14, 1), 0.3, 0.8)
    nt.links.new(c.outputs['Color'], bsdf.inputs['Base Color'])

def bake_img(ob, name, size, color=True):
    img = bpy.data.images.new(name, size, size, alpha=False, float_buffer=False)
    if not color: img.colorspace_settings.name = 'Non-Color'
    for m in ob.data.materials:
        nt = m.node_tree
        for n in nt.nodes: n.select = False
        node = nt.nodes.new('ShaderNodeTexImage'); node.image = img; node.select = True; nt.nodes.active = node
    return img

def save(img, path):
    img.filepath_raw = path; img.file_format = 'PNG'; img.save(); print("BAKED", path)

def bake(hi, lo, cl, mem):
    sc = bpy.context.scene; sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'; sc.cycles.use_denoising = False
    sc.render.bake.margin = 12
    skin_nodes(lo.data.materials[0], "skin"); skin_nodes(cl.data.materials[0], "claw")
    for m in mem.data.materials:             # by name: the joined membrane carries membrane, cartilage and throat materials
        skin_nodes(m, "membrane" if m.name.startswith("membrane") else ("throat" if m.name.startswith("throat") else "cartilage"))
    sc.cycles.samples = 1
    n = bake_img(lo, "l2_normal", TEX, False)
    bpy.ops.object.select_all(action='DESELECT'); hi.select_set(True); lo.select_set(True); bpy.context.view_layer.objects.active = lo
    bpy.ops.object.bake(type='NORMAL', use_selected_to_active=True, cage_extrusion=0.012, max_ray_distance=0.035, normal_space='TANGENT')
    save(n, os.path.join(OUT, "listener2_normal.png"))
    hi.hide_render = True; hi.hide_set(True)
    for ob, tag, size in ((lo, "listener2", TEX), (cl, "claws", 1024), (mem, "membrane", MTEX)):
        select_only(ob)
        sc.cycles.samples = 1
        c = bake_img(ob, tag + "_albedo", size); bpy.ops.object.bake(type='DIFFUSE', pass_filter={'COLOR'}, use_selected_to_active=False)
        save(c, os.path.join(OUT, tag + "_albedo.png"))
        sc.cycles.samples = 24 if ob is lo else 16
        a = bake_img(ob, tag + "_ao", size, False); bpy.ops.object.bake(type='AO', use_selected_to_active=False)
        save(a, os.path.join(OUT, tag + "_ao.png"))
    bpy.data.objects.remove(hi, do_unlink=True)

# ================================================================== rig
def bone_list():
    B = [("root", None, (0, 0, 0), (0, 0.25, 0)), ("hips", "root", "pelvis", "spine1"), ("spine", "hips", "spine1", "spine2"),
         ("chest", "spine", "spine2", "chest"), ("upperchest", "chest", "chest", "upperchest"), ("neck1", "upperchest", "upperchest", "neck1"),
         ("neck2", "neck1", "neck1", "neck2"), ("head", "neck2", "neck2", "head"),
         ("mem_L", "head", "head", (0.2, 2.3, -0.5)), ("mem_R", "head", "head", (-0.22, 2.3, -0.5))]
    for s in "LR":
        B += [(f"thigh_{s}", "hips", f"hip_{s}", f"knee_{s}"), (f"shin_{s}", f"thigh_{s}", f"knee_{s}", f"ankle_{s}"),
              (f"foot_{s}", f"shin_{s}", f"ankle_{s}", f"ball_{s}"),
              (f"clav_{s}", "upperchest", f"clav_{s}", f"shoulder_{s}"), (f"upperarm_{s}", f"clav_{s}", f"shoulder_{s}", f"elbow_{s}"),
              (f"forearm_{s}", f"upperarm_{s}", f"elbow_{s}", f"wrist_{s}"), (f"hand_{s}", f"forearm_{s}", f"wrist_{s}", f"palm_{s}"),
              (f"thumb1_{s}", f"hand_{s}", f"t0_{s}", f"t1_{s}"), (f"thumb2_{s}", f"thumb1_{s}", f"t1_{s}", f"t2_{s}"), (f"thumb3_{s}", f"thumb2_{s}", f"t2_{s}", f"t3_{s}")]
        for k in range(4):
            B += [(f"fing{k}1_{s}", f"hand_{s}", f"f{k}0_{s}", f"f{k}1_{s}")] + [(f"fing{k}{j + 1}_{s}", f"fing{k}{j}_{s}", f"f{k}{j}_{s}", f"f{k}{j + 1}_{s}") for j in range(1, 4)]
            B += [(f"toe{k}1_{s}", f"foot_{s}", f"o{k}0_{s}", f"o{k}1_{s}"), (f"toe{k}2_{s}", f"toe{k}1_{s}", f"o{k}1_{s}", f"o{k}2_{s}")]
    return B

def jp(v): return G(*(J[v] if isinstance(v, str) else v))

def rig(lo, cl, mem):
    adata = bpy.data.armatures.new("ListenerRig"); arm = bpy.data.objects.new("ListenerRig", adata)
    bpy.context.scene.collection.objects.link(arm); select_only(arm)
    bpy.ops.object.mode_set(mode='EDIT'); eb = adata.edit_bones
    for name, parent, h, t in bone_list():
        b = eb.new(name); b.head = jp(h); b.tail = jp(t)
        if (b.tail - b.head).length < 0.008: b.tail = b.head + Vector((0, 0, 0.03))
        b.align_roll(Vector((0, 1, 0)))
        if parent: b.parent = eb[parent]
    bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.object.select_all(action='DESELECT'); lo.select_set(True); arm.select_set(True); bpy.context.view_layer.objects.active = arm
    bpy.ops.object.parent_set(type='ARMATURE_AUTO')
    print("body weights", len(lo.vertex_groups))
    # bone heat leaves detached islands (skull nodules, the crown) unweighted, and unweighted vertices stay behind at
    # their rest position when the body bends: give each one to the nearest bone
    segs = [(b.name, arm.matrix_world @ b.head_local, arm.matrix_world @ b.tail_local) for b in arm.data.bones if b.use_deform]
    def nearest(p):
        best, bd = None, 1e9
        for n, h, t in segs:
            ab = t - h; k = max(0.0, min(1.0, (p - h).dot(ab) / max(1e-9, ab.dot(ab)))); d = (p - (h + ab * k)).length
            if d < bd: best, bd = n, d
        return best
    orphans = 0
    for v in lo.data.vertices:
        if sum(g.weight for g in v.groups) < 1e-4:
            n = nearest(lo.matrix_world @ v.co)
            (lo.vertex_groups.get(n) or lo.vertex_groups.new(name=n)).add([v.index], 1.0, 'REPLACE'); orphans += 1
    print("orphan vertices given to their nearest bone:", orphans)
    # claws ride rigidly on their nearest finger/toe tip bone
    tips = {}
    for s in "LR":
        for k in range(4): tips[f"fing{k}4_{s}"] = Vector(jp(f"f{k}4_{s}")); tips[f"toe{k}2_{s}"] = Vector(jp(f"o{k}2_{s}"))
        tips[f"thumb3_{s}"] = Vector(jp(f"t3_{s}"))
    groups = {n: cl.vertex_groups.new(name=n) for n in tips}
    for v in cl.data.vertices:
        p = cl.matrix_world @ v.co
        best = min(tips, key=lambda n: (tips[n] - p).length)
        groups[best].add([v.index], 1.0, 'REPLACE')
    md = cl.modifiers.new("arm", 'ARMATURE'); md.object = arm; cl.parent = arm
    # membrane: head + flaring lobes (weight grows with distance from the stalk)
    gh = mem.vertex_groups.new(name="head"); gl = mem.vertex_groups.new(name="mem_L"); gr = mem.vertex_groups.new(name="mem_R")
    c = Vector(jp(tuple(MC)))
    for v in mem.data.vertices:
        p = mem.matrix_world @ v.co; d = (p - c).length; f = min(1.0, max(0.0, (d - 0.08) / 0.26))
        gh.add([v.index], 1.0 - f, 'REPLACE')
        (gl if p.x >= c.x else gr).add([v.index], f, 'REPLACE')
    md = mem.modifiers.new("arm", 'ARMATURE'); md.object = arm; mem.parent = arm
    return arm

# ================================================================== animation
def animate(arm):
    sc = bpy.context.scene; sc.render.fps = 30
    arm.animation_data_create(); pb = arm.pose.bones
    for p in pb: p.rotation_mode = 'XYZ'
    S = math.sin; C = math.cos; TAU = 2 * math.pi
    def reset_pose():
        for p in pb: p.rotation_euler = (0, 0, 0); p.location = (0, 0, 0)
    def make(name, frames, fn, step=2):
        act = bpy.data.actions.new(name); arm.animation_data.action = act
        for f in list(range(0, frames, step)) + [frames]:
            reset_pose(); fn(f / frames)
            for p in pb:
                p.keyframe_insert("rotation_euler", frame=f)
                if p.name in ("root", "hips"): p.keyframe_insert("location", frame=f)
        tr = arm.animation_data.nla_tracks.new(); tr.name = name; tr.strips.new(name, 0, act); arm.animation_data.action = None
        print("ACTION", name, frames)
    def fingers(t, curl, twitch=0.0, side=None):
        for s in ([side] if side else "LR"):
            for k in range(4):
                for j in range(1, 5):
                    pb[f"fing{k}{j}_{s}"].rotation_euler.x = curl * (0.6 + 0.2 * j) + twitch * S(TAU * t * 3 + k * 1.3 + j)
            for j in (1, 2, 3): pb[f"thumb{j}_{s}"].rotation_euler.x = curl * 0.5
    def membrane_flare(a):
        pb["mem_L"].rotation_euler.z = -a; pb["mem_R"].rotation_euler.z = a
    def legs(t, amp, lift, lean, drag=0.6):
        for s, ph in (("L", 0.0), ("R", 0.5)):
            a = TAU * (t + ph); amp_s = amp * (1.0 if s == "L" else drag)
            pb[f"thigh_{s}"].rotation_euler.x = amp_s * S(a) + lean * 0.5
            pb[f"shin_{s}"].rotation_euler.x = -lift * (1.0 if s == "L" else drag) * max(0.0, S(a + 1.2)) - 0.12
            pb[f"foot_{s}"].rotation_euler.x = 0.3 * max(0.0, -S(a)) * lift
    def arms(t, amp, raise_=0.0):
        for s, ph in (("L", 0.5), ("R", 0.0)):
            a = TAU * (t + ph)
            pb[f"upperarm_{s}"].rotation_euler.x = amp * S(a) + raise_
            pb[f"forearm_{s}"].rotation_euler.x = 0.18 + 0.22 * max(0.0, S(a)) + raise_ * 0.6
    def hunch(k=1.0, arms=True):
        # the new reference's posture: the upper body folds forward from the spine (the legs hang from the hips, not the
        # spine, so the feet stay planted), the neck lifts the funnel back to face forward and the arms hang to the floor
        pb["spine"].rotation_euler.x += 0.38 * k; pb["chest"].rotation_euler.x += 0.27 * k; pb["upperchest"].rotation_euler.x += 0.16 * k
        pb["neck1"].rotation_euler.x += -0.47 * k; pb["neck2"].rotation_euler.x += -0.15 * k
        if arms:
            for s in "LR": pb[f"upperarm_{s}"].rotation_euler.x += 0.93 * k
    def stance(k=1.0):
        # bent knees with the feet planted (forward-kinematics check: ankles 12 cm, toes 5 cm off the floor), hips 30 cm lower
        pb["root"].location.y += -0.27 * k
        for s in "LR":
            pb[f"thigh_{s}"].rotation_euler.x += 0.386 * k; pb[f"shin_{s}"].rotation_euler.x += -0.952 * k; pb[f"foot_{s}"].rotation_euler.x += 0.792 * k
    def idle(t):
        b = S(TAU * t)
        pb["chest"].rotation_euler.x = 0.03 * b; pb["upperchest"].rotation_euler.x = 0.025 * b
        pb["hips"].rotation_euler.z = 0.03 * S(TAU * t * 0.5)
        pb["neck1"].rotation_euler.y = 0.15 * S(TAU * t + 0.6); pb["head"].rotation_euler.z = 0.1 * S(TAU * t * 2.0)
        membrane_flare(0.06 + 0.05 * S(TAU * t * 2))
        fingers(t, 0.14, 0.07)
        stance(1.0); hunch(1.0)
    def listen(t):
        pb["spine"].rotation_euler.x = 0.1; pb["chest"].rotation_euler.x = 0.08
        pb["neck1"].rotation_euler.y = 0.5 * S(TAU * t); pb["neck2"].rotation_euler.x = 0.18 * S(2 * TAU * t)
        pb["head"].rotation_euler.z = 0.3 * S(TAU * t + 1.0)
        membrane_flare(0.32 + 0.12 * S(TAU * t * 3))           # spreads wide while it listens
        pb["upperarm_L"].rotation_euler.x = 0.45; pb["forearm_L"].rotation_euler.x = 0.9
        fingers(t, 0.08, 0.15, "L"); fingers(t, 0.15, 0.06, "R")
        stance(0.8); hunch(0.9)
    def walk(t):
        legs(t, 0.4, 0.55, 0.12, drag=0.55); arms(t, 0.18)
        pb["root"].location.y = 0.028 * C(2 * TAU * t)
        pb["chest"].rotation_euler.z = 0.08 * S(TAU * t); pb["hips"].rotation_euler.z = -0.06 * S(TAU * t)
        pb["neck1"].rotation_euler.x = 0.05 * S(2 * TAU * t); pb["head"].rotation_euler.z = 0.12 * S(TAU * t * 0.5)
        membrane_flare(0.1); fingers(t, 0.1, 0.05)
        hunch(0.8)
    def run(t):
        legs(t, 0.85, 1.25, 0.4, drag=0.8); arms(t, 0.6, 0.35)
        pb["root"].location.y = 0.05 * C(2 * TAU * t)
        pb["hips"].rotation_euler.x = 0.32; pb["spine"].rotation_euler.x = 0.2; pb["chest"].rotation_euler.z = 0.12 * S(TAU * t)
        pb["neck1"].rotation_euler.x = -0.35; pb["head"].rotation_euler.x = -0.15
        membrane_flare(-0.12); fingers(t, 0.04, 0.1)
        hunch(0.5)
    def search(t):
        stance(1.0); hunch(1.1)
        pb["neck1"].rotation_euler.y = 0.7 * S(TAU * t); pb["head"].rotation_euler.x = 0.2 + 0.1 * S(2 * TAU * t)
        pb["upperarm_R"].rotation_euler.x += 0.3 + 0.25 * S(TAU * t); pb["forearm_R"].rotation_euler.x = 0.4
        fingers(t, -0.05, 0.18, "R"); fingers(t, 0.15, 0.06, "L")
        membrane_flare(0.25 + 0.1 * S(TAU * t * 2))
    def crawl(t):
        # low vent crawl on the knees and planted hands, diagonal gait. Designed with a sagittal forward-kinematics check of
        # this rig (the hip pitch also swings the thighs back, so the thighs must rotate forward to stay under the body):
        # knees 5-9 cm and planted palms 3-7 cm off the floor through the cycle; hands lift ~30 cm when they reach forward.
        pb["root"].location.y = -0.551 + 0.02 * C(2 * TAU * t)
        pb["hips"].rotation_euler.x = 1.05; pb["spine"].rotation_euler.x = 0.16; pb["chest"].rotation_euler.x = 0.035
        pb["neck1"].rotation_euler.x = -0.88; pb["neck2"].rotation_euler.x = -0.42
        pb["hips"].rotation_euler.z = 0.05 * S(TAU * t); pb["chest"].rotation_euler.z = -0.06 * S(TAU * t)
        pb["head"].rotation_euler.z = 0.12 * S(TAU * t * 0.5)
        for s, ph in (("L", 0.0), ("R", 0.5)):
            a = TAU * (t + ph); b = a + math.pi                   # each leg moves with the opposite arm
            pb[f"upperarm_{s}"].rotation_euler.x = 1.53 + 0.22 * S(a)
            pb[f"forearm_{s}"].rotation_euler.x = 0.92 - 0.24 * S(a) + 0.45 * max(0.0, C(a))
            pb[f"hand_{s}"].rotation_euler.x = -0.12
            pb[f"thigh_{s}"].rotation_euler.x = 0.79 + 0.16 * S(b)
            pb[f"shin_{s}"].rotation_euler.x = -1.10 - 0.14 * S(b) - 0.35 * max(0.0, C(b))
            pb[f"foot_{s}"].rotation_euler.x = -0.59
        fingers(t, -0.12, 0.08); membrane_flare(-0.05 + 0.04 * S(TAU * t))
    def attack(t):
        w = min(1.0, t / 0.35); st = max(0.0, min(1.0, (t - 0.35) / 0.15)); rc = max(0.0, (t - 0.6) / 0.4)
        k = w * (1 - st); reach = st * (1 - rc)
        pb["spine"].rotation_euler.x = -0.25 * k + 0.45 * reach; pb["chest"].rotation_euler.x = -0.2 * k + 0.35 * reach
        pb["neck1"].rotation_euler.x = -0.3 * k + 0.2 * reach
        for s in "LR":
            pb[f"upperarm_{s}"].rotation_euler.x = 1.2 * k + 1.6 * reach; pb[f"forearm_{s}"].rotation_euler.x = 0.9 * k + 0.1 * reach
        fingers(t, 0.5 * k - 0.35 * reach, 0.0)
        membrane_flare(0.45 * k + 0.2 * reach)
        legs(0.25, 0.3 * reach, 0.4, 0.2)
    make("idle", 90, idle, 3); make("listen", 75, listen, 3); make("walk", 42, walk); make("run", 23, run, 1)
    make("search", 90, search, 3); make("crawl", 48, crawl, 2); make("attack", 30, attack, 1)

def lods(lo):
    out = [lo]
    for i, ratio in ((1, 0.38), (2, 0.14)):
        c = lo.copy(); c.data = lo.data.copy(); c.name = f"ListenerBody_LOD{i}"
        bpy.context.scene.collection.objects.link(c)
        for m in list(c.modifiers):
            if m.type != 'ARMATURE': c.modifiers.remove(m)
        dec = c.modifiers.new("dec", 'DECIMATE'); dec.ratio = ratio
        select_only(c)
        with bpy.context.temp_override(object=c):
            bpy.ops.object.modifier_move_to_index(modifier="dec", index=0)
            bpy.ops.object.modifier_apply(modifier="dec")
        print(f"LOD{i} faces", len(c.data.polygons)); out.append(c)
    lo.name = "ListenerBody_LOD0"
    return out

def export_listener():
    names = ["ListenerRig", "ListenerMembrane", "ListenerBody_LOD0", "ListenerBody_LOD1", "ListenerBody_LOD2"]
    for o in bpy.context.scene.objects: o.select_set(o.name in names)
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "listener2.gltf"), export_format='GLTF_SEPARATE', use_selection=True,
        export_image_format='NONE', export_animations=True, export_animation_mode='NLA_TRACKS', export_skins=True, export_def_bones=False)
    print("EXPORTED listener2")

if STAGE in ("mesh", "all"):
    hi, lo, cl, mem = build()
if STAGE == "mesh":
    for o in bpy.context.scene.objects: o.select_set(o.name in ("body_lo", "claws", "membrane"))
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "listener2_preview.gltf"), export_format='GLTF_SEPARATE', use_selection=True, export_image_format='NONE')
    print("EXPORTED preview")
if STAGE == "all":
    bake(hi, lo, cl, mem)
    arm = rig(lo, cl, mem)
    animate(arm)
    # join the claws into each LOD so every LOD keeps them
    select_only(lo); cl.select_set(True); bpy.context.view_layer.objects.active = lo; bpy.ops.object.join()
    lo = bpy.context.view_layer.objects.active
    allm = lods(lo)
    mem.name = "ListenerMembrane"
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "listener2_rigged.blend"))
    export_listener()
if STAGE == "anim":
    # re-key every animation on the saved rig and re-export: meshes, UVs, weights and baked maps stay exactly as they are
    bpy.ops.wm.open_mainfile(filepath=os.path.join(OUT, "listener2_rigged.blend"))
    arm = bpy.data.objects["ListenerRig"]
    for tr in list(arm.animation_data.nla_tracks): arm.animation_data.nla_tracks.remove(tr)
    for act in list(bpy.data.actions): bpy.data.actions.remove(act)
    animate(arm)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "listener2_rigged.blend"))
    export_listener()
