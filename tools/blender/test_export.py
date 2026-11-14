import bpy, sys
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.mesh.primitive_cube_add(size=1)
o = bpy.context.active_object
o.scale = (1.0, 0.1, 0.6)
bpy.ops.object.transform_apply(scale=True)
b = o.modifiers.new("bev", "BEVEL"); b.width = 0.02; b.segments = 3; b.limit_method = 'ANGLE'
bpy.ops.object.modifier_apply(modifier="bev")
bpy.ops.object.shade_smooth()
me = o.data
me.uv_layers.new(name="UVMap")
uv2 = me.uv_layers.new(name="Lightmap")
me.uv_layers.active = uv2
bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.lightmap_pack(PREF_CONTEXT='ALL_FACES', PREF_MARGIN_DIV=0.3)
bpy.ops.object.mode_set(mode='OBJECT')
me.uv_layers.active = me.uv_layers["UVMap"]
mat = bpy.data.materials.new("M_PaintedMetal"); o.data.materials.append(mat)
bpy.ops.export_scene.gltf(filepath=sys.argv[-1], export_format='GLTF_SEPARATE', export_texcoords=True, export_normals=True, export_apply=True)
print("EXPORTED", sys.argv[-1], len(me.vertices))
