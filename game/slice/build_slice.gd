extends SceneTree
# Builds res://slice/Slice.tscn — the vertical slice's art scene — from the Blender exports (res://slice/art)
# and the CC0 Poly Haven models (res://assets/models). Static meshes get lightmap UVs (xatlas) and are saved
# under res://slice/meshes; materials under res://slice/materials.
#   1. godot3 --path game -s res://slice/build_slice.gd            (DF_REBUILD=1 regenerates cached meshes)
#   2. DF_BAKE=res://slice/Slice.tscn godot3 --path game --editor   (bakes the lightmap through addons/df_tools)

const OUT := "res://slice/Slice.tscn"
var art: Spatial
var mats := {}
var mesh_cache := {}
var n_meshes := 0
var uid := 0

# name: [texture set, tint, repeats per metre, roughness x, metallic x, normal scale]
const SURF = {
	"M_CorrLower": ["textures/PaintedPlaster006", Color(0.47, 0.56, 0.53), 0.5, 1.0, 0.0, 1.0],
	"M_CorrStripe": ["textures/PaintedPlaster017", Color(0.15, 0.17, 0.17), 0.6, 0.9, 0.0, 0.6],
	"M_CorrUpper": ["assets/surfaces/dirty_concrete", Color(0.86, 0.86, 0.84), 0.3, 1.0, 0.0, 1.0],
	"M_CorrFloor": ["assets/surfaces/concrete_floor_worn_001", Color(0.95, 0.95, 0.95), 0.38, 1.0, 0.0, 1.0],
	"M_CorrCeil": ["assets/surfaces/concrete_wall_006", Color(0.62, 0.62, 0.6), 0.3, 1.0, 0.0, 1.0],
	"M_Beam": ["assets/surfaces/dirty_concrete", Color(0.78, 0.78, 0.76), 0.6, 1.0, 0.0, 1.0],
	"M_ChannelBottom": ["assets/surfaces/dirty_concrete", Color(0.22, 0.21, 0.2), 1.0, 0.5, 0.0, 1.0],
	"M_Grate": ["assets/surfaces/rusty_metal_02", Color(0.5, 0.42, 0.38), 3.0, 1.0, 1.0, 1.0],
	"M_FloorPaint": ["textures/PaintedPlaster006", Color(0.85, 0.66, 0.12), 1.2, 0.85, 0.0, 0.6],
	"M_DuctInside": ["assets/surfaces/metal_plate_02", Color(0.25, 0.25, 0.25), 1.0, 1.0, 1.0, 1.0],
	"M_Steel": ["textures/Metal063", Color(0.75, 0.75, 0.75), 2.0, 0.9, 1.0, 1.0],
	"M_PipeGreen": ["assets/surfaces/green_metal_rust", Color(0.9, 1.0, 0.95), 1.2, 1.0, 1.0, 1.0],
	"M_PipeRed": ["assets/surfaces/rusty_metal_02", Color(0.72, 0.13, 0.1), 1.2, 0.9, 0.6, 1.0],
	"M_PipeGrey": ["textures/Metal063", Color(0.55, 0.56, 0.57), 1.5, 1.0, 1.0, 1.0],
	"M_PipeFlange": ["assets/surfaces/rusty_metal_02", Color(0.42, 0.4, 0.38), 2.0, 1.0, 1.0, 1.0],
	"M_ValveRed": ["textures/PaintedPlaster017", Color(0.55, 0.05, 0.04), 2.0, 0.55, 0.0, 0.5],
	"M_TrayGalv": ["textures/Metal063", Color(0.95, 0.95, 0.95), 2.0, 0.65, 1.0, 1.0],
	"M_CableBlack": ["textures/Rubber004", Color(0.45, 0.45, 0.45), 4.0, 0.75, 0.0, 0.6],
	"M_CableGrey": ["textures/Rubber004", Color(1.4, 1.4, 1.4), 4.0, 0.7, 0.0, 0.6],
	"M_PaintGrey": ["textures/PaintedPlaster017", Color(0.42, 0.45, 0.46), 1.5, 0.6, 0.0, 0.5],
	"M_DoorFrame": ["assets/surfaces/green_metal_rust", Color(0.42, 0.5, 0.56), 1.0, 0.9, 0.7, 1.0],
	"M_DoorSteel": ["assets/surfaces/green_metal_rust", Color(0.72, 0.8, 0.8), 0.8, 0.9, 0.7, 1.0],
	"M_RoomLower": ["textures/PaintedPlaster017", Color(0.33, 0.39, 0.43), 0.5, 0.75, 0.0, 0.7],
	"M_RoomStripe": ["textures/PaintedPlaster017", Color(0.11, 0.12, 0.13), 0.6, 0.7, 0.0, 0.6],
	"M_RoomUpper": ["textures/Concrete034", Color(0.80, 0.84, 0.80), 0.4, 1.0, 0.0, 0.8],
	"M_VoidFloor": ["assets/surfaces/dirty_concrete", Color(0.3, 0.3, 0.3), 0.5, 1.0, 0.0, 1.0],
	"M_RaisedTile": ["textures/Tiles043", Color(0.46, 0.48, 0.48), 1.6667, 0.75, 0.0, 0.6],
	"M_Pedestal": ["textures/Metal063", Color(0.7, 0.7, 0.7), 3.0, 1.0, 1.0, 1.0],
	"M_CeilTile": ["assets/surfaces/ceiling_interior", Color(1.25, 1.22, 1.15), 1.6667, 1.0, 0.0, 0.8],
	"M_RackPaint": ["textures/PaintedPlaster017", Color(0.2, 0.22, 0.24), 1.5, 0.55, 0.0, 0.4],
	"M_RackFront": ["textures/PaintedPlaster017", Color(0.48, 0.5, 0.5), 2.0, 0.5, 0.0, 0.35],
	"M_BeigePlastic": ["textures/PaintedPlaster017", Color(0.74, 0.7, 0.6), 2.0, 0.45, 0.0, 0.25],
	"M_BeigeDark": ["textures/PaintedPlaster017", Color(0.5, 0.47, 0.41), 2.0, 0.45, 0.0, 0.25],
	"M_BlackPlastic": ["textures/Rubber004", Color(0.35, 0.35, 0.36), 3.0, 0.55, 0.0, 0.3],
	"M_KnobBlack": ["textures/Rubber004", Color(0.25, 0.25, 0.26), 6.0, 0.45, 0.0, 0.3],
	"M_KnobAlu": ["textures/Metal063", Color(0.9, 0.9, 0.9), 4.0, 0.5, 1.0, 0.5],
	"M_ReelMetal": ["textures/Metal063", Color(0.85, 0.86, 0.88), 3.0, 0.35, 1.0, 0.4],
	"M_FrameAlu": ["textures/Metal063", Color(0.7, 0.7, 0.72), 2.0, 0.55, 1.0, 0.4],
	"M_DeskTop": ["textures/PaintedPlaster017", Color(0.5, 0.48, 0.44), 1.0, 0.5, 0.0, 0.3],
	"M_ChairFabric": ["textures/Fabric086", Color(0.22, 0.25, 0.3), 3.0, 1.0, 0.0, 1.0],
	"M_Grille": ["textures/MetalWalkway014", Color(0.3, 0.3, 0.3), 6.0, 0.7, 1.0, 1.0],
	"M_TapePack": ["textures/Rubber004", Color(0.32, 0.2, 0.12), 6.0, 0.4, 0.0, 0.2],
	"M_CableRed": ["textures/Rubber004", Color(1.2, 0.18, 0.12), 6.0, 0.6, 0.0, 0.3],
	"M_CableBlue": ["textures/Rubber004", Color(0.2, 0.35, 1.2), 6.0, 0.6, 0.0, 0.3],
	"M_CableYellow": ["textures/Rubber004", Color(1.4, 1.1, 0.2), 6.0, 0.6, 0.0, 0.3],
	"M_BtnGrey": ["textures/Rubber004", Color(0.9, 0.9, 0.88), 6.0, 0.5, 0.0, 0.2],
	"M_BtnRed": ["textures/Rubber004", Color(1.3, 0.15, 0.1), 6.0, 0.5, 0.0, 0.2],
	"M_ClockHand": ["textures/Rubber004", Color(0.1, 0.1, 0.1), 6.0, 0.4, 0.0, 0.1],
	"M_JackHole": ["textures/Rubber004", Color(0.05, 0.05, 0.05), 6.0, 0.8, 0.0, 0.1],
	"M_TBar": ["textures/PaintedPlaster017", Color(0.9, 0.9, 0.88), 2.0, 0.45, 0.2, 0.3],
	"M_TrofferHousing": ["textures/PaintedPlaster017", Color(0.85, 0.85, 0.83), 2.0, 0.45, 0.2, 0.3],
}

func _initialize():
	art = Spatial.new(); art.name = "Slice"
	get_root().add_child(art)
	var t0 = OS.get_ticks_msec()
	_shell()
	_dress()
	_props()
	_colliders()
	_lights()
	_atmosphere()
	_probes_and_lightmap()
	_environment()
	_cameras()
	var ps = PackedScene.new()
	_own(art)
	var err = ps.pack(art)
	printerr("pack ", err, " save ", ResourceSaver.save(OUT, ps), " meshes ", n_meshes, " in ", (OS.get_ticks_msec() - t0) / 1000.0, " s")
	quit()

func _own(n):
	for c in n.get_children():
		c.owner = art
		_own(c)

# ------------------------------------------------------------------ materials
func _tex(path: String) -> Array:
	if path.begins_with("assets/"):
		return [load("res://%s/diff.jpg" % path), load("res://%s/nor_gl.jpg" % path), load("res://%s/arm.jpg" % path)]
	return [load("res://%s/albedo.jpg" % path), load("res://%s/normal.jpg" % path), load("res://%s/orm.jpg" % path)]

func _mat(name: String) -> Material:
	if mats.has(name): return mats[name]
	if name == "M_CorrFloor":
		# wet concrete: pools and streaks that mirror the lamps
		var t = _tex("assets/surfaces/concrete_floor_worn_001")
		var sm = ShaderMaterial.new(); sm.shader = load("res://slice/shaders/wet_surface.shader")
		sm.set_shader_param("albedo_tex", t[0]); sm.set_shader_param("normal_tex", t[1]); sm.set_shader_param("arm_tex", t[2])
		sm.set_shader_param("wet_mask", load("res://slice/tex/wet_mask.png")); sm.set_shader_param("tint", Color(0.95, 0.95, 0.95))
		sm.set_shader_param("uv_scale", 0.38); sm.resource_name = name
		ResourceSaver.save("res://slice/materials/M_CorrFloor.tres", sm)
		mats[name] = load("res://slice/materials/M_CorrFloor.tres")
		return mats[name]
	var m = SpatialMaterial.new()
	match name:
		"M_TrofferOn":
			m.albedo_color = Color(0.9, 0.93, 0.95); m.emission_enabled = true; m.emission = Color(0.9, 0.95, 1.0); m.emission_energy = 2.6; m.roughness = 0.3
		"M_TrofferOff":
			m.albedo_color = Color(0.55, 0.57, 0.56); m.roughness = 0.25
		"M_WiredGlass":
			m.flags_transparent = true; m.albedo_texture = load("res://slice/tex/wired_glass.png"); m.roughness = 0.12; m.metallic_specular = 0.6
		"M_LED_Green", "M_LED_Red", "M_LED_Amber", "M_BeaconRed":
			var c = {"M_LED_Green": Color(0.3, 1.0, 0.4), "M_LED_Red": Color(1.0, 0.12, 0.08), "M_LED_Amber": Color(1.0, 0.6, 0.12), "M_BeaconRed": Color(1.0, 0.1, 0.06)}[name]
			m.albedo_color = c; m.emission_enabled = true; m.emission = c; m.emission_energy = 2.5 if name != "M_BeaconRed" else 0.6; m.roughness = 0.2
		"M_LED_Off":
			m.albedo_color = Color(0.08, 0.06, 0.05); m.roughness = 0.2
		"M_CRT_Log", "M_CRT_Wave", "M_DialGlass", "M_Meter":
			var tx = {"M_CRT_Log": "crt_log", "M_CRT_Wave": "crt_wave", "M_DialGlass": "dial", "M_Meter": "meter"}[name]
			m.albedo_texture = load("res://slice/tex/%s.png" % tx); m.emission_enabled = true; m.emission_texture = m.albedo_texture
			m.emission_energy = {"M_CRT_Log": 1.6, "M_CRT_Wave": 1.6, "M_DialGlass": 1.4, "M_Meter": 0.35}[name]
			m.roughness = 0.35
		"M_CRTGlass":
			m.flags_transparent = true; m.albedo_color = Color(0.02, 0.03, 0.03, 0.18); m.roughness = 0.05; m.metallic_specular = 0.9
		"M_Label", "M_Keys", "M_Chart", "M_Clock", "M_Paper0", "M_Paper1", "M_Paper2", "M_SignComms", "M_SignStorage", "M_SignBattery", "M_SignStair", "M_SignCommsDoor", "M_SignRF":
			var tx = {"M_Label": "label", "M_Keys": "keys", "M_Chart": "chart", "M_Clock": "clock", "M_Paper0": "paper0", "M_Paper1": "paper1", "M_Paper2": "paper2",
				"M_SignComms": "sign_comms", "M_SignStorage": "sign_storage", "M_SignBattery": "sign_battery", "M_SignStair": "sign_stair", "M_SignCommsDoor": "sign_comms_door", "M_SignRF": "sign_rf"}[name]
			m.albedo_texture = load("res://slice/tex/%s.png" % tx); m.roughness = 0.7 if not name.begins_with("M_Paper") else 0.85
			if name == "M_Clock": m.flags_transparent = false; m.params_use_alpha_scissor = true; m.params_alpha_scissor_threshold = 0.5
			if name.begins_with("M_Paper"): m.params_cull_mode = SpatialMaterial.CULL_DISABLED
		"M_Hazard", "M_HazardFrame":
			m.albedo_texture = load("res://slice/tex/hazard.png"); m.roughness = 0.65
			m.uv1_scale = Vector3(1.5, 1.5, 1.5) if name == "M_Hazard" else Vector3(1.2, 1.2, 1.2)
			var t = _tex("textures/PaintedPlaster017"); m.normal_enabled = true; m.normal_texture = t[1]; m.normal_scale = 0.5
		_:
			var s = SURF.get(name)
			if s == null:
				printerr("no material spec for ", name); m.albedo_color = Color(1, 0, 1)
			else:
				var t = _tex(s[0])
				m.albedo_texture = t[0]; m.albedo_color = s[1]
				m.normal_enabled = true; m.normal_texture = t[1]; m.normal_scale = s[5]
				m.roughness_texture = t[2]; m.roughness_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_GREEN; m.roughness = s[3]
				m.metallic_texture = t[2]; m.metallic_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_BLUE; m.metallic = s[4]
				m.ao_enabled = true; m.ao_texture = t[2]; m.ao_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_RED; m.ao_light_affect = 0.25
				m.uv1_scale = Vector3(s[2], s[2], s[2])
	m.resource_name = name
	var p = "res://slice/materials/%s.tres" % name
	ResourceSaver.save(p, m)
	mats[name] = load(p)
	return mats[name]

# ------------------------------------------------------------------ meshes
func _unwrapped(mesh: Mesh, key: String, basis: Basis, texel: float, remap := false) -> Mesh:
	var path = "res://slice/meshes/%s.mesh" % key
	if mesh_cache.has(path): return mesh_cache[path]
	if not OS.has_environment("DF_REBUILD") and ResourceLoader.exists(path):
		mesh_cache[path] = load(path); return mesh_cache[path]
	var am = ArrayMesh.new()
	for i in mesh.get_surface_count():
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh.surface_get_arrays(i))
		var sm = mesh.surface_get_material(i)
		if remap and sm: sm = _mat(sm.resource_name)
		am.surface_set_material(i, sm)
	var err = am.lightmap_unwrap(Transform(basis, Vector3()), texel)
	if err != OK: printerr("unwrap failed ", key, " err ", err)
	ResourceSaver.save(path, am)
	mesh_cache[path] = load(path)
	return mesh_cache[path]

func _xf_rel(node: Node, ancestor: Node) -> Transform:
	var t = Transform()
	var n = node
	while n != ancestor and n != null:
		if n is Spatial: t = n.transform * t
		n = n.get_parent()
	return t

func _meshes_under(n: Node, out: Array) -> Array:
	if n is MeshInstance and n.mesh: out.append(n)
	for c in n.get_children(): _meshes_under(c, out)
	return out

func _add_mesh(parent: Node, name: String, mesh: Mesh, xf: Transform, collide := false) -> MeshInstance:
	var mi = MeshInstance.new(); mi.name = name; mi.mesh = mesh; mi.transform = xf
	mi.use_in_baked_light = true
	parent.add_child(mi); n_meshes += 1
	if collide:
		var sb = StaticBody.new(); sb.name = name + "_col"; parent.add_child(sb)
		var cs = CollisionShape.new(); cs.shape = mesh.create_trimesh_shape(); sb.add_child(cs); sb.transform = xf
	return mi

func _shell():
	var s = load("res://slice/art/slice_shell.gltf").instance()
	var g = Spatial.new(); g.name = "Shell"; art.add_child(g)
	for mi in _meshes_under(s, []):
		var xf = _xf_rel(mi, s)
		var texel = 0.07 if mi.name.begins_with(("room_floor")) else 0.06
		var m = _unwrapped(mi.mesh, "shell_" + mi.name, xf.basis, texel, true)
		_add_mesh(g, mi.name, m, xf, mi.name in ["corridor_arch", "corridor_doors", "room_arch"])
	s.free()

func _dress():
	var s = load("res://slice/art/slice_dress.gltf").instance()
	var g = Spatial.new(); g.name = "Dress"; art.add_child(g)
	for mi in _meshes_under(s, []):
		var xf = _xf_rel(mi, s)
		var m = _unwrapped(mi.mesh, "dress_" + mi.name, xf.basis, 0.03, true)
		_add_mesh(g, mi.name, m, xf)
	s.free()

func _colliders():
	var sb = StaticBody.new(); sb.name = "PropColliders"; art.add_child(sb)
	for b in [[Vector3(23.25, 1.0, 2.45), Vector3(3.9, 2.0, 0.9)], [Vector3(33.58, 0.65, 7.0), Vector3(0.86, 1.3, 8.0)],
			[Vector3(27.05, 0.6, 7.0), Vector3(0.96, 1.2, 2.5)], [Vector3(27.5, 0.4, 11.45), Vector3(2.0, 0.8, 0.95)],
			[Vector3(21.0, 0.95, 11.7), Vector3(1.15, 1.9, 0.5)], [Vector3(20.4, 0.95, 9.6), Vector3(0.6, 1.9, 0.95)]]:
		var cs = CollisionShape.new(); var bx = BoxShape.new(); bx.extents = b[1] / 2; cs.shape = bx; cs.translation = b[0]; sb.add_child(cs)

# ------------------------------------------------------------------ CC0 models
func _place(id: String, sub, pos: Vector3, rot_y: float, snap := "", opts := {}) -> Spatial:
	var scene = load("res://assets/models/%s/%s.gltf" % [id, id]).instance()
	var subs = []
	if typeof(sub) == TYPE_ARRAY: subs = sub
	elif sub != "": subs = [sub]
	var srcs = []
	if subs.empty(): srcs = [scene]
	else:
		for nm in subs:
			var f = scene.find_node(nm, true, false)
			if f: srcs.append(f)
			else: printerr("no node ", nm, " in ", id)
	uid += 1
	var g = Spatial.new(); g.name = "%s_%d" % [id, uid]; art.get_node("Props").add_child(g)
	var base_inv = Transform() if subs.empty() else srcs[0].transform.affine_inverse()
	var sc = opts.get("scale", 1.0)
	var place = Transform(Basis(Vector3.UP, deg2rad(rot_y)).scaled(Vector3(sc, sc, sc)), Vector3())
	var aabb = null
	var k = 0
	for src in srcs:
		for mi in _meshes_under(src, []):
			var rel = base_inv * _xf_rel(mi, scene)
			var xf = place * rel
			var key = "%s__%s" % [id, mi.name]
			var m = _unwrapped(mi.mesh, key, xf.basis, opts.get("texel", 0.035))
			var n = _add_mesh(g, "%s_%d" % [mi.name, k], m, xf); k += 1
			for si in opts.get("override", {}):
				for i in m.get_surface_count():
					var sm = m.surface_get_material(i)
					if sm and sm.resource_name == si: n.set_surface_material(i, opts.override[si])
			var a = xf.xform(m.get_aabb())
			aabb = a if aabb == null else aabb.merge(a)
	scene.free()
	# snap the group to floor / wall / ceiling
	var off = pos
	if aabb != null:
		var c = aabb.position + aabb.size * 0.5
		match snap:
			"floor": off = pos - Vector3(c.x, aabb.position.y, c.z)
			"ceil": off = pos - Vector3(c.x, aabb.end.y, c.z)
			"wall":
				var f = Basis(Vector3.UP, deg2rad(rot_y)).z      # model front (+Z) after rotation
				var back = c - Vector3(f.x * aabb.size.x, 0, f.z * aabb.size.z) * 0.5
				off = pos - Vector3(back.x, c.y, back.z)
			_: off = pos
	g.translation = off
	g.set_meta("aabb", AABB(aabb.position + off, aabb.size) if aabb != null else AABB())
	return g

func _emissive(col: Color, e: float) -> SpatialMaterial:
	var m = SpatialMaterial.new(); m.albedo_color = col; m.emission_enabled = true; m.emission = col; m.emission_energy = e
	m.roughness = 0.2
	return m

func _props():
	var P = Spatial.new(); P.name = "Props"; art.add_child(P)
	var lamp_glass = _emissive(Color(1.0, 0.85, 0.62), 2.2)
	# --- corridor: bulkhead lamps on pilasters (lights added in _lights)
	_place("industrial_wall_lamp", "", Vector3(5.86, 2.2, 10.0), -90, "wall", {"override": {"industrial_wall_lamp_glass": lamp_glass}})
	_place("industrial_wall_lamp", "", Vector3(4.14, 2.2, 14.0), 90, "wall", {"override": {"industrial_wall_lamp_glass": lamp_glass}})
	_place("industrial_wall_lamp", "", Vector3(5.86, 2.2, 18.0), -90, "wall")          # dead lamp
	_place("industrial_wall_lamp", "", Vector3(4.0, 2.2, 19.8), 90, "wall", {"override": {"industrial_wall_lamp_glass": lamp_glass}})
	var red_glass = _emissive(Color(1.0, 0.1, 0.05), 3.0)
	var dead_tube = SpatialMaterial.new(); dead_tube.albedo_color = Color(0.55, 0.56, 0.55); dead_tube.roughness = 0.3
	for p in [[Vector3(9.4, 2.25, 6.14), 0], [Vector3(13.4, 2.25, 7.86), 180], [Vector3(17.1, 2.25, 6.14), 0]]:
		_place("industrial_wall_lamp", "", p[0], p[1], "wall", {"override": {"industrial_wall_lamp_glass": red_glass}})
	_place("mounted_fluorescent_lights", "mounted_fluorescent_lights_d", Vector3(9.6, 3.2, 7.0), 90, "ceil", {"override": {"mounted_fluorescent_lights_glass": dead_tube}})
	_place("mounted_fluorescent_lights", "mounted_fluorescent_lights_b", Vector3(16.6, 3.2, 7.0), 90, "ceil", {"override": {"mounted_fluorescent_lights_glass": dead_tube}})
	_place("caged_hanging_light", "", Vector3(17.3, 3.2, 7.25), 20, "ceil")
	_place("korean_fire_extinguisher_01", "", Vector3(4.22, 0.0, 16.7), 90, "floor")
	_place("fire_alarm", "", Vector3(4.0, 1.45, 15.9), 90, "wall")
	_place("utility_box_02", "", Vector3(9.9, 0.0, 6.0), 0, "floor")
	_place("power_box_01", "", Vector3(18.7, 1.25, 6.0), 0, "wall")
	_place("security_camera_01", "", Vector3(4.3, 2.75, 6.25), 135, "")
	_place("WetFloorSign_01", "", Vector3(5.25, 0.0, 17.4), 30, "floor")
	_place("metal_trash_can", ["metal_trash_can_rust", "metal_trash_can_rust_lid", "metal_trash_can_rust_handle_left", "metal_trash_can_rust_handle_right"], Vector3(15.2, 0.0, 6.4), 0, "floor")
	_place("cardboard_box_01", "", Vector3(4.35, 0.0, 11.05), 8, "floor")
	_place("cardboard_box_01", "", Vector3(4.33, 0.34, 11.0), -14, "floor")
	_place("metal_toolbox", "", Vector3(13.2, 0.0, 7.62), 75, "floor")
	_place("old_gas_mask", "", Vector3(5.92, 1.25, 20.6), -90, "wall")
	# --- communications room
	_place("metal_office_desk", "", Vector3(27.5, 0.0, 11.45), 180, "floor")
	_place("classic_laptop", "", Vector3(27.1, 0.79, 11.5), 160, "floor")
	_place("desk_lamp_arm_01", "", Vector3(28.25, 0.79, 11.65), 200, "floor", {"override": {"desk_lamp_arm_01_light": _emissive(Color(1.0, 0.8, 0.55), 3.0)}})
	_place("clipboard", "", Vector3(26.4, 0.79, 11.35), 100, "floor")
	_place("office_notepads", "office_notepads_a4_stack", Vector3(28.0, 0.79, 11.2), 10, "floor")
	_place("cassette_player", "", Vector3(26.85, 0.79, 11.15), 170, "floor")
	_place("metal_stool_01", "", Vector3(25.3, 0.0, 10.2), 30, "floor")
	_place("drawer_cabinet", "", Vector3(21.0, 0.0, 11.7), 180, "floor")
	_place("worn_metal_rack", "", Vector3(20.35, 0.0, 9.6), 90, "floor")
	_place("cardboard_box_01", "", Vector3(20.4, 0.9, 9.4), 85, "floor")
	_place("retro_multimeter", "", Vector3(20.35, 1.44, 9.95), 70, "floor")
	_place("power_box_01", "", Vector3(20.0, 1.3, 3.4), 90, "wall")
	_place("fire_alarm", "", Vector3(20.0, 1.45, 5.4), 90, "wall")
	_place("korean_fire_extinguisher_01", "", Vector3(20.25, 0.0, 8.35), 100, "floor")
	_place("vintage_radio_transceiver", "", Vector3(26.85, 0.78, 6.5), -90, "floor", {"texel": 0.02})
	_place("vintage_spacecraft_instrument", "", Vector3(26.88, 0.78, 7.32), -80, "floor")
	_place("Television_01", "", Vector3(20.45, 1.35, 9.7), 90, "floor")
	_place("metal_toolbox", "", Vector3(32.4, 0.0, 11.4), 200, "floor")
	_place("utility_box_01", "", Vector3(33.7, 0.0, 2.45), -90, "floor")

# ------------------------------------------------------------------ lights
func _light(kind: String, pos: Vector3, col: Color, energy: float, rng: float, baked := true, extra := {}) -> Light:
	var l
	if kind == "spot":
		l = SpotLight.new(); l.spot_range = rng; l.spot_angle = extra.get("angle", 60.0); l.spot_angle_attenuation = extra.get("att", 1.0)
		l.spot_attenuation = extra.get("dist_att", 1.4)
	else:
		l = OmniLight.new(); l.omni_range = rng; l.omni_attenuation = extra.get("dist_att", 1.6)
	l.translation = pos; l.light_color = col; l.light_energy = energy
	l.light_indirect_energy = extra.get("indirect", 1.0)
	l.light_bake_mode = Light.BAKE_ALL if baked else Light.BAKE_INDIRECT
	l.shadow_enabled = not baked
	if extra.has("rot"): l.rotation_degrees = extra.rot
	if extra.has("name"): l.name = extra.name
	art.get_node("Lights").add_child(l)
	return l

func _lights():
	var L = Spatial.new(); L.name = "Lights"; art.add_child(L)
	var warm = Color(1.0, 0.82, 0.6); var cool = Color(0.82, 0.92, 1.0)
	_light("omni", Vector3(5.55, 2.15, 10.0), warm, 1.5, 6.5)
	_light("omni", Vector3(4.45, 2.15, 14.0), warm, 1.5, 6.5)
	var red = Color(1.0, 0.13, 0.07)
	_light("omni", Vector3(9.4, 2.2, 6.42), red, 1.9, 7.5)
	_light("omni", Vector3(13.4, 2.2, 7.58), red, 1.9, 7.5)
	_light("omni", Vector3(17.1, 2.2, 6.42), red, 1.6, 6.5)
	_light("omni", Vector3(17.3, 2.42, 7.25), Color(1.0, 0.78, 0.5), 1.0, 5.0, false, {"name": "HangLamp"})
	var bc = _light("spot", Vector3(20.2, 2.62, 7.0), Color(1.0, 0.08, 0.04), 3.0, 11.0, false, {"name": "Beacon", "angle": 32.0, "rot": Vector3(-12, 0, 0)})
	bc.light_bake_mode = Light.BAKE_DISABLED; bc.shadow_enabled = true; bc.visible = false
	_light("omni", Vector3(19.4, 2.55, 7.0), Color(1.0, 0.12, 0.08), 0.35, 3.0, true, {"name": "DoorRed"})
	_light("omni", Vector3(4.32, 2.15, 19.8), warm, 1.3, 6.0)
	# room: troffers that work, CRT glow, desk lamp, receiver dial
	for p in [Vector3(23, 2.95, 5), Vector3(31, 2.95, 9)]:
		_light("spot", p, Color(0.88, 0.94, 1.0), 2.2, 7.5, true, {"rot": Vector3(-90, 0, 0), "angle": 80.0, "att": 0.6})
	_light("spot", Vector3(27, 2.95, 9), Color(0.88, 0.94, 1.0), 1.8, 7.5, false, {"rot": Vector3(-90, 0, 0), "angle": 80.0, "att": 0.6, "name": "TrofferFlicker"})
	_light("spot", Vector3(28.15, 1.32, 11.5), Color(1.0, 0.78, 0.52), 3.0, 3.0, true, {"rot": Vector3(-70, 180, 0), "angle": 40.0})
	for z in [4.6, 6.9, 9.2]:
		_light("omni", Vector3(33.05, 0.98, z), Color(0.4, 1.0, 0.6), 0.4, 2.6)
	_light("omni", Vector3(26.85, 1.15, 7.0), Color(1.0, 0.62, 0.25), 0.7, 2.8)

func _atmosphere():
	var B = Spatial.new(); B.name = "Beams"; art.add_child(B)
	var fx = load("res://scripts/fx.gd")
	for p in [Vector3(23, 2.98, 5), Vector3(31, 2.98, 9)]:          # working troffers
		var b = fx.beam(B, 0.42, 1.25, 2.85, Color(0.85, 0.92, 1.0), 0.045); b.translation = p
	for p in [[Vector3(9.4, 2.2, 6.3), 1.0], [Vector3(13.4, 2.2, 7.7), -1.0], [Vector3(17.1, 2.2, 6.3), 1.0]]:   # red emergency lamps
		var b = fx.beam(B, 0.08, 0.95, 2.0, Color(1.0, 0.15, 0.08), 0.06); b.translation = p[0]; b.rotation_degrees = Vector3(38 * p[1], 0, 0)
	for p in [[Vector3(5.55, 2.15, 10.0), -1.0], [Vector3(4.45, 2.15, 14.0), 1.0], [Vector3(4.32, 2.15, 19.8), 1.0]]:   # bulkhead lamps
		var b = fx.beam(B, 0.08, 0.9, 1.9, Color(1.0, 0.85, 0.62), 0.05); b.translation = p[0]; b.rotation_degrees = Vector3(0, 0, -38 * p[1])
	# puddles (reflective, not baked) and effect markers the level turns into particles
	var W = Spatial.new(); W.name = "Wet"; art.add_child(W)
	for p in [[Vector3(5.25, 0.004, 17.0), 1.4, 0], [Vector3(4.75, 0.004, 13.4), 0.9, 1], [Vector3(12.7, 0.004, 7.35), 1.1, 0], [Vector3(31.2, 0.004, 4.0), 1.2, 1]]:
		var q = MeshInstance.new(); var pm = PlaneMesh.new(); pm.size = Vector2(p[1], p[1] * 0.8); q.mesh = pm
		var m = SpatialMaterial.new(); m.flags_transparent = true; m.albedo_texture = load("res://slice/tex/puddle%d.png" % p[2])
		m.albedo_color = Color(0.03, 0.033, 0.035); m.roughness = 0.03; m.metallic_specular = 1.0
		m.normal_enabled = true; m.normal_texture = load("res://assets/surfaces/concrete_floor_worn_001/nor_gl.jpg"); m.normal_scale = 0.15
		q.material_override = m; q.translation = p[0]; q.rotation_degrees.y = p[1] * 40.0; q.use_in_baked_light = false
		q.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF; W.add_child(q)
	_decals()
	var F = Spatial.new(); F.name = "FX"; art.add_child(F)
	for m in [["steam_valve", Vector3(4.42, 2.72, 12.6)], ["drip_1", Vector3(4.75, 3.17, 13.4)], ["drip_2", Vector3(5.3, 3.17, 16.9)], ["drip_3", Vector3(31.2, 2.98, 4.0)]]:
		var p3 = Position3D.new(); p3.name = m[0]; p3.translation = m[1]; F.add_child(p3)

func _decal(parent: Node, tex: String, size: Vector2, pos: Vector3, normal: Vector3, spin := 0.0, wet := false):
	# a textured quad 3 mm off the surface (Godot 3 has no projected decals)
	var q = MeshInstance.new(); var qm = QuadMesh.new(); qm.size = size; q.mesh = qm
	var m = SpatialMaterial.new(); m.flags_transparent = true; m.albedo_texture = load("res://slice/tex/%s.png" % tex)
	m.roughness = 0.12 if wet else 0.75; m.metallic_specular = 0.7 if wet else 0.4
	q.material_override = m; q.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF; q.use_in_baked_light = false
	parent.add_child(q)
	var up = Vector3.UP if abs(normal.y) < 0.9 else Vector3.FORWARD
	q.transform = Transform(Basis(), pos + normal * 0.003).looking_at(pos + normal * 0.003 - normal, up)
	q.rotate_object_local(Vector3.FORWARD, deg2rad(spin))

func _decals():
	var D = Spatial.new(); D.name = "Decals"; art.add_child(D)
	# water leaking down the walls
	for d in [[Vector3(4.0, 2.35, 12.6), Vector3.RIGHT], [Vector3(6.0, 2.2, 16.9), Vector3.LEFT], [Vector3(11.6, 2.25, 6.0), Vector3.BACK], [Vector3(32.2, 1.9, 2.0), Vector3.BACK]]:
		_decal(D, "decal_leak", Vector2(0.7, 2.1), d[0], d[1], 0.0, true)
	# rust running from the pipe flanges
	for z in [16.0, 13.0, 10.0, 19.0]:
		_decal(D, "decal_rust", Vector2(0.35, 1.0), Vector3(4.0, 2.25, z), Vector3.RIGHT)
	# floor grime in the corners and along the walls
	for p in [Vector3(4.45, 0.0, 21.4), Vector3(5.6, 0.0, 8.9), Vector3(6.6, 0.0, 7.6), Vector3(18.5, 0.0, 6.4), Vector3(22.2, 0.0, 3.3), Vector3(33.0, 0.0, 11.4), Vector3(4.4, 0.0, 15.2)]:
		_decal(D, "decal_grime", Vector2(1.4, 1.4), p, Vector3.UP, p.x * 37.0)
	# something dragged itself from the vent towards the comms door
	_decal(D, "decal_smear", Vector2(3.4, 0.85), Vector3(13.2, 0.0, 7.05), Vector3.UP, 0.0, true)
	_decal(D, "decal_smear", Vector2(1.6, 0.4), Vector3(11.0, 2.0, 6.0), Vector3.BACK, -70.0, true)

func _probes_and_lightmap():
	for p in [[Vector3(5, 1.6, 15), Vector3(1.05, 1.65, 7.6)], [Vector3(12, 1.6, 7), Vector3(8.2, 1.65, 1.05)], [Vector3(27, 1.5, 7), Vector3(7.05, 1.55, 5.05)]]:
		var rp = ReflectionProbe.new(); rp.translation = p[0]; rp.extents = p[1]
		rp.box_projection = true; rp.interior_enable = true; rp.update_mode = ReflectionProbe.UPDATE_ONCE
		rp.intensity = 0.9; rp.max_distance = 30.0
		rp.interior_ambient_color = Color(0, 0, 0); rp.interior_ambient_energy = 0.0
		art.add_child(rp)
	var bl = BakedLightmap.new(); bl.name = "Lightmap"
	bl.translation = Vector3(19, 1.6, 12); bl.extents = Vector3(17.5, 2.6, 11.5)
	bl.quality = BakedLightmap.BAKE_QUALITY_MEDIUM; bl.bounces = 3; bl.use_denoiser = true; bl.use_hdr = true; bl.use_color = true
	bl.default_texels_per_unit = 16.0; bl.atlas_generate = true; bl.atlas_max_size = 4096
	bl.capture_enabled = true; bl.capture_cell_size = 0.5
	bl.environment_mode = BakedLightmap.ENVIRONMENT_MODE_DISABLED
	art.add_child(bl)

func _environment():
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color(0, 0, 0)
	env.ambient_light_color = Color(0.03, 0.035, 0.04); env.ambient_light_energy = 0.15
	env.tonemap_mode = Environment.TONE_MAPPER_ACES_FITTED; env.tonemap_exposure = 1.25; env.tonemap_white = 6.0
	env.fog_enabled = true; env.fog_color = Color(0.035, 0.04, 0.045); env.fog_depth_enabled = true
	env.fog_depth_begin = 3.0; env.fog_depth_end = 34.0; env.fog_depth_curve = 1.6
	env.glow_enabled = true; env.glow_intensity = 0.55; env.glow_strength = 1.0; env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.0; env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.set("glow_levels/1", true); env.set("glow_levels/2", true); env.set("glow_levels/3", true); env.set("glow_levels/5", false)
	env.ssao_enabled = true; env.ssao_radius = 0.6; env.ssao_intensity = 1.6; env.ssao_radius2 = 2.0; env.ssao_intensity2 = 0.6
	env.ss_reflections_enabled = true; env.ss_reflections_max_steps = 48; env.ss_reflections_depth_tolerance = 0.25
	env.adjustment_enabled = true; env.adjustment_contrast = 1.06; env.adjustment_saturation = 0.88
	var we = WorldEnvironment.new(); we.name = "Env"; we.environment = env; art.add_child(we)

func _cameras():
	var C = Spatial.new(); C.name = "Cams"; art.add_child(C)
	for c in [["Cam_start", Vector3(5.0, 1.62, 21.0), Vector3(-3, 0, 0)], ["Cam_mid", Vector3(5.35, 1.62, 16.2), Vector3(-2, 6, 0)],
			["Cam_corner", Vector3(4.7, 1.62, 10.6), Vector3(-3, -28, 0)], ["Cam_ew", Vector3(6.4, 1.62, 7.15), Vector3(-2, -90, 0)],
			["Cam_vent", Vector3(9.6, 1.55, 7.35), Vector3(28, -75, 0)], ["Cam_door", Vector3(17.2, 1.62, 7.1), Vector3(-3, -90, 0)],
			["Cam_room", Vector3(21.2, 1.62, 7.2), Vector3(-5, -95, 0)], ["Cam_room2", Vector3(33.0, 1.7, 11.3), Vector3(-7, 52, 0)],
			["Cam_console", Vector3(25.95, 1.5, 8.1), Vector3(-22, -62, 0)], ["Cam_crt", Vector3(32.3, 1.45, 8.0), Vector3(-12, -60, 0)], ["Cam_racks", Vector3(25.0, 1.6, 6.8), Vector3(-4, 22, 0)]]:
		var cam = Camera.new(); cam.name = c[0]; cam.translation = c[1]; cam.rotation_degrees = c[2]; cam.fov = 68; cam.far = 80
		C.add_child(cam)
