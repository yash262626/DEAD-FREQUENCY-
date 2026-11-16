"""The Listener (production model for Unreal Engine 5.8) - Blender stage runner.

    xvfb-run -a blender -b --factory-startup -noaudio --python tools/blender/ue/listener4.py -- <stage> [args]

Stages (each reads the previous stage's output from tools/blender/work/ue/listener/):
    body [h]          anatomy signed-distance field -> high-resolution body mesh (npz) + rig landmarks (json)
    head              the membrane horn: game-resolution shell and the relief-detailed bake source (npz)
    preview_body      clay renders of the body from several angles (anatomy review)
    preview_full      body + head together, clay
    retopo [faces]    quad game mesh of the body (QuadriFlow on a voxel-cleaned copy, projected onto the sculpt)
    uv                anatomical seams, unwrap, pack (body texture set); the head unwraps from its own seam
    details           claws (game + bake), veins grown over the skin, dried-blood runs (npz)
    assemble          game meshes (body + claws, head) with UVs and materials; bake sources -> listener_bake.blend
    rig               Unreal-style skeleton, body skin weights (bone heat, claws rigid), membrane weights
    rigtest           deformation test poses (clay renders)
    anim [names]      the animation set as actions; contact sheets
    bake [size]       Cycles bakes: normal, AO, thickness, curvature source, position, part id, vein/blood masks
    textures [size]   compose the final PBR maps (Unreal naming) into SourceArt/Characters/Listener/Textures
    lookdev [pose]    textured renders (Blender materials built from the Unreal maps); pose = rest | stance
"""
import json
import os
import sys
import time

import bpy
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import bl_util as U  # noqa: E402
import sdf  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
WORK = os.path.join(ROOT, "tools", "blender", "work", "ue", "listener")
os.makedirs(WORK, exist_ok=True)


def log(*a):
    print("[listener4]", *a, flush=True)


def jsonable(d):
    return {k: (v.tolist() if hasattr(v, "tolist") else v) for k, v in d.items()}


# ------------------------------------------------------------------------------------------------ body

def stage_body(h="0.25"):
    import listener_body as B
    t = time.time()
    g = B.build(float(h), log=log)
    log("field %.1fs" % (time.time() - t))
    t = time.time()
    v, q = sdf.surface_nets(g)
    log("surface nets: %d verts, %d quads, volume %.0f cm3 (%.1fs)" % (len(v), len(q), sdf.mesh_volume(v, q), time.time() - t))
    sdf.save_npz(os.path.join(WORK, "body_hi.npz"), v, q)
    claws = [[c[0].tolist(), c[1].tolist(), c[2], c[3], np.asarray(c[4]).tolist()] for c in B.CLAWS]
    with open(os.path.join(WORK, "rig_landmarks.json"), "w") as f:
        json.dump({"joints": jsonable(B.JOINTS), "claws": claws, "h": float(h)}, f, indent=1)


def stage_head():
    import listener_body as B
    import listener_head as H
    lm = json.load(open(os.path.join(WORK, "rig_landmarks.json")))
    neck_fwd = np.array([0.0, -0.95, -0.31])
    horn = H.default_horn(lm["joints"]["head"], neck_fwd)
    out = {}
    for tag, res in (("lo", (64, 26, 4, 6)), ("hi", (384, 160, 10, 16))):
        V, Q, T, th, u, lay = horn.build(*res)
        if tag == "hi":
            V, veins = H.relief(V, th, u, lay, horn)
            out["veins"] = veins
        np.savez_compressed(os.path.join(WORK, "head_%s.npz" % tag), verts=V.astype(np.float32), quads=Q.astype(np.int32),
                            tris=T.astype(np.int32), theta=th.astype(np.float32), u=u.astype(np.float32),
                            layer=lay.astype(np.int8), **({"veins": out["veins"].astype(np.float32)} if tag == "hi" else {}))
        log("head %s: %d verts, %d quads" % (tag, len(V), len(Q)))
    with open(os.path.join(WORK, "head_frame.json"), "w") as f:
        json.dump({"base": horn.base.tolist(), "D": horn.D.tolist(), "U": horn.U.tolist(), "S": horn.S.tolist(),
                   "L": horn.L, "r0": horn.r0, "r1": horn.r1, "bend": horn.bend, "struts": H.STRUTS}, f, indent=1)


def load_head(tag="hi", name=None):
    d = np.load(os.path.join(WORK, "head_%s.npz" % tag))
    ob = U.mesh_from_numpy(name or ("Listener_Head_" + tag), d["verts"], [d["quads"], d["tris"]])
    U.shade_smooth(ob)
    return ob, d


def load_body(name="Listener_Body_hi"):
    d = np.load(os.path.join(WORK, "body_hi.npz"))
    ob = U.mesh_from_numpy(name, d["verts"], d["faces"])
    U.shade_smooth(ob)
    return ob


VIEWS = {   # name: (camera location offset from target, target, lens)
    "front": ((0, -470, 10), (0, 0, 110), 50),
    "side": ((470, 0, 10), (0, 0, 110), 50),
    "back": ((0, 470, 10), (0, 0, 110), 50),
    "q34": ((-330, -340, 50), (0, 0, 110), 50),
    "torso": ((-120, -190, 20), (0, -2, 160), 50),
    "back_close": ((90, 200, 30), (0, 8, 160), 50),
    "hand": ((60, -70, 15), (79, -18, 83), 50),
    "foot": ((40, -75, 35), (11, -5, 6), 50),
    "neck": ((-70, -110, 10), (0, 0, 190), 50),
    "legs": ((-160, -260, -20), (0, 0, 60), 50),
    "headq": ((-150, -170, 40), (2, -20, 222), 50),
}


def stage_preview_full(views="front,side,back,q34,headq,torso,back_close,hand,neck,legs"):
    stage_preview_body(views, with_head=True, prefix="full")


def stage_preview_body(views="front,side,back,q34,torso,back_close,hand,neck,foot,legs", with_head=False, prefix="body"):
    sc = U.reset_scene()
    ob = load_body()
    clay = U.principled("Clay", (0.58, 0.55, 0.53), rough=0.55, sss=0.05, sss_radius=(1.0, 0.5, 0.35))
    ob.data.materials.append(clay)
    if with_head:
        hd, _ = load_head("hi")
        hd.data.materials.append(clay)
    U.floor(0.0)
    U.studio((0, 0, 130 if with_head else 115), radius=480, key=0.32)
    U.eevee((1200, 1600), samples=48)
    out = []
    for name in views.split(","):
        off, tgt, lens = VIEWS[name]
        cam = U.camera("cam_" + name, tuple(np.add(tgt, off)), tgt, lens=lens)
        if name in ("hand", "foot", "torso", "back_close", "neck", "legs", "headq"):
            sc.render.resolution_x, sc.render.resolution_y = 1400, 1050
        else:
            sc.render.resolution_x, sc.render.resolution_y = 1050, 1400
        p = os.path.join(WORK, "prev_%s_%s.png" % (prefix, name))
        U.render(p, cam)
        out.append(p)
        log("rendered", name)
    full = [p for p in out if p.endswith(("front.png", "side.png", "back.png", "q34.png"))]
    U.contact_sheet([p for p in out if p.endswith(("front.png", "side.png", "back.png", "q34.png"))],
                    os.path.join(WORK, "sheet_%s_full.jpg" % prefix), 4, thumb=(600, 800),
                    labels=["front", "side", "back", "three-quarter"])
    rest = [p for p in out if p not in full]
    if rest:
        U.contact_sheet(rest, os.path.join(WORK, "sheet_%s_detail.jpg" % prefix), 3, thumb=(700, 525),
                        labels=[os.path.basename(p)[6 + len(prefix):-4] for p in rest])


def stage_details(seed="43"):
    """Claws, veins and blood runs, grown on the sculpt's surface."""
    import listener_detail as LD
    from mathutils.bvhtree import BVHTree
    rng = np.random.default_rng(int(seed))
    lm = json.load(open(os.path.join(WORK, "rig_landmarks.json")))
    J = {k: np.asarray(v, float) for k, v in lm["joints"].items()}
    claws = [(np.array(c[0]), np.array(c[1]), c[2], c[3], np.array(c[4])) for c in lm["claws"]]
    for tag, ns, nl, ridges in (("lo", 8, 7, False), ("hi", 24, 30, True)):
        V, Q, T, ID = LD.claws_mesh(claws, ns, nl, ridges)
        np.savez_compressed(os.path.join(WORK, "claws_%s.npz" % tag), verts=V.astype(np.float32), quads=Q.astype(np.int32),
                            tris=T.astype(np.int32), claw=ID.astype(np.int16))
        log("claws %s: %d verts" % (tag, len(V)))
    d = np.load(os.path.join(WORK, "body_hi.npz"))
    bvh = BVHTree.FromPolygons([tuple(map(float, v)) for v in d["verts"]], d["faces"].tolist())
    veins = []     # (points, radii, depth) depth: 0 raised, 1 deep (colour only)

    def add_walk(start, goal, length, r0, r1, depth, wander=0.35, branch=0.03, gen=0, stop=None):
        pts, nrm = LD.walk_surface(bvh, start, goal, length, step=0.6, wander=wander, rng=rng, stop=stop)
        if len(pts) < 4:
            return
        k = len(pts)
        rad = np.linspace(r0, r1, k) * (1 + 0.15 * np.sin(np.linspace(0, rng.uniform(4, 9), k)))
        sink = -0.45 if depth == 0 else -1.35
        veins.append((pts + nrm * (rad * sink)[:, None], rad, depth))
        if gen < 2:
            for i in range(3, k - 3):
                if rng.random() < branch:
                    side = np.cross(nrm[i], pts[i + 1] - pts[i])
                    g = goal(pts[i]) if callable(goal) else np.asarray(goal, float)
                    add_walk(pts[i], g + side * rng.choice([-1, 1]) * rng.uniform(0.6, 1.4), length * rng.uniform(0.15, 0.4),
                             rad[i] * 0.7, rad[i] * 0.35, depth, wander * 1.2, branch * 0.6, gen + 1, stop)

    def toward(target):
        target = np.asarray(target, float)
        return lambda p: (target - p) / max(np.linalg.norm(target - p), 1e-6)

    for s in "lr":
        sx = 1 if s == "l" else -1
        wr, el, sh = J["hand_" + s], J["lowerarm_" + s], J["upperarm_" + s]
        a, t, n = np.asarray(lm["joints"]["hand_axes_" + s], float)
        for i in range(5):                                    # back of the hand
            st = wr + a * rng.uniform(4, 10) + t * rng.uniform(-2.5, 2.5) - n * 1.5
            add_walk(st, toward(el), rng.uniform(10, 18), 0.12, 0.16, 0)
        fwd_side = t
        add_walk(wr + fwd_side * 1.6, toward(el + fwd_side * 1.5), 42, 0.17, 0.21, 0, branch=0.05)   # cephalic
        add_walk(wr - fwd_side * 1.6, toward(el - fwd_side * 1.2), 42, 0.16, 0.2, 0, branch=0.05)    # basilic
        add_walk(el + fwd_side * 1.0, toward(sh + np.array([0, -3.0, 0])), 38, 0.18, 0.22, 0, branch=0.04)
        add_walk(el - fwd_side * 0.6, toward(sh), 34, 0.38, 0.42, 1, branch=0.02)
        for i in range(3):
            add_walk(el + rng.normal(0, 2.0, 3), toward(wr), rng.uniform(15, 30), 0.22, 0.18, 1)
        th, kn, an = J["thigh_" + s], J["calf_" + s], J["foot_" + s]
        inner = np.array([-sx, 0, 0])
        add_walk(an + inner * 2.2 + np.array([0, -0.8, 1.0]), toward(kn + inner * 4.0), 58, 0.18, 0.22, 0, branch=0.04)  # saphenous
        add_walk(kn + inner * 4.5, toward(th + inner * 3.0 + np.array([0, -3, 0])), 55, 0.2, 0.23, 0, branch=0.04)
        add_walk(an + np.array([sx * 2.0, 2.0, 2.0]), toward(kn + np.array([0, 4.0, 0])), 50, 0.15, 0.19, 0, branch=0.04)
        for i in range(4):
            add_walk(J["ball_" + s] + np.array([sx * rng.uniform(-2, 2), 0, 1.5]), toward(an), 12, 0.11, 0.14, 0)
        for i in range(3):
            add_walk(kn + rng.normal(0, 3, 3), toward(th), rng.uniform(25, 45), 0.4, 0.42, 1)
        add_walk(th + np.array([sx * 3, -5, 4]), toward(J["upperarm_" + s] + np.array([-sx * 3, 0, -8])), 60, 0.13, 0.16, 0, branch=0.05)
        # neck: external jugular and the veins that feed the membrane
        hb = J["head"]
        add_walk(hb + np.array([sx * 3.5, 0.5, -2]), toward(J["clavicle_" + s] + np.array([sx * 6, 0, 0])), 26, 0.2, 0.24, 0, branch=0.06)
    for i in range(16):
        ang = rng.uniform(0, 2 * np.pi)
        st = J["head"] + np.array([np.cos(ang) * 4.5, np.sin(ang) * 4.5 - 0.5, 1.0])
        add_walk(st, np.array([0, 0, -1.0]), rng.uniform(8, 22), 0.16, 0.08, 0, wander=0.5, branch=0.08)
    for i in range(10):                                       # faint deep veins over the chest and belly
        st = np.array([rng.uniform(-9, 9), -6, rng.uniform(140, 172)])
        add_walk(st, np.array([np.sign(st[0]) * 1.0, 0.3, rng.uniform(-0.5, 0.6)]), rng.uniform(12, 26), 0.3, 0.2, 1, branch=0.06)
    # dried blood: runs from the membrane root down the throat and chest; smears on the hands
    blood = []
    for i in range(14):
        st = J["head"] + np.array([rng.normal(0, 2.5), -3.5, rng.uniform(-2, 1)])
        pts, nrm = LD.walk_surface(bvh, st, np.array([0, 0, -1.0]), rng.uniform(10, 45), step=0.6, wander=0.18, rng=rng)
        if len(pts) > 4:
            k = len(pts)
            blood.append((pts + nrm * 0.02, np.linspace(rng.uniform(0.35, 0.7), 0.15, k), 2))
    for s in "lr":
        a, t, n = np.asarray(lm["joints"]["hand_axes_" + s], float)
        for f in ("index", "middle", "ring", "pinky"):
            tip = J["%s_tip_%s" % (f, s)]
            pts, nrm = LD.walk_surface(bvh, tip - a * 1.0, -a, rng.uniform(6, 16), step=0.5, wander=0.3, rng=rng)
            if len(pts) > 4:
                blood.append((pts + nrm * 0.02, np.linspace(0.45, 0.2, len(pts)), 2))
    all_paths = veins + blood
    V, Q = LD.tubes_mesh([(p, r) for p, r, _ in all_paths], n_side=6)
    kind = np.concatenate([np.full(len(p) * 6, dep) for p, r, dep in all_paths if len(p) >= 2])
    np.savez_compressed(os.path.join(WORK, "veins_hi.npz"), verts=V.astype(np.float32), quads=Q.astype(np.int32),
                        kind=kind.astype(np.int8))
    log("veins %d (raised %d, deep %d), blood runs %d: %d verts" % (len(veins), sum(1 for v in veins if v[2] == 0),
        sum(1 for v in veins if v[2] == 1), len(blood), len(V)))


def head_uv_seams(ob, d):
    """Head shell seams: one radial cut on the underside through every layer, and a ring at the middle of the
    rolled lip, so the outer skin and the inner skin unwrap as two islands."""
    th, u, lay = d["theta"], d["u"], d["layer"]
    n_theta = len(np.unique(np.round(th[:-1], 6)))          # the last vertex is the gullet tip
    E = mesh_edges(ob)
    a, b = E[:, 0], E[:, 1]
    k = np.round(th / (2 * np.pi) * n_theta).astype(int) % n_theta
    k_seam = n_theta // 2                                   # theta = pi: the underside of the horn
    radial = ((k[a] == k_seam) & (k[b] == k_seam)) | ((k[a] == 0) & (k[b] == 0))
    lip_rows = np.nonzero(lay == 1)[0]
    rows = np.arange(len(th)) // n_theta
    lip_r = np.unique(rows[lip_rows])
    mid = lip_r[len(lip_r) // 2]
    ring = (rows[a] == mid) & (rows[b] == mid)
    seam = radial | ring
    ob.data.edges.foreach_set("use_seam", seam)
    return seam


def link_npz(name, path, faces_keys=("quads", "tris", "faces"), coll=None):
    d = np.load(path)
    faces = [d[k] for k in faces_keys if k in d and len(d[k])]
    ob = U.mesh_from_numpy(name, d["verts"], faces if len(faces) > 1 else faces[0], coll)
    U.shade_smooth(ob)
    return ob, d


def stage_assemble():
    """One file with the game meshes (UV-mapped, two texture sets) and every bake source."""
    bpy.ops.wm.open_mainfile(filepath=os.path.join(WORK, "body_uv.blend"))
    body = bpy.data.objects["Listener_Body"]
    claws, _ = link_npz("Listener_Claws", os.path.join(WORK, "claws_lo.npz"))
    select_only(claws)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=1.15, island_margin=0.02)
    bpy.ops.object.mode_set(mode="OBJECT")
    # body + claws share the Body texture set: join, then re-pack every island together
    m_skin = U.principled("M_Listener_Skin", (0.75, 0.7, 0.66), rough=0.45, sss=0.3)
    m_claw = U.principled("M_Listener_Claws", (0.35, 0.3, 0.22), rough=0.35)
    body.data.materials.clear()
    body.data.materials.append(m_skin)
    claws.data.materials.append(m_claw)
    for o in bpy.context.scene.objects:
        o.select_set(o in (body, claws))
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.join()
    claw_faces = np.array([p.material_index == 1 for p in body.data.polygons])
    log("body + claws: %d faces (%d claw faces)" % (len(claw_faces), claw_faces.sum()))
    part = body.data.attributes["part"]
    vals = np.empty(len(body.data.vertices), np.int32)
    part.data.foreach_get("value", vals)
    for p in body.data.polygons:
        if p.material_index == 1:
            vals[list(p.vertices)] = 20                     # claws: their own texture region
    part.data.foreach_set("value", vals)
    select_only(body)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.average_islands_scale()
    pack(0.003)
    bpy.ops.object.mode_set(mode="OBJECT")
    # head (its own texture set)
    head, hd = link_npz("Listener_Head", os.path.join(WORK, "head_lo.npz"))
    head_uv_seams(head, hd)
    head.data.materials.append(U.principled("M_Listener_Membrane", (0.6, 0.3, 0.3), rough=0.3, sss=0.5))
    unwrap(head)
    import listener_head as H
    at = head.data.attributes.new("bake_attrs", "FLOAT_COLOR", "POINT")
    cols = np.stack([hd["layer"] / 3.0, np.clip(hd["u"], 0, 1), H.strut_field(hd["theta"], 0.05),
                     np.ones(len(hd["u"]))], axis=1).astype(np.float32)
    at.data.foreach_set("color", cols.reshape(-1))
    uv_layout_png(head, os.path.join(WORK, "uv_head.png"), 1600, None)
    log("head uv coverage %.1f%%" % (100 * uv_coverage(head)))
    # game meshes are triangulated once, here: the bake and the export use the same triangles (tangent space)
    keep = bpy.data.collections.new("Source_Quads")
    bpy.context.scene.collection.children.link(keep)
    for ob in (body, head):
        q = ob.copy()
        q.data = ob.data.copy()
        q.name = ob.name + "_quads"
        keep.objects.link(q)
        q.hide_render = True
        tri = ob.modifiers.new("tri", "TRIANGULATE")
        tri.quad_method = "FIXED"
        tri.ngon_method = "BEAUTY"
        select_only(ob)
        bpy.ops.object.modifier_apply(modifier="tri")
        log("%s: %d triangles" % (ob.name, len(ob.data.polygons)))
    # bake sources in their own collection
    src = bpy.data.collections.new("BakeSources")
    bpy.context.scene.collection.children.link(src)
    for name, path in (("hi_body", "body_hi.npz"), ("hi_claws", "claws_hi.npz"), ("hi_head", "head_hi.npz")):
        ob, _ = link_npz(name, os.path.join(WORK, path), coll=src)
    vd = np.load(os.path.join(WORK, "veins_hi.npz"))
    kinds = vd["kind"]
    for k, name in ((0, "hi_veins_raised"), (1, "hi_veins_deep"), (2, "hi_blood")):
        keep_v = kinds == k
        remap = np.cumsum(keep_v) - 1
        q = vd["quads"]
        qk = q[keep_v[q[:, 0]]]
        ob = U.mesh_from_numpy(name, vd["verts"][keep_v], remap[qk], src)
        U.shade_smooth(ob)
    for ob in (body, head):
        stats(ob)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(WORK, "listener_bake.blend"), compress=True)


# ------------------------------------------------------------------------------------------------ baking

BAKE = os.path.join(WORK, "bake")


def node_mat(name, build):
    """Material whose node tree is built by build(nodes, links, out_node)."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    build(nt.nodes, nt.links, out)
    return m


def emit_mat(name, socket_fn):
    def build(nodes, links, out):
        em = nodes.new("ShaderNodeEmission")
        links.new(socket_fn(nodes, links), em.inputs["Color"])
        links.new(em.outputs[0], out.inputs["Surface"])
    return node_mat(name, build)


def skin_detail_mat(name, pores=7.0, wrinkle=1.4, strength=0.22):
    """High-poly skin for the normal bake: pores and fine creases as bump (Cycles bakes the shading normal)."""
    def build(nodes, links, out):
        tc = nodes.new("ShaderNodeTexCoord")
        vor = nodes.new("ShaderNodeTexVoronoi")
        vor.feature = "F1"
        vor.inputs["Scale"].default_value = pores
        vor.inputs["Randomness"].default_value = 0.9
        noi = nodes.new("ShaderNodeTexNoise")
        noi.inputs["Scale"].default_value = wrinkle
        noi.inputs["Detail"].default_value = 10.0
        noi.inputs["Roughness"].default_value = 0.62
        noi.inputs["Distortion"].default_value = 0.6
        fine = nodes.new("ShaderNodeTexNoise")
        fine.inputs["Scale"].default_value = 9.0
        fine.inputs["Detail"].default_value = 6.0
        for t in (vor, noi, fine):
            links.new(tc.outputs["Object"], t.inputs["Vector"])
        pore = nodes.new("ShaderNodeMapRange")
        pore.inputs["From Min"].default_value = 0.0
        pore.inputs["From Max"].default_value = 0.22
        pore.inputs["To Min"].default_value = -1.0
        pore.inputs["To Max"].default_value = 0.0
        links.new(vor.outputs["Distance"], pore.inputs["Value"])
        mix = nodes.new("ShaderNodeMath")
        mix.operation = "MULTIPLY_ADD"
        links.new(noi.outputs["Fac"], mix.inputs[0])
        mix.inputs[1].default_value = 1.2
        links.new(pore.outputs["Result"], mix.inputs[2])
        add = nodes.new("ShaderNodeMath")
        add.operation = "MULTIPLY_ADD"
        links.new(fine.outputs["Fac"], add.inputs[0])
        add.inputs[1].default_value = 0.35
        links.new(mix.outputs[0], add.inputs[2])
        bump = nodes.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = strength
        bump.inputs["Distance"].default_value = 0.06
        links.new(add.outputs[0], bump.inputs["Height"])
        bsdf = nodes.new("ShaderNodeBsdfPrincipled")
        links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
        links.new(bsdf.outputs[0], out.inputs["Surface"])
    return node_mat(name, build)


def set_mat(ob, m):
    ob.data.materials.clear()
    ob.data.materials.append(m)


def bake_pass(target, sources, kind, size, name, samples=1, extrusion=0.5, max_ray=1.0, margin=24):
    sc = bpy.context.scene
    sc.cycles.samples = samples
    img = bpy.data.images.new(name, size, size, alpha=False, float_buffer=True, is_data=True)
    for m in target.data.materials:
        nt = m.node_tree
        node = nt.nodes.get("BakeTarget") or nt.nodes.new("ShaderNodeTexImage")
        node.name = "BakeTarget"
        node.image = img
        for n in nt.nodes:
            n.select = False
        node.select = True
        nt.nodes.active = node
    for o in sc.objects:
        o.select_set(False)
    for o in sources:
        o.hide_render = False
        o.select_set(True)
    target.select_set(True)
    bpy.context.view_layer.objects.active = target
    t = time.time()
    bpy.ops.object.bake(type=kind, use_selected_to_active=bool(sources), cage_extrusion=extrusion,
                        max_ray_distance=max_ray, margin=margin, normal_space="TANGENT", use_clear=True)
    img.filepath_raw = os.path.join(BAKE, name + ".exr")
    img.file_format = "OPEN_EXR"
    img.save()
    log("baked %s %dpx in %.0fs" % (name, size, time.time() - t))
    return img


def stage_bake(size="4096", which="all"):
    os.makedirs(BAKE, exist_ok=True)
    bpy.ops.wm.open_mainfile(filepath=os.path.join(WORK, "listener_bake.blend"))
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.use_denoising = False                  # this Blender build has no denoiser: with it on, bakes come out empty
    sc.render.bake.use_cage = False
    sc.world = sc.world or bpy.data.worlds.new("World")
    sc.world.light_settings.distance = 8.0                 # local AO (cm)
    size = int(size)
    small = size // 2
    O = bpy.data.objects
    body, head = O["Listener_Body"], O["Listener_Head"]
    hb, hc, hh = O["hi_body"], O["hi_claws"], O["hi_head"]
    vr, vd, bl = O["hi_veins_raised"], O["hi_veins_deep"], O["hi_blood"]
    for o in (hb,):
        sm = o.modifiers.new("unterrace", "SMOOTH")
        sm.factor, sm.iterations = 0.5, 3
    skin_hi = skin_detail_mat("hi_skin")
    for o in (hb, vr):
        set_mat(o, skin_hi)
    set_mat(hc, skin_detail_mat("hi_claw", pores=2.0, wrinkle=3.0, strength=0.08))
    set_mat(hh, skin_detail_mat("hi_membrane", pores=4.0, wrinkle=0.9, strength=0.16))
    sets = [("Body", body, [hb, vr, hc]), ("Head", head, [hh])]
    want = which.split(",") if which != "all" else ["normal", "ao", "thick", "pos", "part", "masks"]
    for tag, low, src in sets:
        if "normal" in want:
            bake_pass(low, src, "NORMAL", size, "%s_normal" % tag)
        if "ao" in want:
            bake_pass(low, src, "AO", small, "%s_ao" % tag, samples=64)
        if "thick" in want:
            thick = emit_mat("thick", lambda n, l: _ao_inside(n, l))
            saved = {o.name: list(o.data.materials) for o in src}
            for o in src:
                set_mat(o, thick)
            bake_pass(low, src, "EMIT", small, "%s_thickness" % tag, samples=32)
            for o in src:
                o.data.materials.clear()
                for m in saved[o.name]:
                    o.data.materials.append(m)
        if "pos" in want:
            keep = list(low.data.materials)
            set_mat(low, emit_mat("pos", lambda n, l: n.new("ShaderNodeNewGeometry").outputs["Position"]))
            bake_pass(low, [], "EMIT", small, "%s_position" % tag)
            low.data.materials.clear()
            for m in keep:
                low.data.materials.append(m)
        if "part" in want and tag == "Body":
            keep = list(low.data.materials)
            def part_col(n, l):
                at = n.new("ShaderNodeAttribute")
                at.attribute_name = "part"
                return at.outputs["Fac"]
            set_mat(low, emit_mat("part", part_col))
            bake_pass(low, [], "EMIT", small, "%s_part" % tag, margin=8)
            low.data.materials.clear()
            for m in keep:
                low.data.materials.append(m)
    if "masks" in want:
        # vein / blood masks for the body: R raised veins, G deep veins, B dried blood (only those objects are hit)
        for o, col in ((vr, (1, 0, 0)), (vd, (0, 1, 0)), (bl, (0, 0, 1))):
            set_mat(o, emit_mat("m_" + o.name, lambda n, l, c=col: _rgb(n, c)))
        bake_pass(body, [vr, vd, bl], "EMIT", size, "Body_masks", extrusion=1.0, max_ray=1.9, margin=8)
        # membrane veins: the per-vertex vein strength of the relief, transferred from the bake source
        hd = np.load(os.path.join(WORK, "head_hi.npz"))
        at = hh.data.attributes.new("veins", "FLOAT", "POINT")
        at.data.foreach_set("value", hd["veins"])
        def vein_col(n, l):
            a = n.new("ShaderNodeAttribute")
            a.attribute_name = "veins"
            return a.outputs["Fac"]
        set_mat(hh, emit_mat("m_head_veins", vein_col))
        bake_pass(head, [hh], "EMIT", size, "Head_masks", extrusion=0.6, max_ray=1.2, margin=8)
    if "attrs" in want or which == "all":
        keep = list(head.data.materials)
        def attr_col(n, l):
            a = n.new("ShaderNodeAttribute")
            a.attribute_name = "bake_attrs"
            return a.outputs["Color"]
        set_mat(head, emit_mat("attrs", attr_col))
        bake_pass(head, [], "EMIT", small, "Head_attrs", margin=8)
        head.data.materials.clear()
        for m in keep:
            head.data.materials.append(m)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(WORK, "listener_baked.blend"), compress=True)


ART = os.path.join(ROOT, "unreal", "DeadFrequency", "SourceArt", "Characters", "Listener")
TEX = os.path.join(ART, "Textures")


def load_exr(name, size):
    """Baked EXR -> float array (H, W, 4), top row first, resized to `size`."""
    from PIL import Image
    img = bpy.data.images.load(os.path.join(BAKE, name + ".exr"))
    w, h = img.size
    a = np.empty(w * h * 4, np.float32)
    img.pixels.foreach_get(a)
    a = a.reshape(h, w, 4)[::-1].copy()
    bpy.data.images.remove(img)
    if w != size:
        a = np.stack([np.asarray(Image.fromarray(a[..., c], mode="F").resize((size, size), Image.BILINEAR))
                      for c in range(4)], axis=-1)
    return a


def save_png(arr, path, gray=False):
    from PIL import Image
    import texgen as T
    u8 = T.to_u8(arr)
    Image.fromarray(u8, mode="L" if gray else "RGB").save(path, optimize=True)
    return path


def stage_textures(size="4096"):
    import texgen as T
    size = int(size)
    os.makedirs(TEX, exist_ok=True)
    t = time.time()
    n = load_exr("Body_normal", size)[..., :3]
    ao = load_exr("Body_ao", size)[..., 0]
    th = load_exr("Body_thickness", size)[..., 0]
    pos = load_exr("Body_position", size)[..., :3]
    part = load_exr("Body_part", size)[..., 0]
    masks = load_exr("Body_masks", size)[..., :3]
    m = T.body_maps(n, ao, th, pos, part, masks)
    save_png(T.lin_to_srgb(m["BaseColor"]), os.path.join(TEX, "T_Listener_Body_BC.png"))
    save_png(T.normal_dx(m["Normal"]), os.path.join(TEX, "T_Listener_Body_N.png"))
    save_png(m["ORM"], os.path.join(TEX, "T_Listener_Body_ORM.png"))
    save_png(m["SSS"], os.path.join(TEX, "T_Listener_Body_SSS.png"), gray=True)
    log("body maps %dpx (%.0fs)" % (size, time.time() - t))
    t = time.time()
    n = load_exr("Head_normal", size)[..., :3]
    ao = load_exr("Head_ao", size)[..., 0]
    th = load_exr("Head_thickness", size)[..., 0]
    pos = load_exr("Head_position", size)[..., :3]
    attrs = load_exr("Head_attrs", size)[..., :3]
    veins = load_exr("Head_masks", size)[..., 0]
    m = T.head_maps(n, ao, th, pos, attrs, veins)
    save_png(T.lin_to_srgb(m["BaseColor"]), os.path.join(TEX, "T_Listener_Membrane_BC.png"))
    save_png(T.normal_dx(m["Normal"]), os.path.join(TEX, "T_Listener_Membrane_N.png"))
    save_png(m["ORM"], os.path.join(TEX, "T_Listener_Membrane_ORM.png"))
    save_png(m["SSS"], os.path.join(TEX, "T_Listener_Membrane_SSS.png"), gray=True)
    log("membrane maps %dpx (%.0fs)" % (size, time.time() - t))


def ld_material(name, prefix, sss_scale=0.45, sss_radius=(1.0, 0.32, 0.18), sss_amount=0.55, coat=0.0, metal_free=True):
    """Blender material from the exported Unreal maps (DirectX normal -> flipped back to OpenGL here)."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    L = nt.links.new

    def tex(suffix, noncolor):
        n = nt.nodes.new("ShaderNodeTexImage")
        n.image = bpy.data.images.load(os.path.join(TEX, "T_%s_%s.png" % (prefix, suffix)), check_existing=True)
        if noncolor:
            n.image.colorspace_settings.name = "Non-Color"
        return n
    bc, nm, orm, sss = tex("BC", False), tex("N", True), tex("ORM", True), tex("SSS", True)
    L(bc.outputs["Color"], b.inputs["Base Color"])
    sep = nt.nodes.new("ShaderNodeSeparateColor")
    L(orm.outputs["Color"], sep.inputs["Color"])
    L(sep.outputs["Green"], b.inputs["Roughness"])
    sn = nt.nodes.new("ShaderNodeSeparateColor")
    L(nm.outputs["Color"], sn.inputs["Color"])
    inv = nt.nodes.new("ShaderNodeMath")
    inv.operation = "SUBTRACT"
    inv.inputs[0].default_value = 1.0
    L(sn.outputs["Green"], inv.inputs[1])
    cc = nt.nodes.new("ShaderNodeCombineColor")
    L(sn.outputs["Red"], cc.inputs["Red"])
    L(inv.outputs[0], cc.inputs["Green"])
    L(sn.outputs["Blue"], cc.inputs["Blue"])
    nmap = nt.nodes.new("ShaderNodeNormalMap")
    L(cc.outputs["Color"], nmap.inputs["Color"])
    L(nmap.outputs["Normal"], b.inputs["Normal"])
    mul = nt.nodes.new("ShaderNodeMath")
    mul.operation = "MULTIPLY"
    mul.inputs[1].default_value = sss_amount
    L(sss.outputs["Color"], mul.inputs[0])
    L(mul.outputs[0], b.inputs["Subsurface Weight"])
    b.inputs["Subsurface Radius"].default_value = sss_radius
    b.inputs["Subsurface Scale"].default_value = sss_scale
    b.subsurface_method = "RANDOM_WALK_SKIN"
    b.inputs["Coat Weight"].default_value = coat
    b.inputs["Coat Roughness"].default_value = 0.08
    m.use_sss_translucency = True
    return m


def horror_lights(target, scale=1.0, back=1.0):
    """Cold key from above the front, warm rim behind the horn (shows the membrane's translucency), dim fill."""
    from mathutils import Vector
    t = Vector(target)
    s = 2.4e6 * scale
    U.area_light("Key", t + Vector((-180, -300, 260)), t, 2.2 * s, size=120, color=(0.86, 0.92, 1.0))
    U.area_light("Rim", t + Vector((160, 260, 120)), t, 3.4 * s * back, size=90, color=(1.0, 0.72, 0.55))
    U.area_light("Back", t + Vector((-60, 180, 230)), t + Vector((0, -30, 20)), 2.6 * s * back, size=60, color=(1.0, 0.6, 0.45))
    U.area_light("Fill", t + Vector((320, -220, 40)), t, 0.35 * s, size=260, color=(0.7, 0.75, 0.9))
    w = bpy.data.worlds.new("World")
    bpy.context.scene.world = w
    w.use_nodes = True
    w.node_tree.nodes["Background"].inputs["Color"].default_value = (0.006, 0.006, 0.008, 1)


def stage_lookdev(pose="rest", views="front,q34,headq,torso,hand,back", engine="eevee", tag="lookdev"):
    rigged = os.path.join(WORK, "listener_rigged.blend")
    src = rigged if os.path.exists(rigged) else os.path.join(WORK, "listener_bake.blend")
    bpy.ops.wm.open_mainfile(filepath=src)
    sc = bpy.context.scene
    for o in sc.objects:
        if o.name.startswith("hi_") or o.name.endswith("_quads"):
            o.hide_render = True
    body, head = bpy.data.objects["Listener_Body"], bpy.data.objects["Listener_Head"]
    skin = ld_material("LD_Skin", "Listener_Body", sss_scale=0.5, sss_amount=0.6)
    claw = ld_material("LD_Claw", "Listener_Body", sss_amount=0.0, coat=0.3)
    memb = ld_material("LD_Membrane", "Listener_Membrane", sss_scale=0.9, sss_radius=(1.0, 0.25, 0.2), sss_amount=0.8, coat=0.25)
    body.data.materials.clear()
    body.data.materials.append(skin)
    body.data.materials.append(claw)
    head.data.materials.clear()
    head.data.materials.append(memb)
    lm = json.load(open(os.path.join(WORK, "rig_landmarks.json")))
    J = {k: np.asarray(v, float) for k, v in lm["joints"].items()}
    if pose != "rest" and "Armature" in bpy.data.objects:
        import anim as A
        import listener_anim as LA
        arm = bpy.data.objects["Armature"]
        rig = A.Rig(arm)
        c = LA.Ctx(rig)
        P = LA.clip_idle(rig, c, 0, 120, {})
        apply_pose(arm, P)
        bpy.context.view_layer.update()
        J["hand_l"] = np.array(arm.matrix_world @ arm.pose.bones["hand_l"].head)
        J["head"] = np.array(arm.matrix_world @ arm.pose.bones["head"].head)
    U.floor(0.0, color=(0.03, 0.03, 0.035), rough=0.45)
    horror_lights((0, -5, 140))
    if engine == "eevee":
        U.eevee((1200, 1600), samples=64, sss=True, bloom=False)
    else:
        U.cycles((1200, 1600), samples=int(engine.split(":")[1]) if ":" in engine else 192)
    hj = J["head"]
    hand = J["hand_l"]
    cams = {
        "front": ((0, -430, 140), (0, 0, 125), 50),
        "q34": ((-300, -330, 170), (0, -5, 128), 50),
        "back": ((120, 420, 160), (0, 0, 130), 50),
        "headq": ((-90, -120, 30), (2, -16, 18), 55),
        "torso": ((-70, -150, 5), (0, -2, 0), 50),
        "hand": ((-55, -45, 10), (0, 0, 0), 55),
    }
    out = []
    for name in views.split(","):
        off, tgt, lens = cams[name]
        if name == "headq":
            base = hj
        elif name == "hand":
            base = hand
        elif name == "torso":
            base = np.array([0, 0, 165.0])
        else:
            base = np.zeros(3)
        T = np.add(base, tgt)
        cam = U.camera("cam_" + name, tuple(np.add(T, off)), tuple(T), lens=lens)
        wide = name in ("headq", "torso", "hand")
        sc.render.resolution_x, sc.render.resolution_y = (1600, 1200) if wide else (1200, 1600)
        p = os.path.join(WORK, "%s_%s.png" % (tag, name))
        U.render(p, cam)
        out.append(p)
        log("rendered", name)
    U.contact_sheet(out, os.path.join(WORK, "sheet_%s.jpg" % tag), 3, thumb=(800, 800), labels=views.split(","))


def _rgb(nodes, c):
    n = nodes.new("ShaderNodeRGB")
    n.outputs[0].default_value = (*c, 1.0)
    return n.outputs[0]


def _ao_inside(nodes, links):
    ao = nodes.new("ShaderNodeAmbientOcclusion")
    ao.inside = True
    ao.samples = 16
    ao.inputs["Distance"].default_value = 6.0
    return ao.outputs["AO"]


# ------------------------------------------------------------------------------------------------ rig

def build_armature(bones):
    ad = bpy.data.armatures.new("SK_Listener_Skeleton")
    arm = bpy.data.objects.new("Armature", ad)
    bpy.context.scene.collection.objects.link(arm)
    select_only(arm)
    bpy.ops.object.mode_set(mode="EDIT")
    eb = ad.edit_bones
    for b in bones:
        e = eb.new(b["name"])
        e.head = b["head"].tolist()
        e.tail = b["tail"].tolist()
        e.align_roll(b["up"].tolist())
        e.use_deform = b["name"] != "root"
    for b in bones:
        if b["parent"]:
            eb[b["name"]].parent = eb[b["parent"]]
            eb[b["name"]].use_connect = False
    bpy.ops.object.mode_set(mode="OBJECT")
    ad.display_type = "STICK"
    return arm


def stage_rig(src="listener_bake.blend"):
    import rig as R
    bpy.ops.wm.open_mainfile(filepath=os.path.join(WORK, src))
    lm = json.load(open(os.path.join(WORK, "rig_landmarks.json")))
    J = {k: np.asarray(v, float) for k, v in lm["joints"].items()}
    hf = json.load(open(os.path.join(WORK, "head_frame.json")))
    bones = R.define(J, hf, hf["struts"])
    arm = build_armature(bones)
    body, head = bpy.data.objects["Listener_Body"], bpy.data.objects["Listener_Head"]
    # body: bone heat from the body bones only (the membrane bones would steal the neck)
    mem = [b.name for b in arm.data.bones if b.name.startswith("membrane_")]
    for n in mem:
        arm.data.bones[n].use_deform = False
    for o in bpy.context.scene.objects:
        o.select_set(False)
    body.select_set(True)
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    t = time.time()
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")
    log("bone heat weights %.0fs, %d groups" % (time.time() - t, len(body.vertex_groups)))
    for n in mem:
        arm.data.bones[n].use_deform = True
    # claws: rigid on the last bone of their digit
    me = body.data
    claw_poly = np.array([p.material_index == 1 for p in me.polygons])
    claw_verts = np.zeros(len(me.vertices), bool)
    for p in me.polygons:
        if p.material_index == 1:
            claw_verts[list(p.vertices)] = True
    V = U.get_verts(body)
    tips = {}
    for s in "lr":
        for f in ("index", "middle", "ring", "pinky"):
            tips["%s_04_%s" % (f, s)] = J["%s_tip_%s" % (f, s)]
        tips["thumb_03_" + s] = J["thumb_tip_" + s]
        tips["ball_" + s] = J["toe_tip_" + s]
    names = list(tips)
    pts = np.array([tips[n] for n in names])
    idx = np.nonzero(claw_verts)[0]
    near = np.argmin(np.linalg.norm(V[idx][:, None] - pts[None], axis=2), axis=1)
    for g in body.vertex_groups:
        g.remove(idx.tolist())
    for k, n in enumerate(names):
        sel = idx[near == k].tolist()
        if sel:
            (body.vertex_groups.get(n) or body.vertex_groups.new(name=n)).add(sel, 1.0, "REPLACE")
    del claw_poly
    # tidy: smooth a little, at most 4 influences, normalised
    select_only(body)
    bpy.ops.object.mode_set(mode="WEIGHT_PAINT")
    bpy.ops.object.vertex_group_smooth(group_select_mode="ALL", factor=0.35, repeat=2)
    bpy.ops.object.vertex_group_limit_total(group_select_mode="ALL", limit=4)
    bpy.ops.object.vertex_group_normalize_all(lock_active=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    # head: weights from the horn's own parameters
    hd = np.load(os.path.join(WORK, "head_lo.npz"))
    W = R.membrane_weights(hd["theta"], hd["u"], hd["layer"], hf["struts"])
    for n, w in W.items():
        w = np.asarray(w, float)
        g = head.vertex_groups.new(name=n)
        for val in np.unique(np.round(w[w > 0.001], 3)):
            sel = np.nonzero(np.abs(np.round(w, 3) - val) < 1e-9)[0].tolist()
            g.add(sel, float(val), "REPLACE")
    select_only(head)
    bpy.ops.object.mode_set(mode="WEIGHT_PAINT")
    bpy.ops.object.vertex_group_limit_total(group_select_mode="ALL", limit=4)
    bpy.ops.object.vertex_group_normalize_all(lock_active=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    for ob in (body, head):
        ob.parent = arm
        mod = ob.modifiers.get("Armature") or ob.modifiers.new("Armature", "ARMATURE")
        mod.object = arm
    # sanity: every vertex weighted
    for ob in (body, head):
        tot = np.zeros(len(ob.data.vertices))
        for v in ob.data.vertices:
            tot[v.index] = sum(g.weight for g in v.groups)
        log("%s: unweighted verts %d, max influences %d" % (ob.name, int((tot < 0.99).sum()),
            max(len(v.groups) for v in ob.data.vertices)))
    log("bones %d (deform %d)" % (len(arm.data.bones), sum(b.use_deform for b in arm.data.bones)))
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(WORK, "listener_rigged.blend"), compress=True)


def apply_pose(arm, P):
    """Put a Pose (anim.Pose) on the armature's pose bones."""
    from anim import quat_from_mat
    for i, n in enumerate(P.rig.names):
        pb = arm.pose.bones[n]
        pb.rotation_mode = "QUATERNION"
        pb.rotation_quaternion = quat_from_mat(P.basis[i][:3, :3]).tolist()
        pb.location = P.basis[i][:3, 3].tolist()
    bpy.context.view_layer.update()


def stage_rigtest():
    import anim as A
    import listener_anim as LA
    bpy.ops.wm.open_mainfile(filepath=os.path.join(WORK, "listener_rigged.blend"))
    sc = bpy.context.scene
    arm = bpy.data.objects["Armature"]
    for o in sc.objects:
        if o.name.startswith("hi_"):
            o.hide_render = True
    clay = U.principled("Clay", (0.62, 0.6, 0.58), rough=0.6)
    for n in ("Listener_Body", "Listener_Head"):
        ob = bpy.data.objects[n]
        ob.data.materials.clear()
        ob.data.materials.append(clay)
    rig = A.Rig(arm)
    c = LA.Ctx(rig)
    poses = {}
    P = LA.base_pose(rig); LA.pelvis_offset(P, [0, 0, -9]); LA.posture(P, c)
    for s in "lr":
        LA.foot_plant(P, c, s, 0.0, 0.0)
    poses["hunched stance"] = P
    P = LA.base_pose(rig); LA.pelvis_offset(P, [0, 6, -42]); LA.posture(P, c, hunch=1.2, lean=20)
    for s in "lr":
        LA.foot_plant(P, c, s, -8.0, 0.0, x_off=c.side[s] * 6)
    poses["deep crouch"] = P
    P = LA.base_pose(rig); LA.pelvis_offset(P, [0, 0, -9]); LA.posture(P, c, yaw=40, side_bend=25)
    for s in "lr":
        LA.foot_plant(P, c, s, 0.0, 0.0)
    for s in "lr":
        sh = P.world("upperarm_" + s)[:3, 3]
        P.ik("upperarm_" + s, "lowerarm_" + s, sh + np.array([-c.side[s] * 5, -30, 25]), sh + np.array([c.side[s] * 30, 10, -20]), z_to_pole=False)
        LA.relax_hand(P, c, s, 1.0)
    poses["twist, reach, fists"] = P
    P = LA.base_pose(rig); LA.pelvis_offset(P, [0, 0, -9]); LA.posture(P, c)
    for s in "lr":
        LA.foot_plant(P, c, s, 0.0, 0.0)
    LA.struts_flare(P, c, 24.0)
    LA.rot_w(P, "head", Z, 30)
    for s in "lr":
        LA.relax_hand(P, c, s, -0.2, spread=1.2)
    poses["membrane flared"] = P
    poses["crawl"] = LA.clip_crawl(rig, c, 0, 36, {})
    poses["attack (seize)"] = LA.clip_attack(rig, c, 22, 54, {})
    U.floor(0.0)
    U.studio((0, 0, 100), radius=480, key=0.32)
    U.eevee((1050, 1200), samples=32)
    cam = U.camera("cam", (-260, -330, 120), (0, -10, 100), lens=40)
    out = []
    for k, (label, P) in enumerate(poses.items()):
        apply_pose(arm, P)
        p = os.path.join(WORK, "rigtest_%02d.png" % k)
        U.render(p, cam)
        out.append(p)
    U.contact_sheet(out, os.path.join(WORK, "sheet_rigtest.jpg"), 3, thumb=(700, 800), labels=list(poses))


def select_only(ob):
    for o in bpy.context.scene.objects:
        o.select_set(False)
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob


def stage_retopo(faces="36000", voxel="0.55"):
    """Body game mesh: voxel-clean the sculpt (manifold, even), QuadriFlow to quads, then relax and project
    back onto the sculpt so the low mesh hugs the high one (small bake distances)."""
    U.reset_scene()
    hi = load_body()
    lo = hi.copy()
    lo.data = hi.data.copy()
    lo.name = "Listener_Body"
    bpy.context.scene.collection.objects.link(lo)
    select_only(lo)
    t = time.time()
    lo.data.remesh_voxel_size = float(voxel)
    lo.data.use_remesh_fix_poles = True
    bpy.ops.object.voxel_remesh()
    log("voxel remesh %.2f: %d faces (%.1fs)" % (float(voxel), len(lo.data.polygons), time.time() - t))
    t = time.time()
    r = bpy.ops.object.quadriflow_remesh(target_faces=int(faces), use_mesh_symmetry=True, use_preserve_sharp=False,
                                         use_preserve_boundary=False, smooth_normals=False, seed=7)
    log("quadriflow %s: %d faces (%.1fs)" % (r, len(lo.data.polygons), time.time() - t))
    # relax + project, twice
    for it in range(2):
        m = lo.modifiers.new("relax", "SMOOTH")
        m.factor, m.iterations = 0.5, 2
        w = lo.modifiers.new("project", "SHRINKWRAP")
        w.target = hi
        w.wrap_method = "NEAREST_SURFACEPOINT"
        for mod in list(lo.modifiers):
            bpy.ops.object.modifier_apply(modifier=mod.name)
    clean_mesh(lo)
    refine_extremities(lo, hi)
    stats(lo)
    hi.hide_render = True
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(WORK, "body_retopo.blend"), compress=True)


def refine_extremities(lo, hi):
    """Hands and feet get one more level of quads (fingers need ~12 faces around), projected onto the sculpt."""
    import uvseams
    lm = json.load(open(os.path.join(WORK, "rig_landmarks.json")))
    V = U.get_verts(lo)
    E = mesh_edges(lo)
    _, lab, _ = uvseams.compute(V, E, lm["joints"])
    ext = np.isin(lab, [uvseams.PARTS.index(p) for p in ("hand_l", "hand_r", "foot_l", "foot_r")])
    # also take the wrist/ankle ring so the transition sits on the forearm/shin, not on the knuckles
    me = lo.data
    sel = np.zeros(len(me.polygons), bool)
    for p in me.polygons:
        sel[p.index] = ext[list(p.vertices)].all()
    me.polygons.foreach_set("select", sel)
    select_only(lo)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_mode(type="FACE")
    bpy.ops.mesh.subdivide(number_cuts=1, smoothness=0.0, quadcorner="INNERVERT")
    bpy.ops.object.mode_set(mode="OBJECT")
    # project only the refined region back onto the sculpt
    V2 = U.get_verts(lo)
    grp = lo.vertex_groups.new(name="refine")
    dist = np.linalg.norm(V2[:, None, :2] * 0, axis=2)  # placeholder to keep shapes simple
    del dist
    sel_v = [v.index for v in me.vertices if v.select]
    grp.add(sel_v, 1.0, "REPLACE")
    w = lo.modifiers.new("project_refined", "SHRINKWRAP")
    w.target = hi
    w.wrap_method = "NEAREST_SURFACEPOINT"
    w.vertex_group = "refine"
    m = lo.modifiers.new("relax_refined", "SMOOTH")
    m.factor, m.iterations, m.vertex_group = 0.4, 1, "refine"
    w2 = lo.modifiers.new("project_refined2", "SHRINKWRAP")
    w2.target = hi
    w2.wrap_method = "NEAREST_SURFACEPOINT"
    w2.vertex_group = "refine"
    for mod in list(lo.modifiers):
        bpy.ops.object.modifier_apply(modifier=mod.name)
    lo.vertex_groups.remove(grp)
    log("refined hands and feet: %d faces selected, now %d faces" % (int(sel.sum()), len(me.polygons)))


def clean_mesh(ob):
    """Remove the few non-manifold spots QuadriFlow can leave (fins where two sheets touch), refill as quads."""
    select_only(ob)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_mode(type="VERT")
    bpy.ops.mesh.select_all(action="DESELECT")
    bpy.ops.mesh.select_non_manifold(extend=False, use_wire=True, use_boundary=False, use_multi_face=True,
                                     use_non_contiguous=True, use_verts=True)
    bpy.ops.mesh.delete(type="VERT")
    bpy.ops.mesh.select_all(action="DESELECT")
    bpy.ops.mesh.select_non_manifold(extend=False, use_wire=False, use_boundary=True, use_multi_face=False,
                                     use_non_contiguous=False, use_verts=False)
    bpy.ops.mesh.fill_holes(sides=12)
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.tris_convert_to_quads()
    bpy.ops.mesh.delete_loose()
    bpy.ops.object.mode_set(mode="OBJECT")


def wire_overlay(ob, thickness=0.06, color=(0.02, 0.02, 0.025)):
    """A copy of the mesh turned into its edges (Wireframe modifier), drawn over the clay: real topology."""
    w = ob.copy()
    w.data = ob.data.copy()
    w.name = ob.name + "_wire"
    bpy.context.scene.collection.objects.link(w)
    m = w.modifiers.new("wire", "WIREFRAME")
    m.thickness = thickness
    m.use_even_offset = False
    m.use_relative_offset = False
    m.offset = 1.0
    w.data.materials.clear()
    w.data.materials.append(U.principled("Wire", color, rough=0.8))
    return w


def stage_preview_wire(blend="body_retopo.blend", obj="Listener_Body", views="front,q34,torso,hand,back_close,foot", tag="retopo"):
    bpy.ops.wm.open_mainfile(filepath=os.path.join(WORK, blend))
    sc = bpy.context.scene
    for o in list(sc.objects):
        if o.name != obj:
            o.hide_render = True
    ob = bpy.data.objects[obj]
    ob.hide_render = False
    ob.data.materials.clear()
    ob.data.materials.append(U.principled("Clay", (0.62, 0.6, 0.58), rough=0.6))
    wire_overlay(ob)
    U.floor(0.0)
    U.studio((0, 0, 115), radius=480, key=0.32)
    U.eevee((1200, 1600), samples=32)
    out = []
    for name in views.split(","):
        off, tgt, lens = VIEWS[name]
        cam = U.camera("cam_" + name, tuple(np.add(tgt, off)), tgt, lens=lens)
        wide = name in ("hand", "foot", "torso", "back_close", "neck", "legs", "headq")
        sc.render.resolution_x, sc.render.resolution_y = (1400, 1050) if wide else (1050, 1400)
        p = os.path.join(WORK, "wire_%s_%s.png" % (tag, name))
        U.render(p, cam)
        out.append(p)
    U.contact_sheet(out, os.path.join(WORK, "sheet_wire_%s.jpg" % tag), 3, thumb=(800, 600),
                    labels=["%s - %s" % (tag, os.path.basename(p)[6 + len(tag):-4]) for p in out])


def face_data(ob):
    """Face centroids and, for every edge, the (up to two) faces using it (-1 where missing)."""
    me = ob.data
    n = len(me.polygons)
    cent = np.empty(n * 3, np.float32)
    me.polygons.foreach_get("center", cent)
    le = np.empty(len(me.loops), np.int32)
    me.loops.foreach_get("edge_index", le)
    tot = np.empty(n, np.int32)
    me.polygons.foreach_get("loop_total", tot)
    lf = np.repeat(np.arange(n), tot)
    EF = np.full((len(me.edges), 2), -1, np.int64)
    order = np.argsort(le, kind="stable")
    le_s, lf_s = le[order], lf[order]
    first = np.ones(len(le_s), bool)
    first[1:] = le_s[1:] != le_s[:-1]
    EF[le_s[first], 0] = lf_s[first]
    second = ~first
    EF[le_s[second], 1] = lf_s[second]
    return cent.reshape(-1, 3).astype(np.float64), EF


def mesh_edges(ob):
    me = ob.data
    e = np.empty(len(me.edges) * 2, np.int32)
    me.edges.foreach_get("vertices", e)
    return e.reshape(-1, 2)


def unwrap(ob, margin=0.003):
    select_only(ob)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.unwrap(method="ANGLE_BASED", margin=margin)
    bpy.ops.uv.average_islands_scale()
    pack(margin)
    bpy.ops.object.mode_set(mode="OBJECT")


def pack(margin=0.003):
    bpy.ops.uv.pack_islands(rotate=True, rotate_method="ANY", scale=True, margin_method="SCALED", margin=margin,
                            shape_method="CONCAVE")


def stage_uv():
    import uvseams
    bpy.ops.wm.open_mainfile(filepath=os.path.join(WORK, "body_retopo.blend"))
    lo = bpy.data.objects["Listener_Body"]
    lm = json.load(open(os.path.join(WORK, "rig_landmarks.json")))
    V = U.get_verts(lo)
    E = mesh_edges(lo)
    F, EF = face_data(lo)
    seam, lab, region = uvseams.compute(V, E, lm["joints"], F, EF)
    lo.data.edges.foreach_set("use_seam", seam)
    # part labels as a vertex attribute (used later by texturing and skin weights)
    at = lo.data.attributes.new("part", "INT", "POINT")
    at.data.foreach_set("value", lab.astype(np.int32))
    log("seams: %d of %d edges; regions %d" % (seam.sum(), len(seam), len(np.unique(region))))
    select_only(lo)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.unwrap(method="ANGLE_BASED", margin=0.003)
    bpy.ops.uv.average_islands_scale()
    bpy.ops.object.mode_set(mode="OBJECT")
    # hands and feet: more texels (close-ups in attacks); scale their islands before packing
    me = lo.data
    uv = np.empty(len(me.loops) * 2, np.float32)
    me.uv_layers.active.data.foreach_get("uv", uv)
    uv = uv.reshape(-1, 2)
    tot = np.empty(len(me.polygons), np.int32)
    me.polygons.foreach_get("loop_total", tot)
    loop_face = np.repeat(np.arange(len(me.polygons)), tot)
    hf = [uvseams.PARTS.index(p) * 4 for p in ("hand_l", "hand_r", "foot_l", "foot_r")]
    for r in np.unique(region):
        if (r // 4) * 4 in hf:
            sel = region[loop_face] == r
            c = uv[sel].mean(axis=0)
            uv[sel] = c + (uv[sel] - c) * 1.4
    me.uv_layers.active.data.foreach_set("uv", uv.reshape(-1))
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    pack(0.003)
    bpy.ops.object.mode_set(mode="OBJECT")
    uv = np.empty(len(lo.data.loops) * 2, np.float32)
    lo.data.uv_layers.active.data.foreach_get("uv", uv)
    log("uv bounds", uv.reshape(-1, 2).min(0), uv.reshape(-1, 2).max(0), "coverage %.1f%%" % (100 * uv_coverage(lo)))
    uv_layout_png(lo, os.path.join(WORK, "uv_body.png"), 1600, region)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(WORK, "body_uv.blend"), compress=True)


def uv_coverage(ob, res=1024):
    """Fraction of the 0-1 UV square covered by faces (rasterised)."""
    from PIL import Image, ImageDraw
    me = ob.data
    uv = np.empty(len(me.loops) * 2, np.float32)
    me.uv_layers.active.data.foreach_get("uv", uv)
    uv = uv.reshape(-1, 2)
    img = Image.new("L", (res, res), 0)
    dr = ImageDraw.Draw(img)
    for p in me.polygons:
        dr.polygon([(float(uv[i, 0] * res), float((1 - uv[i, 1]) * res)) for i in p.loop_indices], fill=255)
    return float(np.asarray(img).mean() / 255.0)


def uv_layout_png(ob, path, size=2048, color_by=None):
    """Draw the UV layout (one outline per face) with PIL; optional per-face colour index."""
    from PIL import Image, ImageDraw
    me = ob.data
    uv = np.empty(len(me.loops) * 2, np.float32)
    me.uv_layers.active.data.foreach_get("uv", uv)
    uv = uv.reshape(-1, 2)
    img = Image.new("RGB", (size, size), (16, 16, 18))
    dr = ImageDraw.Draw(img)
    pal = [(214, 120, 110), (110, 170, 214), (150, 210, 120), (220, 190, 100), (180, 130, 210), (110, 200, 190),
           (230, 140, 60), (200, 200, 200)]
    for p in me.polygons:
        pts = [(float(uv[i, 0] * size), float((1 - uv[i, 1]) * size)) for i in p.loop_indices]
        c = pal[(color_by[p.index] if color_by is not None else 0) % len(pal)]
        dr.polygon(pts, outline=c, fill=tuple(int(x * 0.25) for x in c))
    img.save(path)
    return path


def stats(ob):
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    sizes = np.bincount([len(f.verts) for f in bm.faces])
    nonman = sum(1 for e in bm.edges if not e.is_manifold)
    poles = np.bincount([len(v.link_edges) for v in bm.verts])
    log("%s: %d verts, %d faces (by size %s), non-manifold edges %d, valence %s" % (
        ob.name, len(bm.verts), len(bm.faces), dict(enumerate(sizes.tolist())), nonman, dict(enumerate(poles.tolist()))))
    bm.free()


if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    stage = argv[0] if argv else "body"
    globals()["stage_" + stage](*argv[1:])
