"""The Listener — original creature for DEAD FREQUENCY (procedural sculpt, bake, rig, animation).
blender -b --factory-startup --python tools/blender/listener.py -- <out_dir> [stage]
Godot coordinates via G(); the creature faces -Z (Godot forward), feet on y = 0, ~2.6 m tall."""
import sys, os, math, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dflib import *
import bmesh
from mathutils import Vector, Matrix, Euler, noise

OUT = sys.argv[-2] if sys.argv[-1] in ("mesh", "bake", "all") else sys.argv[-1]
STAGE = sys.argv[-1] if sys.argv[-1] in ("mesh", "bake", "all") else "all"
random.seed(5)
reset()
scene = bpy.context.scene

# ------------------------------------------------------------------ skeleton (joint positions, Godot axes)
J = {
 "pelvis": (0, 1.24, 0.02), "spine1": (0, 1.46, 0.0), "spine2": (0, 1.7, -0.06), "chest": (0, 1.94, -0.14),
 "neck1": (0, 2.1, -0.24), "neck2": (0, 2.24, -0.33), "head": (0, 2.34, -0.42),
}
for s, sx in (("L", 1), ("R", -1)):
    J.update({
     f"hip_{s}": (sx * 0.13, 1.2, 0.03), f"knee_{s}": (sx * 0.17, 0.76, -0.16), f"ankle_{s}": (sx * 0.19, 0.3, 0.1),
     f"ball_{s}": (sx * 0.2, 0.05, -0.05), f"toe_{s}": (sx * 0.21, 0.02, -0.21),
     f"shoulder_{s}": (sx * 0.25, 1.95, -0.12), f"elbow_{s}": (sx * 0.38, 1.48, -0.02), f"wrist_{s}": (sx * 0.43, 1.0, -0.13),
     f"palm_{s}": (sx * 0.445, 0.88, -0.16),
    })
    for k, dz in enumerate((-0.05, 0.0, 0.05)):
        J[f"f{k}a_{s}"] = (sx * (0.45 + 0.01 * k), 0.8, -0.16 + dz)
        J[f"f{k}b_{s}"] = (sx * (0.46 + 0.01 * k), 0.66, -0.19 + dz * 1.4)
        J[f"f{k}c_{s}"] = (sx * (0.465 + 0.01 * k), 0.53, -0.17 + dz * 1.6)
EDGES = [("pelvis", "spine1"), ("spine1", "spine2"), ("spine2", "chest"), ("chest", "neck1"), ("neck1", "neck2"), ("neck2", "head")]
for s in "LR":
    EDGES += [("pelvis", f"hip_{s}"), (f"hip_{s}", f"knee_{s}"), (f"knee_{s}", f"ankle_{s}"), (f"ankle_{s}", f"ball_{s}"), (f"ball_{s}", f"toe_{s}"),
              ("chest", f"shoulder_{s}"), (f"shoulder_{s}", f"elbow_{s}"), (f"elbow_{s}", f"wrist_{s}"), (f"wrist_{s}", f"palm_{s}")]
    for k in range(3):
        EDGES += [(f"palm_{s}", f"f{k}a_{s}"), (f"f{k}a_{s}", f"f{k}b_{s}"), (f"f{k}b_{s}", f"f{k}c_{s}")]
RAD = {"pelvis": 0.115, "spine1": 0.1, "spine2": 0.12, "chest": 0.14, "neck1": 0.055, "neck2": 0.05, "head": 0.06}
for s in "LR":
    RAD.update({f"hip_{s}": 0.075, f"knee_{s}": 0.05, f"ankle_{s}": 0.035, f"ball_{s}": 0.032, f"toe_{s}": 0.016,
                f"shoulder_{s}": 0.055, f"elbow_{s}": 0.038, f"wrist_{s}": 0.026, f"palm_{s}": 0.03})
    for k in range(3):
        RAD[f"f{k}a_{s}"] = 0.016; RAD[f"f{k}b_{s}"] = 0.012; RAD[f"f{k}c_{s}"] = 0.005

def build_body():
    names = list(J.keys()); idx = {n: i for i, n in enumerate(names)}
    me = bpy.data.meshes.new("skel")
    me.from_pydata([G(*J[n]) for n in names], [(idx[a], idx[b]) for a, b in EDGES], [])
    ob = bpy.data.objects.new("skel", me); bpy.context.scene.collection.objects.link(ob)
    ob.modifiers.new("skin", 'SKIN')
    for n in names:
        r = RAD[n]
        d = me.skin_vertices[0].data[idx[n]]; d.radius = (r * (1.25 if n in ("chest", "spine2") else 1.0), r)
    me.skin_vertices[0].data[idx["pelvis"]].use_root = True
    sub = ob.modifiers.new("sub", 'SUBSURF'); sub.levels = 2; sub.render_levels = 2
    body = realize(ob)
    parts = [body]
    # ribs: arcs around the chest that push through the skin, and a ridge of vertebrae down the back
    for k in range(7):
        y = 1.95 - k * 0.07; zc = -0.115 + k * 0.012
        w = 0.135 - abs(k - 2.5) * 0.008; d = 0.115 - k * 0.004
        pts = []
        for t in range(-115, 116, 23):
            a_ = math.radians(t)
            pts.append((w * math.sin(a_), y - 0.07 * max(0.0, math.cos(a_)) ** 1.5, zc - d * math.cos(a_)))
        parts.append(tube_path(f"rib{k}", pts, 0.0105 - k * 0.0006, "skin", res=4))
    # shoulder blades and a skull bulb behind the dish
    for sx in (-1, 1):
        sb = cyl("scapula", 0.075, 0.02, (sx * 0.12, 1.86, 0.02), "skin", axis='z', seg=16)
        sb.scale = (1.0, 1.35, 1.0); parts.append(sb)
    sk = bpy.data.objects.new("skull", bpy.data.meshes.new("skull")); bpy.context.scene.collection.objects.link(sk)
    bmk = bmesh.new(); bmesh.ops.create_uvsphere(bmk, u_segments=24, v_segments=16, radius=0.085); bmk.to_mesh(sk.data); bmk.free()
    sk.location = G(0, 2.38, -0.4); sk.scale = (0.9, 1.25, 1.0); parts.append(sk)
    for k in range(14):
        t = k / 13
        y = 1.3 + t * 0.85; z = 0.1 - t * 0.12 - 0.15 * t * t
        parts.append(cyl(f"vert{k}", 0.022, 0.03, (0, y, z + 0.02), "skin", axis='z', seg=10))
    # collarbones and a pelvic ridge
    for sx in (-1, 1):
        parts.append(tube_path("clav", [(0, 1.97, -0.2), (sx * 0.14, 2.0, -0.18), (sx * 0.26, 1.96, -0.13)], 0.016, "skin"))
        parts.append(tube_path("iliac", [(sx * 0.02, 1.32, -0.08), (sx * 0.12, 1.3, -0.06), (sx * 0.15, 1.24, 0.02)], 0.02, "skin"))
    parts = [realize(p) for p in parts]
    body = join("body_hi", parts)
    bpy.context.view_layer.objects.active = body
    body.data.remesh_voxel_size = 0.0035
    bpy.ops.object.voxel_remesh()
    # soften voxel steps, then skin detail: fine wrinkles + veins
    sm = body.modifiers.new("smooth", 'CORRECTIVE_SMOOTH'); sm.iterations = 8; sm.smooth_type = 'LENGTH_WEIGHTED'; sm.use_only_smooth = True
    tex = bpy.data.textures.new("wrinkle", 'VORONOI'); tex.noise_scale = 0.011; tex.distance_metric = 'DISTANCE'
    dp = body.modifiers.new("wrinkle", 'DISPLACE'); dp.texture = tex; dp.strength = -0.0024; dp.mid_level = 0.5
    tex2 = bpy.data.textures.new("lumps", 'CLOUDS'); tex2.noise_scale = 0.07
    dp2 = body.modifiers.new("lumps", 'DISPLACE'); dp2.texture = tex2; dp2.strength = 0.006
    body = realize(body)
    return body

def build_dish():
    """The 'ear': a parabolic membrane ~0.75 m across on cartilage spokes; the hollow faces forward (-Z)."""
    R, depth, rings, segs = 0.37, 0.16, 14, 56
    C = (0.0, 2.43, -0.5)          # centre of the hollow (deepest point)
    def P(u, v, w):                 # dish-local (u right, v up, w forward depth) -> Godot
        return (C[0] + u, C[1] + v, C[2] - w)
    def shape(r, a):
        wob = 1.0 + 0.07 * math.sin(a * 3 + 1.0) + 0.04 * math.sin(a * 7 + 0.3)
        return r * math.cos(a) * wob, r * math.sin(a) * wob * 0.9, depth * (r / R) ** 2
    bm = bmesh.new()
    grid = []
    for i in range(rings + 1):
        row = []
        for j in range(segs):
            a = 2 * math.pi * j / segs; r = R * i / rings
            u, v, w = shape(r, a)
            row.append(bm.verts.new(G(*P(u, v, w))))
        grid.append(row)
    for i in range(rings):
        for j in range(segs):
            q = [grid[i][j], grid[i][(j + 1) % segs], grid[i + 1][(j + 1) % segs], grid[i + 1][j]]
            if i == 0: bm.faces.new((q[0], q[2], q[3]))
            else: bm.faces.new(q)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    me = bpy.data.meshes.new("dish"); bm.to_mesh(me); bm.free()
    dish = bpy.data.objects.new("dish", me); bpy.context.scene.collection.objects.link(dish)
    me.materials.append(mat("membrane"))
    so = dish.modifiers.new("thick", 'SOLIDIFY'); so.thickness = 0.007
    sub = dish.modifiers.new("sub", 'SUBSURF'); sub.levels = 1
    parts = [realize(dish)]
    for j in range(9):                      # cartilage spokes behind the membrane
        a = 2 * math.pi * j / 9 + 0.2
        pts = []
        for t in (0.12, 0.35, 0.6, 0.85, 1.0):
            u, v, w = shape(R * t, a); pts.append(P(u, v, w - 0.014))
        parts.append(tube_path(f"spoke{j}", pts, 0.012 - 0.002 * (j % 2), "bone", res=4))
    rim = []
    for k in range(29):
        a = 2 * math.pi * k / 28; u, v, w = shape(R * 1.0, a); rim.append(P(u, v, w))
    parts.append(tube_path("rim", rim, 0.011, "bone", res=3))
    for k in range(13):                     # the pit: hollow teeth pointing out of the centre
        a = random.uniform(0, 2 * math.pi); r = random.uniform(0.0, 0.07)
        c = cyl(f"tooth{k}", 0.009, random.uniform(0.025, 0.055), P(r * math.cos(a), r * math.sin(a), 0.02), "bone", axis='z', seg=8, r2=0.0015)
        parts.append(c)
    # stalk joining the dish to the skull
    parts.append(tube_path("stalk", [(0, 2.36, -0.42), (0, 2.42, -0.47), C], 0.03, "bone", res=4))
    ms = [realize(p) if (p.type == 'CURVE' or p.modifiers) else p for p in parts]
    return join("dish", ms)

def lowpoly(ob, voxel):
    """Clean game mesh: coarse voxel re-mesh of the sculpt (even quads), smoothed back onto it."""
    lo = ob.copy(); lo.data = ob.data.copy(); lo.name = ob.name.replace("_hi", "_lo")
    for m in list(lo.modifiers): lo.modifiers.remove(m)
    bpy.context.scene.collection.objects.link(lo)
    bpy.ops.object.select_all(action='DESELECT'); lo.select_set(True); bpy.context.view_layer.objects.active = lo
    lo.data.remesh_voxel_size = voxel
    bpy.ops.object.voxel_remesh()
    sw = lo.modifiers.new("fit", 'SHRINKWRAP'); sw.target = ob; sw.wrap_method = 'NEAREST_SURFACEPOINT'
    sm = lo.modifiers.new("relax", 'CORRECTIVE_SMOOTH'); sm.iterations = 3; sm.use_only_smooth = True
    lo = realize(lo)
    for p in lo.data.polygons: p.use_smooth = True
    return lo

body_hi = build_body()
print("body_hi faces", len(body_hi.data.polygons))
dish_hi = build_dish()
print("dish faces", len(dish_hi.data.polygons))
body_lo = lowpoly(body_hi, 0.011)
print("body_lo faces", len(body_lo.data.polygons))
for o in (body_lo, dish_hi):
    o.data.materials.clear()
body_lo.data.materials.append(mat("M_CreatureSkin"))
# smart UV for the body (needed for baked maps)
bpy.ops.object.select_all(action='DESELECT'); body_lo.select_set(True); bpy.context.view_layer.objects.active = body_lo
bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(angle_limit=math.radians(72), island_margin=0.003)
bpy.ops.object.mode_set(mode='OBJECT')
# dish: planar UVs facing forward, and a material with veins
bpy.ops.object.select_all(action='DESELECT'); dish_hi.select_set(True); bpy.context.view_layer.objects.active = dish_hi
bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.004)
bpy.ops.object.mode_set(mode='OBJECT')
dish_hi.data.materials.append(mat("M_CreatureMembrane"))
dish_hi.name = "dish"
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "listener_work.blend"))
print("SAVED work file")
for o in list(bpy.context.scene.objects):
    o.select_set(o.name in ("body_lo", "dish"))
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "listener_preview.gltf"), export_format='GLTF_SEPARATE', use_selection=True, export_image_format='NONE')
print("EXPORTED preview")

# ================================================================== bake: normal (high -> low), AO, skin colour
def node_mat_skin(m, membrane=False):
    m.use_nodes = True; nt = m.node_tree; nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputMaterial'); bsdf = nt.nodes.new('ShaderNodeBsdfPrincipled')
    nt.links.new(bsdf.outputs[0], out.inputs[0])
    tc = nt.nodes.new('ShaderNodeTexCoord')
    n1 = nt.nodes.new('ShaderNodeTexNoise'); n1.inputs['Scale'].default_value = 5.0 if not membrane else 9.0; n1.inputs['Detail'].default_value = 8.0
    nt.links.new(tc.outputs['Object'], n1.inputs['Vector'])
    ramp = nt.nodes.new('ShaderNodeValToRGB'); nt.links.new(n1.outputs['Fac'], ramp.inputs['Fac'])
    if membrane:
        ramp.color_ramp.elements[0].color = (0.55, 0.38, 0.36, 1); ramp.color_ramp.elements[1].color = (0.78, 0.62, 0.58, 1)
    else:
        ramp.color_ramp.elements[0].color = (0.36, 0.36, 0.33, 1); ramp.color_ramp.elements[1].color = (0.66, 0.64, 0.58, 1)
    vor = nt.nodes.new('ShaderNodeTexVoronoi'); vor.feature = 'DISTANCE_TO_EDGE'; vor.inputs['Scale'].default_value = 7.0 if not membrane else 14.0
    nt.links.new(tc.outputs['Object'], vor.inputs['Vector'])
    vr = nt.nodes.new('ShaderNodeValToRGB'); nt.links.new(vor.outputs['Distance'], vr.inputs['Fac'])
    vr.color_ramp.elements[0].position = 0.0; vr.color_ramp.elements[0].color = (0.18, 0.06, 0.08, 1)
    vr.color_ramp.elements[1].position = 0.035; vr.color_ramp.elements[1].color = (1, 1, 1, 1)
    mix = nt.nodes.new('ShaderNodeMixRGB'); mix.blend_type = 'MULTIPLY'; mix.inputs['Fac'].default_value = 0.85 if not membrane else 0.95
    nt.links.new(ramp.outputs['Color'], mix.inputs[1]); nt.links.new(vr.outputs['Color'], mix.inputs[2])
    n2 = nt.nodes.new('ShaderNodeTexNoise'); n2.inputs['Scale'].default_value = 1.6; n2.inputs['Detail'].default_value = 3.0
    nt.links.new(tc.outputs['Object'], n2.inputs['Vector'])
    blot = nt.nodes.new('ShaderNodeValToRGB'); nt.links.new(n2.outputs['Fac'], blot.inputs['Fac'])
    blot.color_ramp.elements[0].position = 0.45; blot.color_ramp.elements[0].color = (0.55, 0.6, 0.55, 1)
    blot.color_ramp.elements[1].position = 0.7; blot.color_ramp.elements[1].color = (1, 1, 1, 1)
    mix2 = nt.nodes.new('ShaderNodeMixRGB'); mix2.blend_type = 'MULTIPLY'; mix2.inputs['Fac'].default_value = 1.0
    nt.links.new(mix.outputs['Color'], mix2.inputs[1]); nt.links.new(blot.outputs['Color'], mix2.inputs[2])
    nt.links.new(mix2.outputs['Color'], bsdf.inputs['Base Color'])
    return nt

def bake_target(ob, name, size, color=True):
    img = bpy.data.images.new(name, size, size, alpha=False, float_buffer=False)
    if not color: img.colorspace_settings.name = 'Non-Color'
    for m in ob.data.materials:
        nt = m.node_tree
        for n in nt.nodes:
            n.select = False
        node = nt.nodes.new('ShaderNodeTexImage'); node.image = img; node.select = True; nt.nodes.active = node
    return img

def save_img(img, path):
    img.filepath_raw = path; img.file_format = 'PNG'; img.save()
    print("BAKED", path)

if STAGE in ("bake", "all"):
    import numpy as np
    sc = bpy.context.scene; sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'; sc.cycles.use_denoising = False  # this Blender build has no OIDN
    sc.render.bake.margin = 8
    body_lo = bpy.data.objects["body_lo"]; body_hi = bpy.data.objects["body_hi"]; dish = bpy.data.objects["dish"]
    node_mat_skin(body_lo.data.materials[0]); node_mat_skin(dish.data.materials[0], True)
    SZ = 2048
    # normal map: high -> low
    sc.cycles.samples = 1
    nimg = bake_target(body_lo, "lis_normal", SZ, color=False)
    bpy.ops.object.select_all(action='DESELECT'); body_hi.select_set(True); body_lo.select_set(True); bpy.context.view_layer.objects.active = body_lo
    bpy.ops.object.bake(type='NORMAL', use_selected_to_active=True, cage_extrusion=0.015, max_ray_distance=0.04, normal_space='TANGENT')
    save_img(nimg, os.path.join(OUT, "listener_normal.png"))
    # colour (no lighting) and AO: the sculpt must not occlude the game mesh
    body_hi.hide_render = True; body_hi.hide_set(True)
    cimg = bake_target(body_lo, "lis_albedo", SZ)
    bpy.ops.object.select_all(action='DESELECT'); body_lo.select_set(True); bpy.context.view_layer.objects.active = body_lo
    bpy.ops.object.bake(type='DIFFUSE', pass_filter={'COLOR'}, use_selected_to_active=False)
    save_img(cimg, os.path.join(OUT, "listener_albedo.png"))
    # ambient occlusion
    sc.cycles.samples = 24
    aimg = bake_target(body_lo, "lis_ao", SZ, color=False)
    bpy.ops.object.bake(type='AO', use_selected_to_active=False)
    save_img(aimg, os.path.join(OUT, "listener_ao.png"))
    # dish colour + AO
    sc.cycles.samples = 1
    dimg = bake_target(dish, "dish_albedo", 1024)
    bpy.ops.object.select_all(action='DESELECT'); dish.select_set(True); bpy.context.view_layer.objects.active = dish
    bpy.ops.object.bake(type='DIFFUSE', pass_filter={'COLOR'}, use_selected_to_active=False)
    save_img(dimg, os.path.join(OUT, "dish_albedo.png"))
    sc.cycles.samples = 16
    daimg = bake_target(dish, "dish_ao", 1024, color=False)
    bpy.ops.object.bake(type='AO', use_selected_to_active=False)
    save_img(daimg, os.path.join(OUT, "dish_ao.png"))
    bpy.data.objects.remove(body_hi, do_unlink=True)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "listener_baked.blend"))
    print("SAVED baked")

# ================================================================== rig + animation
BONES = [("root", None, (0, 0, 0), (0, 0.25, 0)), ("hips", "root", "pelvis", "spine1"), ("spine", "hips", "spine1", "spine2"),
         ("chest", "spine", "spine2", "chest"), ("upperchest", "chest", "chest", "neck1"), ("neck", "upperchest", "neck1", "neck2"),
         ("head", "neck", "neck2", "head")]
for s_ in "LR":
    BONES += [(f"thigh_{s_}", "hips", f"hip_{s_}", f"knee_{s_}"), (f"shin_{s_}", f"thigh_{s_}", f"knee_{s_}", f"ankle_{s_}"),
              (f"foot_{s_}", f"shin_{s_}", f"ankle_{s_}", f"ball_{s_}"), (f"toe_{s_}", f"foot_{s_}", f"ball_{s_}", f"toe_{s_}"),
              (f"clav_{s_}", "upperchest", "chest", f"shoulder_{s_}"), (f"upperarm_{s_}", f"clav_{s_}", f"shoulder_{s_}", f"elbow_{s_}"),
              (f"forearm_{s_}", f"upperarm_{s_}", f"elbow_{s_}", f"wrist_{s_}"), (f"hand_{s_}", f"forearm_{s_}", f"wrist_{s_}", f"palm_{s_}")]
    for k in range(3):
        BONES += [(f"fing{k}a_{s_}", f"hand_{s_}", f"palm_{s_}", f"f{k}a_{s_}"), (f"fing{k}b_{s_}", f"fing{k}a_{s_}", f"f{k}a_{s_}", f"f{k}b_{s_}"),
                  (f"fing{k}c_{s_}", f"fing{k}b_{s_}", f"f{k}b_{s_}", f"f{k}c_{s_}")]

def jp(v):
    return G(*(J[v] if isinstance(v, str) else v))

if STAGE == "all":
    body = bpy.data.objects["body_lo"]; dish = bpy.data.objects["dish"]
    adata = bpy.data.armatures.new("ListenerRig"); rig = bpy.data.objects.new("ListenerRig", adata)
    bpy.context.scene.collection.objects.link(rig)
    bpy.ops.object.select_all(action='DESELECT'); rig.select_set(True); bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode='EDIT')
    eb = adata.edit_bones
    for name, parent, h, t in BONES:
        b = eb.new(name); b.head = jp(h); b.tail = jp(t)
        if (b.tail - b.head).length < 0.01: b.tail = b.head + Vector((0, 0, 0.05))
        b.align_roll(Vector((0, 1, 0)))
        if parent: b.parent = eb[parent]
    eb["head"].tail = G(0, 2.43, -0.5)
    bpy.ops.object.mode_set(mode='OBJECT')
    # skin the body (bone heat), the dish rides on the head bone
    bpy.ops.object.select_all(action='DESELECT'); body.select_set(True); rig.select_set(True); bpy.context.view_layer.objects.active = rig
    bpy.ops.object.parent_set(type='ARMATURE_AUTO')
    vg = dish.vertex_groups.new(name="head"); vg.add(list(range(len(dish.data.vertices))), 1.0, 'REPLACE')
    md = dish.modifiers.new("arm", 'ARMATURE'); md.object = rig; dish.parent = rig
    print("weights:", len(body.vertex_groups), "groups")
    # ---------------------------------------------------------- animations (in place; the game moves the node)
    FPS = 30; bpy.context.scene.render.fps = FPS
    rig.animation_data_create()
    pb = rig.pose.bones
    for p in pb: p.rotation_mode = 'XYZ'
    def pose(t, fn):
        for p in pb: p.rotation_euler = (0, 0, 0); p.location = (0, 0, 0)
        fn(t)
    def make(name, frames, fn, step=2):
        act = bpy.data.actions.new(name); rig.animation_data.action = act
        for f in list(range(0, frames, step)) + [frames]:
            pose(f / frames, fn)
            for p in pb:
                p.keyframe_insert("rotation_euler", frame=f)
                if p.name in ("root", "hips"): p.keyframe_insert("location", frame=f)
        tr = rig.animation_data.nla_tracks.new(); tr.name = name
        tr.strips.new(name, 0, act); rig.animation_data.action = None
        print("ACTION", name, frames)
    S = math.sin; Cc = math.cos; TAU = 2 * math.pi
    def legs(t, amp, lift, lean):
        for s_, ph in (("L", 0.0), ("R", 0.5)):
            a = TAU * (t + ph)
            pb[f"thigh_{s_}"].rotation_euler.x = amp * S(a) + lean * 0.5
            pb[f"shin_{s_}"].rotation_euler.x = -lift * max(0.0, S(a + 1.2)) - 0.1
            pb[f"foot_{s_}"].rotation_euler.x = 0.35 * max(0.0, -S(a)) * lift
    def arms(t, amp, raise_=0.0):
        for s_, ph in (("L", 0.5), ("R", 0.0)):
            a = TAU * (t + ph)
            pb[f"upperarm_{s_}"].rotation_euler.x = amp * S(a) + raise_
            pb[f"forearm_{s_}"].rotation_euler.x = 0.15 + 0.25 * max(0.0, S(a)) + raise_ * 0.5
            for k in range(3):
                pb[f"fing{k}a_{s_}"].rotation_euler.x = 0.15 + 0.08 * S(a * 2 + k)
    def walk(t):
        legs(t, 0.42, 0.6, 0.1); arms(t, 0.22)
        pb["root"].location.y = 0.03 * Cc(2 * TAU * t)
        pb["chest"].rotation_euler.z = 0.07 * S(TAU * t); pb["hips"].rotation_euler.z = -0.05 * S(TAU * t)
        pb["neck"].rotation_euler.x = 0.06 * S(2 * TAU * t); pb["head"].rotation_euler.z = 0.1 * S(TAU * t * 0.5)
    def run(t):
        legs(t, 0.8, 1.2, 0.35); arms(t, 0.5, 0.25)
        pb["root"].location.y = 0.06 * Cc(2 * TAU * t)
        pb["hips"].rotation_euler.x = 0.3; pb["spine"].rotation_euler.x = 0.18; pb["chest"].rotation_euler.z = 0.12 * S(TAU * t)
        pb["neck"].rotation_euler.x = -0.35; pb["head"].rotation_euler.x = -0.15
    def idle(t):
        b = S(TAU * t)
        pb["chest"].rotation_euler.x = 0.035 * b; pb["upperchest"].rotation_euler.x = 0.025 * b
        pb["neck"].rotation_euler.y = 0.18 * S(TAU * t + 0.5); pb["head"].rotation_euler.z = 0.12 * S(TAU * t * 2.0)
        for s_ in "LR":
            pb[f"upperarm_{s_}"].rotation_euler.x = 0.04 * b
            for k in range(3): pb[f"fing{k}b_{s_}"].rotation_euler.x = 0.25 + 0.2 * max(0.0, S(TAU * t * 3 + k * 1.7))
    def listen(t):
        pb["neck"].rotation_euler.y = 0.55 * S(TAU * t); pb["head"].rotation_euler.z = 0.28 * S(TAU * t + 1.0)
        pb["head"].rotation_euler.x = 0.15 * S(2 * TAU * t)
        pb["spine"].rotation_euler.x = 0.12; pb["chest"].rotation_euler.x = 0.1
        for s_ in "LR":
            pb[f"upperarm_{s_}"].rotation_euler.x = 0.3; pb[f"forearm_{s_}"].rotation_euler.x = 0.7
            for k in range(3): pb[f"fing{k}a_{s_}"].rotation_euler.x = 0.4 + 0.3 * S(TAU * t * 4 + k)
    def attack(t):
        w = min(1.0, t / 0.35); st = max(0.0, min(1.0, (t - 0.35) / 0.15)); rc = max(0.0, (t - 0.6) / 0.4)
        k = w * (1 - st)
        reach = st * (1 - rc)
        pb["spine"].rotation_euler.x = -0.25 * k + 0.45 * reach; pb["chest"].rotation_euler.x = -0.2 * k + 0.35 * reach
        pb["neck"].rotation_euler.x = -0.3 * k + 0.2 * reach
        for s_ in "LR":
            pb[f"upperarm_{s_}"].rotation_euler.x = 1.2 * k + 1.6 * reach; pb[f"forearm_{s_}"].rotation_euler.x = 0.9 * k + 0.1 * reach
            for kk in range(3): pb[f"fing{kk}a_{s_}"].rotation_euler.x = -0.4 * reach + 0.5 * k
        legs(0.25, 0.3 * reach, 0.4, 0.2)
    make("walk", 36, walk); make("run", 21, run, step=1); make("idle", 90, idle, step=3); make("listen", 75, listen, step=3); make("attack", 30, attack, step=1)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "listener_rigged.blend"))
    for o in bpy.context.scene.objects: o.select_set(o.name in ("ListenerRig", "body_lo", "dish"))
    body.name = "ListenerBody"; dish.name = "ListenerDish"
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "listener.gltf"), export_format='GLTF_SEPARATE', use_selection=True,
        export_image_format='NONE', export_animations=True, export_animation_mode='NLA_TRACKS', export_skins=True,
        export_all_influences=False, export_def_bones=False)
    print("EXPORTED listener")
