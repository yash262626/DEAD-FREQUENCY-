"""Blender helpers for the Unreal art pipeline: scene units, fast numpy meshes, materials, cameras, lights,
EEVEE/Cycles render settings and contact sheets. Scenes use 1 Blender unit = 1 centimetre (unit scale 0.01),
which is what Unreal expects from FBX."""
import math
import os

import bpy
import numpy as np
from mathutils import Matrix, Vector


def reset_scene(cm=True):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    if cm:
        sc.unit_settings.system = "METRIC"
        sc.unit_settings.scale_length = 0.01
        sc.unit_settings.length_unit = "CENTIMETERS"
    sc.render.fps = 30
    return sc


def mesh_from_numpy(name, verts, faces, coll=None):
    """faces: (M, 3) or (M, 4) int array, or a list of arrays of mixed sizes."""
    me = bpy.data.meshes.new(name)
    verts = np.asarray(verts, np.float32)
    if isinstance(faces, (list, tuple)):
        sizes = np.concatenate([np.full(len(f), f.shape[1]) for f in faces if len(f)])
        loops = np.concatenate([f.reshape(-1) for f in faces if len(f)])
    else:
        faces = np.asarray(faces)
        sizes = np.full(len(faces), faces.shape[1])
        loops = faces.reshape(-1)
    me.vertices.add(len(verts))
    me.vertices.foreach_set("co", verts.reshape(-1))
    me.loops.add(len(loops))
    me.loops.foreach_set("vertex_index", loops.astype(np.int32))
    me.polygons.add(len(sizes))
    starts = np.concatenate([[0], np.cumsum(sizes)[:-1]]).astype(np.int32)
    me.polygons.foreach_set("loop_start", starts)
    me.update(calc_edges=True)
    me.validate(clean_customdata=False)
    ob = bpy.data.objects.new(name, me)
    (coll or bpy.context.scene.collection).objects.link(ob)
    return ob


def shade_smooth(ob):
    me = ob.data
    me.polygons.foreach_set("use_smooth", np.ones(len(me.polygons), bool))
    me.update()


def get_verts(ob):
    v = np.empty(len(ob.data.vertices) * 3, np.float32)
    ob.data.vertices.foreach_get("co", v)
    return v.reshape(-1, 3)


def set_verts(ob, v):
    ob.data.vertices.foreach_set("co", np.asarray(v, np.float32).reshape(-1))
    ob.data.update()


def get_faces(ob):
    me = ob.data
    n = np.empty(len(me.polygons), np.int32)
    me.polygons.foreach_get("loop_total", n)
    idx = np.empty(len(me.loops), np.int32)
    me.loops.foreach_get("vertex_index", idx)
    return n, idx


# ------------------------------------------------------------------------------------------------ materials

def principled(name, color=(0.8, 0.8, 0.8), rough=0.5, metal=0.0, sss=0.0, sss_radius=(1.0, 0.35, 0.2), sss_scale=1.0,
               coat=0.0, coat_rough=0.05, spec=0.5):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*color, 1.0)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    b.inputs["Subsurface Weight"].default_value = sss
    b.inputs["Subsurface Radius"].default_value = sss_radius
    b.inputs["Subsurface Scale"].default_value = sss_scale
    b.inputs["Coat Weight"].default_value = coat
    b.inputs["Coat Roughness"].default_value = coat_rough
    b.inputs["Specular IOR Level"].default_value = spec
    return m


def clay(name="Clay", color=(0.62, 0.6, 0.58)):
    return principled(name, color, rough=0.62, sss=0.0)


# ------------------------------------------------------------------------------------------------ camera and lights

def look_at(ob, target, roll=0.0):
    d = Vector(target) - ob.location
    ob.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    if roll:
        ob.rotation_euler.rotate_axis("Z", math.radians(roll))


def camera(name, loc, target, lens=50.0, ortho=None, clip_end=10000.0):
    cd = bpy.data.cameras.new(name)
    cd.lens = lens
    cd.clip_start = 1.0
    cd.clip_end = clip_end
    if ortho:
        cd.type = "ORTHO"
        cd.ortho_scale = ortho
    ob = bpy.data.objects.new(name, cd)
    bpy.context.scene.collection.objects.link(ob)
    ob.location = loc
    look_at(ob, target)
    return ob


def area_light(name, loc, target, power, size=100.0, color=(1, 1, 1), shape="DISK"):
    ld = bpy.data.lights.new(name, "AREA")
    ld.energy = power
    ld.size = size
    ld.shape = shape
    ld.color = color
    ob = bpy.data.objects.new(name, ld)
    bpy.context.scene.collection.objects.link(ob)
    ob.location = loc
    look_at(ob, target)
    return ob


def studio(target=(0, 0, 120), radius=420.0, key=1.0, dark=False):
    """Three-point studio around `target` (cm). Powers are in watts for a cm-scale scene."""
    t = Vector(target)
    # light falloff is per Blender unit: a cm-scale scene needs 10^4 times the power of a metre-scale one
    s = 2.4e6 * key * (radius / 420.0) ** 2
    area_light("Key", t + Vector((-0.75, -1.0, 0.55)) * radius, t, 3.2 * s, size=160)
    area_light("Fill", t + Vector((1.0, -0.7, 0.15)) * radius, t, 0.9 * s, size=220, color=(0.85, 0.9, 1.0))
    area_light("Rim", t + Vector((0.4, 1.1, 0.75)) * radius, t, 3.6 * s, size=120, color=(1.0, 0.95, 0.9))
    w = bpy.data.worlds.new("World")
    bpy.context.scene.world = w
    w.use_nodes = True
    bg = w.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = (0.012, 0.012, 0.014, 1) if dark else (0.05, 0.05, 0.055, 1)
    bg.inputs["Strength"].default_value = 1.0


def floor(z=0.0, size=2000.0, color=(0.06, 0.06, 0.065), rough=0.6):
    bpy.ops.mesh.primitive_plane_add(size=size, location=(0, 0, z))
    ob = bpy.context.active_object
    ob.name = "Floor"
    ob.data.materials.append(principled("FloorMat", color, rough=rough))
    return ob


# ------------------------------------------------------------------------------------------------ rendering

def eevee(res=(1600, 1600), samples=64, sss=True, bloom=False, ao=True, film_transparent=False):
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE"
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.resolution_percentage = 100
    e = sc.eevee
    e.taa_render_samples = samples
    e.use_gtao = ao
    e.gtao_distance = 40.0
    e.use_ssr = True
    e.use_soft_shadows = True
    e.shadow_cube_size = "2048"
    e.shadow_cascade_size = "4096"
    e.use_bloom = bloom
    e.sss_samples = 15 if sss else 1
    sc.render.film_transparent = film_transparent
    sc.view_settings.view_transform = "AgX"
    sc.view_settings.look = "AgX - Medium High Contrast"
    sc.render.image_settings.file_format = "PNG"


def cycles(res=(1600, 1600), samples=256, threshold=0.01):
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = samples
    sc.cycles.use_adaptive_sampling = True
    sc.cycles.adaptive_threshold = threshold
    sc.cycles.use_denoising = False
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.view_settings.view_transform = "AgX"
    sc.view_settings.look = "AgX - Medium High Contrast"


def render(path, cam=None):
    sc = bpy.context.scene
    if cam:
        sc.camera = cam
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return path


def contact_sheet(paths, out, cols, labels=None, thumb=None, bg=(10, 10, 12), quality=90):
    from PIL import Image, ImageDraw
    ims = [Image.open(p).convert("RGB") for p in paths]
    if thumb:
        ims = [im.resize(thumb, Image.LANCZOS) for im in ims]
    w, h = ims[0].size
    rows = (len(ims) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * w, rows * h), bg)
    dr = ImageDraw.Draw(sheet)
    for i, im in enumerate(ims):
        x, y = (i % cols) * w, (i // cols) * h
        sheet.paste(im, (x, y))
        if labels:
            dr.text((x + 14, y + 12), labels[i], fill=(220, 220, 220))
    sheet.save(out, quality=quality)
    return out
