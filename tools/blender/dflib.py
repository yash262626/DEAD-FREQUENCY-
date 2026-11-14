"""Shared Blender helpers for DEAD FREQUENCY art builds (Blender 4.0, headless).
Coordinates: every function takes GODOT coordinates (x right, y up, z towards the camera); G() converts to
Blender (x, -z, y). The glTF exporter converts back, so positions match the game's level grid (2 m cells)."""
import bpy, bmesh, math, random
from mathutils import Vector, Matrix, Euler

def G(x, y, z):
    return Vector((x, -z, y))

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for c in list(bpy.data.collections): bpy.data.collections.remove(c)

def mat(name):
    return bpy.data.materials.get(name) or bpy.data.materials.new(name)

def _link(ob, coll=None):
    (coll or bpy.context.scene.collection).objects.link(ob)
    return ob

def collection(name):
    c = bpy.data.collections.get(name)
    if not c:
        c = bpy.data.collections.new(name); bpy.context.scene.collection.children.link(c)
    return c

def mesh_object(name, bm, matname, coll=None, smooth_angle=None):
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    ob = bpy.data.objects.new(name, me); _link(ob, coll)
    if isinstance(matname, (list, tuple)):
        for m in matname: me.materials.append(mat(m))
    else:
        me.materials.append(mat(matname))
    if smooth_angle is not None: autosmooth(ob, smooth_angle)
    return ob

def autosmooth(ob, angle=35):
    me = ob.data
    for p in me.polygons: p.use_smooth = True
    if hasattr(me, "use_auto_smooth"):
        me.use_auto_smooth = True; me.auto_smooth_angle = math.radians(angle)

def box(name, size, pos, matname, bevel=0.0, seg=2, rot=(0, 0, 0), coll=None):
    """Axis-aligned box: size (sx, sy, sz) and centre pos in Godot axes, rot in degrees about Godot x/y/z."""
    sx, sy, sz = size
    bm = bmesh.new(); bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts: v.co = Vector((v.co.x * sx, v.co.y * sz, v.co.z * sy))
    ob = mesh_object(name, bm, matname, coll)
    ob.location = G(*pos)
    ob.rotation_euler = Euler((math.radians(rot[0]), -math.radians(rot[2]), math.radians(rot[1])), 'XZY')
    if bevel > 0: add_bevel(ob, bevel, seg)
    return ob

def add_bevel(ob, width, seg=2, angle=40):
    m = ob.modifiers.new("bevel", 'BEVEL'); m.width = width; m.segments = seg
    m.limit_method = 'ANGLE'; m.angle_limit = math.radians(angle); m.harden_normals = True
    m.miter_outer = 'MITER_ARC'
    autosmooth(ob, 60)
    return m

def cyl(name, r, h, pos, matname, axis='y', seg=24, bevel=0.0, coll=None, r2=None, caps=True):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=caps, cap_tris=False, segments=seg, radius1=r, radius2=r if r2 is None else r2, depth=h)
    ob = mesh_object(name, bm, matname, coll)
    ob.location = G(*pos)
    if axis == 'y': pass                                # Blender z = Godot y
    elif axis == 'x': ob.rotation_euler = Euler((0, math.radians(90), 0))
    elif axis == 'z': ob.rotation_euler = Euler((math.radians(90), 0, 0))
    autosmooth(ob, 40)
    if bevel > 0: add_bevel(ob, bevel, 2, 50)
    return ob

def tube_path(name, pts, radius, matname, coll=None, res=6, bevel_res=4):
    """A pipe/cable along Godot-space points (smooth bends)."""
    cu = bpy.data.curves.new(name, 'CURVE'); cu.dimensions = '3D'
    cu.bevel_depth = radius; cu.bevel_resolution = bevel_res; cu.resolution_u = res; cu.use_fill_caps = True
    sp = cu.splines.new('BEZIER'); sp.bezier_points.add(len(pts) - 1)
    for i, p in enumerate(pts):
        bp = sp.bezier_points[i]; bp.co = G(*p); bp.handle_left_type = 'AUTO'; bp.handle_right_type = 'AUTO'
    ob = bpy.data.objects.new(name, cu); _link(ob, coll)
    cu.materials.append(mat(matname))
    return ob

def poly_tube(name, pts, radius, matname, coll=None, bevel_res=3, corner=0.0):
    """Straight segments with optional rounded corners (industrial pipes)."""
    cu = bpy.data.curves.new(name, 'CURVE'); cu.dimensions = '3D'
    cu.bevel_depth = radius; cu.bevel_resolution = bevel_res; cu.use_fill_caps = True
    sp = cu.splines.new('POLY'); sp.points.add(len(pts) - 1)
    for i, p in enumerate(pts):
        v = G(*p); sp.points[i].co = (v.x, v.y, v.z, 1)
    ob = bpy.data.objects.new(name, cu); _link(ob, coll)
    cu.materials.append(mat(matname))
    return ob

def realize(ob):
    """Apply modifiers / convert curves; returns a mesh object with the same name."""
    dg = bpy.context.evaluated_depsgraph_get()
    ev = ob.evaluated_get(dg)
    me = bpy.data.meshes.new_from_object(ev, preserve_all_data_layers=True, depsgraph=dg)
    new = bpy.data.objects.new(ob.name + "_m", me)
    for c in ob.users_collection: c.objects.link(new)
    new.matrix_world = ob.matrix_world.copy()
    name = ob.name
    bpy.data.objects.remove(ob, do_unlink=True)
    new.name = name
    return new

def realize_all(coll=None):
    obs = list((coll or bpy.context.scene.collection).all_objects)
    return [realize(o) for o in obs if o.type in ('MESH', 'CURVE')]

def world_uv(ob, scale=1.0):
    """Box-projected UVs in world metres (adjacent pieces line up; 1 UV unit = 1/scale m)."""
    me = ob.data
    if not me.uv_layers: me.uv_layers.new(name="UVMap")
    bm = bmesh.new(); bm.from_mesh(me)
    uv = bm.loops.layers.uv.active or bm.loops.layers.uv.new("UVMap")
    mw = ob.matrix_world; mn = mw.to_3x3()
    for f in bm.faces:
        n = (mn @ f.normal).normalized()
        ax = max(range(3), key=lambda i: abs(n[i]))
        for l in f.loops:
            p = mw @ l.vert.co
            if ax == 0: u, v = (p.y if n.x > 0 else -p.y), p.z
            elif ax == 1: u, v = (-p.x if n.y > 0 else p.x), p.z
            else: u, v = p.x, (p.y if n.z > 0 else -p.y)
            l[uv].uv = (u * scale, v * scale)
    bm.to_mesh(me); bm.free()

def join(name, obs):
    obs = [o for o in obs if o and o.type == 'MESH']
    if not obs: return None
    bpy.ops.object.select_all(action='DESELECT')
    for o in obs: o.select_set(True)
    bpy.context.view_layer.objects.active = obs[0]
    bpy.ops.object.join()
    ob = bpy.context.view_layer.objects.active; ob.name = name; ob.data.name = name
    return ob

def export(path, coll=None):
    bpy.ops.object.select_all(action='DESELECT')
    obs = list((coll or bpy.context.scene.collection).all_objects)
    for o in obs: o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLTF_SEPARATE', use_selection=True,
        export_texcoords=True, export_normals=True, export_apply=True, export_materials='EXPORT',
        export_image_format='NONE' if bpy.app.version >= (4, 0, 0) else 'AUTO', export_yup=True)
    print("EXPORTED", path, len(obs), "objects")

def quad(name, w, h, center, normal, matname, coll=None, up=(0, 1, 0)):
    """Single textured quad (UV 0..1) of size w x h, facing `normal` (Godot axes)."""
    n = Vector(G(*normal)).normalized(); u_ = Vector(G(*up))
    if abs(n.dot(u_.normalized())) > 0.99: u_ = Vector(G(0, 0, -1))
    right = u_.cross(n).normalized(); upv = n.cross(right).normalized()
    c = Vector(G(*center))
    bm = bmesh.new(); uv = bm.loops.layers.uv.new("UVMap")
    vs = [bm.verts.new(c + right * sx * w / 2 + upv * sy * h / 2) for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    f = bm.faces.new(vs)
    for l, t in zip(f.loops, ((0, 0), (1, 0), (1, 1), (0, 1))): l[uv].uv = t
    bm.normal_update()
    if f.normal.dot(n) < 0:
        f.normal_flip()
    return mesh_object(name, bm, matname, coll)

def orient(ob, normal):
    """Rotate so the object's local +Z (Blender) points along a Godot-space direction."""
    n = Vector(G(*normal)).normalized()
    ob.rotation_euler = Vector((0, 0, 1)).rotation_difference(n).to_euler()
    return ob

def disc(name, r, thick, center, normal, matname, seg=32, coll=None, bevel=0.0):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=seg, radius1=r, radius2=r, depth=thick)
    ob = mesh_object(name, bm, matname, coll); ob.location = G(*center); orient(ob, normal)
    autosmooth(ob, 40)
    if bevel > 0: add_bevel(ob, bevel, 2, 50)
    return ob

def prism(name, p0, p1, p3, depth, normal, matname, coll=None, bevel=0.0):
    """Parallelogram slab: corner p0, edges to p1 and p3 (Godot points), extruded `depth` against `normal`."""
    a, b, d = Vector(G(*p0)), Vector(G(*p1)), Vector(G(*p3))
    n = Vector(G(*normal)).normalized() * depth
    c = b + (d - a)
    bm = bmesh.new()
    top = [bm.verts.new(v) for v in (a, b, c, d)]
    bot = [bm.verts.new(v - n) for v in (a, b, c, d)]
    bm.faces.new(top); bm.faces.new(list(reversed(bot)))
    for i in range(4):
        j = (i + 1) % 4; bm.faces.new([top[i], bot[i], bot[j], top[j]])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    ob = mesh_object(name, bm, matname, coll)
    if bevel > 0: add_bevel(ob, bevel, 2)
    return ob
