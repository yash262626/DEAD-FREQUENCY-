extends SceneTree
# DEAD FREQUENCY — Godot 4 visual benchmark. Builds the vertical slice from the SAME assets as the Godot 3.5 game
# (Blender glTF exports, CC0 Poly Haven models and surfaces, the Listener v2) and renders it with Godot 4's
# Forward+ features: SDFGI real-time global illumination, shadowed volumetric fog, projected decals, AgX tone
# mapping, TAA, skin subsurface scattering and a torch with a light projector. Writes PNGs to DF_OUT.
#   godot4 --path benchmark_godot4 --resolution 1920x1080 -s res://bench.gd       (DF_SHOTS=a,b to pick shots)
var art: Node3D
var mats := {}
var uid := 0
var cam: Camera3D
var lamp: SpotLight3D
var listener: Node3D
var anim: AnimationPlayer
var fp: Node3D

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

func _props():
	var P = Node3D.new(); P.name = "Props"; art.add_child(P)
	var lamp_glass = _emissive(Color(1.0, 0.85, 0.62), 2.2)
	# --- corridor: bulkhead lamps on pilasters (lights added in _lights)
	_place("industrial_wall_lamp", "", Vector3(5.86, 2.2, 10.0), -90, "wall", {"override": {"industrial_wall_lamp_glass": lamp_glass}})
	_place("industrial_wall_lamp", "", Vector3(4.14, 2.2, 14.0), 90, "wall", {"override": {"industrial_wall_lamp_glass": lamp_glass}})
	_place("industrial_wall_lamp", "", Vector3(5.86, 2.2, 18.0), -90, "wall")          # dead lamp
	_place("industrial_wall_lamp", "", Vector3(4.0, 2.2, 19.8), 90, "wall", {"override": {"industrial_wall_lamp_glass": lamp_glass}})
	var red_glass = _emissive(Color(1.0, 0.1, 0.05), 3.0)
	var dead_tube = StandardMaterial3D.new(); dead_tube.albedo_color = Color(0.55, 0.56, 0.55); dead_tube.roughness = 0.3
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


func _lights():
	var L = Node3D.new(); L.name = "Lights"; art.add_child(L)
	var warm = Color(1.0, 0.82, 0.6); var cool = Color(0.82, 0.92, 1.0)
	_light("omni", Vector3(5.55, 2.15, 10.0), warm, 1.5, 6.5)
	_light("omni", Vector3(4.45, 2.15, 14.0), warm, 1.5, 6.5)
	var red = Color(1.0, 0.13, 0.07)
	_light("omni", Vector3(9.4, 2.2, 6.42), red, 1.9, 7.5)
	_light("omni", Vector3(13.4, 2.2, 7.58), red, 1.9, 7.5)
	_light("omni", Vector3(17.1, 2.2, 6.42), red, 1.6, 6.5)
	_light("omni", Vector3(17.3, 2.42, 7.25), Color(1.0, 0.78, 0.5), 1.0, 5.0, false, {"name": "HangLamp"})
	var bc = _light("spot", Vector3(20.2, 2.62, 7.0), Color(1.0, 0.08, 0.04), 3.0, 11.0, false, {"name": "Beacon", "angle": 32.0, "rot": Vector3(-12, 0, 0)})
	bc.visible = false
	_light("omni", Vector3(19.4, 2.55, 7.0), Color(1.0, 0.12, 0.08), 0.35, 3.0, true, {"name": "DoorRed"})
	_light("omni", Vector3(4.32, 2.15, 19.8), warm, 1.3, 6.0)
	# room: troffers that work, CRT glow, desk lamp, receiver dial
	for p in [Vector3(23, 2.95, 5), Vector3(31, 2.95, 9)]:
		_light("spot", p, Color(0.88, 0.94, 1.0), 2.2, 7.5, true, {"rot": Vector3(-90, 0, 0), "angle": 80.0, "att": 0.6})
	_light("spot", Vector3(27, 2.95, 9), Color(0.88, 0.94, 1.0), 1.8, 7.5, false, {"rot": Vector3(-90, 0, 0), "angle": 80.0, "att": 0.6, "name": "TrofferFlicker"})
	_light("spot", Vector3(28.15, 1.32, 11.5), Color(1.0, 0.78, 0.52), 3.0, 3.0, true, {"rot": Vector3(-70, 180, 0), "angle": 40.0})
	for z in [4.6, 6.9, 9.2]:
		_light("omni", Vector3(33.05, 0.98, z), Color(0.4, 1.0, 0.6), 0.4, 2.6)
	_light("omni", Vector3(26.85, 1.15, 7.0), Color(1.0, 0.62, 0.25), 0.7, 1.7)   # shorter than in 3.5: Godot 4 falloff reaches the ceiling



func _initialize():
	art = Node3D.new(); art.name = "Slice"; get_root().add_child(art)
	var vp = get_root()
	vp.positional_shadow_atlas_size = 4096
	vp.use_taa = true
	vp.msaa_3d = Viewport.MSAA_2X
	_env(); _shell(); _props(); _lights(); _decals(); _creature(); _first_person()
	call_deferred("_run")

# ------------------------------------------------------------------ materials (same textures and tints as the 3.5 build)
func _tex(path: String) -> Array:
	if path.begins_with("assets/"):
		return [load("res://%s/diff.jpg" % path), load("res://%s/nor_gl.jpg" % path), load("res://%s/arm.jpg" % path)]
	return [load("res://%s/albedo.jpg" % path), load("res://%s/normal.jpg" % path), load("res://%s/orm.jpg" % path)]

func _emissive(col: Color, e: float) -> StandardMaterial3D:
	var m = StandardMaterial3D.new(); m.albedo_color = col; m.emission_enabled = true; m.emission = col; m.emission_energy_multiplier = e * 1.5
	m.roughness = 0.2
	return m

func _tex_mat(tex: String, rough := 0.7, emissive := 0.0, alpha := false) -> StandardMaterial3D:
	var m = StandardMaterial3D.new(); m.albedo_texture = load("res://slice/tex/%s.png" % tex); m.roughness = rough
	if emissive > 0.0:
		m.emission_enabled = true; m.emission_texture = m.albedo_texture; m.emission_energy_multiplier = emissive * 1.5
	if alpha: m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	return m

func _mat(name: String) -> Material:
	if mats.has(name): return mats[name]
	var m: Material
	match name:
		"M_CorrFloor":
			var t = _tex("assets/surfaces/concrete_floor_worn_001")
			var sm = ShaderMaterial.new(); sm.shader = load("res://wet_surface4.gdshader")
			sm.set_shader_parameter("albedo_tex", t[0]); sm.set_shader_parameter("normal_tex", t[1]); sm.set_shader_parameter("arm_tex", t[2])
			sm.set_shader_parameter("wet_mask", load("res://slice/tex/wet_mask.png")); sm.set_shader_parameter("uv_scale", 0.38)
			m = sm
		"M_TrofferOn": m = _emissive(Color(0.9, 0.95, 1.0), 2.6)
		"M_TrofferOff":
			m = StandardMaterial3D.new(); m.albedo_color = Color(0.55, 0.57, 0.56); m.roughness = 0.25
		"M_WiredGlass":
			m = _tex_mat("wired_glass", 0.12); m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		"M_Hazard", "M_HazardFrame":
			m = _tex_mat("hazard", 0.65); m.uv1_scale = Vector3(1.5, 1.5, 1.5) if name == "M_Hazard" else Vector3(1.2, 1.2, 1.2)
		"M_LED_Green", "M_LED_Red", "M_LED_Amber", "M_BeaconRed":
			m = _emissive({"M_LED_Green": Color(0.3, 1.0, 0.4), "M_LED_Red": Color(1.0, 0.12, 0.08), "M_LED_Amber": Color(1.0, 0.6, 0.12), "M_BeaconRed": Color(1.0, 0.1, 0.06)}[name], 2.5)
		"M_LED_Off":
			m = StandardMaterial3D.new(); m.albedo_color = Color(0.08, 0.06, 0.05); m.roughness = 0.2
		"M_CRT_Log": m = _tex_mat("crt_log", 0.35, 1.6)
		"M_CRT_Wave": m = _tex_mat("crt_wave", 0.35, 1.6)
		"M_DialGlass": m = _tex_mat("dial", 0.35, 1.4)
		"M_Meter": m = _tex_mat("meter", 0.4, 0.35)
		"M_CRTGlass":
			m = StandardMaterial3D.new(); m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; m.albedo_color = Color(0.02, 0.03, 0.03, 0.18); m.roughness = 0.05
		"M_Label": m = _tex_mat("label")
		"M_Keys": m = _tex_mat("keys")
		"M_Chart": m = _tex_mat("chart")
		"M_Clock": m = _tex_mat("clock", 0.6, 0.0, true)
		"M_Paper0", "M_Paper1", "M_Paper2":
			m = _tex_mat("paper" + name.right(1), 0.85); m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"M_SignComms": m = _tex_mat("sign_comms")
		"M_SignStorage": m = _tex_mat("sign_storage")
		"M_SignBattery": m = _tex_mat("sign_battery")
		"M_SignStair": m = _tex_mat("sign_stair")
		"M_SignCommsDoor": m = _tex_mat("sign_comms_door")
		"M_SignRF": m = _tex_mat("sign_rf")
		_:
			var s = SURF.get(name)
			if s == null:
				m = StandardMaterial3D.new(); m.albedo_color = Color(1, 0, 1)
			else:
				var t = _tex(s[0])
				var o = ORMMaterial3D.new()
				o.albedo_texture = t[0]; o.albedo_color = s[1]
				o.normal_enabled = true; o.normal_texture = t[1]; o.normal_scale = s[5]
				o.orm_texture = t[2]; o.roughness = s[3]; o.metallic = s[4]
				o.uv1_scale = Vector3(s[2], s[2], s[2])
				m = o
	mats[name] = m
	return m

# ------------------------------------------------------------------ geometry
func _xf_rel(node: Node, ancestor: Node) -> Transform3D:
	var t = Transform3D()
	var n = node
	while n != ancestor and n != null:
		if n is Node3D: t = n.transform * t
		n = n.get_parent()
	return t

func _meshes_under(n: Node, out: Array) -> Array:
	if n is MeshInstance3D and n.mesh: out.append(n)
	for c in n.get_children(): _meshes_under(c, out)
	return out

func _add_scene(path: String, remap: bool):
	var s = load(path).instantiate()
	for mi in _meshes_under(s, []):
		var n = MeshInstance3D.new(); n.mesh = mi.mesh; n.transform = _xf_rel(mi, s)
		art.add_child(n)
		if remap:
			for i in mi.mesh.get_surface_count():
				var sm = mi.mesh.surface_get_material(i)
				if sm: n.set_surface_override_material(i, _mat(sm.resource_name))
	s.free()

func _shell():
	_add_scene("res://slice/art/slice_shell.gltf", true)
	_add_scene("res://slice/art/slice_dress.gltf", true)

func _place(id: String, sub, pos: Vector3, rot_y: float, snap := "", opts := {}) -> Node3D:
	var scene = load("res://assets/models/%s/%s.gltf" % [id, id]).instantiate()
	var subs = []
	if typeof(sub) == TYPE_ARRAY: subs = sub
	elif sub != "": subs = [sub]
	var srcs = []
	if subs.is_empty(): srcs = [scene]
	else:
		for nm in subs:
			var f = scene.find_child(nm, true, false)
			if f: srcs.append(f)
	uid += 1
	var g = Node3D.new(); g.name = "%s_%d" % [id, uid]; art.get_node("Props").add_child(g)
	var base_inv = Transform3D() if subs.is_empty() else srcs[0].transform.affine_inverse()
	var place = Transform3D(Basis(Vector3.UP, deg_to_rad(rot_y)), Vector3())
	var aabb = null
	for src in srcs:
		for mi in _meshes_under(src, []):
			var xf = place * base_inv * _xf_rel(mi, scene)
			var n = MeshInstance3D.new(); n.mesh = mi.mesh; n.transform = xf; g.add_child(n)
			for si in opts.get("override", {}):
				for i in mi.mesh.get_surface_count():
					var sm = mi.mesh.surface_get_material(i)
					if sm and sm.resource_name == si: n.set_surface_override_material(i, opts.override[si])
			var a = xf * mi.mesh.get_aabb()
			aabb = a if aabb == null else aabb.merge(a)
	scene.free()
	var off = pos
	if aabb != null:
		var c = aabb.position + aabb.size * 0.5
		match snap:
			"floor": off = pos - Vector3(c.x, aabb.position.y, c.z)
			"ceil": off = pos - Vector3(c.x, aabb.end.y, c.z)
			"wall":
				var f = Basis(Vector3.UP, deg_to_rad(rot_y)).z
				var back = c - Vector3(f.x * aabb.size.x, 0, f.z * aabb.size.z) * 0.5
				off = pos - Vector3(back.x, c.y, back.z)
	g.position = off
	return g

# ------------------------------------------------------------------ lights: all dynamic, all casting shadows, all in the fog
func _light(kind: String, pos: Vector3, col: Color, energy: float, rng: float, _baked := true, extra := {}) -> Light3D:
	var l
	if kind == "spot":
		l = SpotLight3D.new(); l.spot_range = rng; l.spot_angle = extra.get("angle", 60.0); l.spot_angle_attenuation = extra.get("att", 1.0)
	else:
		l = OmniLight3D.new(); l.omni_range = rng
	l.position = pos; l.light_color = col; l.light_energy = energy * 1.3
	l.shadow_enabled = true; l.light_volumetric_fog_energy = 1.2
	if extra.has("rot"): l.rotation_degrees = extra.rot
	if extra.has("name"): l.name = extra.name
	art.get_node("Lights").add_child(l)
	return l

func _env():
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color(0, 0, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.03, 0.035, 0.04); env.ambient_light_energy = 0.2
	env.tonemap_mode = Environment.TONE_MAPPER_AGX; env.tonemap_exposure = 1.1
	env.sdfgi_enabled = true; env.sdfgi_use_occlusion = true; env.sdfgi_cascades = 4; env.sdfgi_min_cell_size = 0.08; env.sdfgi_energy = 1.5; env.sdfgi_bounce_feedback = 0.9
	env.ssil_enabled = true; env.ssao_enabled = true; env.ssao_radius = 0.8; env.ssao_intensity = 1.6
	env.ssr_enabled = true; env.ssr_max_steps = 96
	env.glow_enabled = true; env.glow_intensity = 0.5; env.glow_bloom = 0.04; env.glow_hdr_threshold = 1.0
	env.volumetric_fog_enabled = true; env.volumetric_fog_density = 0.032; env.volumetric_fog_albedo = Color(0.7, 0.72, 0.75)
	env.volumetric_fog_anisotropy = 0.45; env.volumetric_fog_length = 40.0; env.volumetric_fog_gi_inject = 0.6
	env.adjustment_enabled = true; env.adjustment_contrast = 1.06; env.adjustment_saturation = 0.9
	var we = WorldEnvironment.new(); we.environment = env; art.add_child(we)
	# stills: let SDFGI converge in 5 frames with the densest probe rays (a game would keep the defaults)
	RenderingServer.environment_set_sdfgi_frames_to_converge(RenderingServer.ENV_SDFGI_CONVERGE_IN_5_FRAMES)
	RenderingServer.environment_set_sdfgi_ray_count(RenderingServer.ENV_SDFGI_RAY_COUNT_128)
	RenderingServer.environment_set_sdfgi_frames_to_update_light(RenderingServer.ENV_SDFGI_UPDATE_LIGHT_IN_1_FRAME)
	var ca = CameraAttributesPractical.new(); ca.dof_blur_far_enabled = false; we.camera_attributes = ca

# ------------------------------------------------------------------ projected decals (Godot 4 has real decals)
func _decal(tex: String, size: Vector2, pos: Vector3, normal: Vector3, spin := 0.0, wet := false):
	var d = Decal.new(); d.texture_albedo = load("res://slice/tex/%s.png" % tex)
	d.size = Vector3(size.x, 0.12, size.y)
	art.add_child(d)
	var up = Vector3.UP if abs(normal.y) < 0.9 else Vector3.FORWARD
	# a Decal projects along its local -Y: aim -Y into the surface
	var y = normal.normalized(); var x = up.cross(y).normalized()
	if x.length() < 0.5: x = Vector3.RIGHT
	var z = x.cross(y).normalized()
	d.global_transform = Transform3D(Basis(x, y, z), pos + normal * 0.03)
	d.rotate_object_local(Vector3.UP, deg_to_rad(spin))
	if wet: d.modulate = Color(1, 1, 1, 1)

func _decals():
	for dd in [[Vector3(4.0, 2.35, 12.6), Vector3.RIGHT], [Vector3(6.0, 2.2, 16.9), Vector3.LEFT], [Vector3(11.6, 2.25, 6.0), Vector3.BACK], [Vector3(32.2, 1.9, 2.0), Vector3.BACK]]:
		_decal("decal_leak", Vector2(0.7, 2.1), dd[0], dd[1], 0.0, true)
	for z in [16.0, 13.0, 10.0, 19.0]:
		_decal("decal_rust", Vector2(0.35, 1.0), Vector3(4.0, 2.25, z), Vector3.RIGHT)
	for p in [Vector3(4.45, 0.0, 21.4), Vector3(5.6, 0.0, 8.9), Vector3(6.6, 0.0, 7.6), Vector3(18.5, 0.0, 6.4), Vector3(22.2, 0.0, 3.3), Vector3(33.0, 0.0, 11.4), Vector3(4.4, 0.0, 15.2)]:
		_decal("decal_grime", Vector2(1.4, 1.4), p, Vector3.UP, p.x * 37.0)
	_decal("decal_smear", Vector2(3.4, 0.85), Vector3(13.2, 0.0, 7.05), Vector3.UP, 0.0, true)
	_decal("decal_smear", Vector2(1.6, 0.4), Vector3(11.0, 2.0, 6.0), Vector3.BACK, -70.0, true)
	for p in [[Vector3(5.25, 0.0, 17.0), 1.4, 0], [Vector3(4.75, 0.0, 13.4), 0.9, 1], [Vector3(12.7, 0.0, 7.35), 1.1, 0], [Vector3(31.2, 0.0, 4.0), 1.2, 1]]:
		_decal("puddle%d" % p[2], Vector2(p[1], p[1] * 0.8), p[0], Vector3.UP, p[1] * 40.0, true)

# ------------------------------------------------------------------ the Listener v2 and the first-person rig
func _creature():
	listener = Node3D.new(); art.add_child(listener)
	var s = load("res://assets/creature2/listener2.gltf").instantiate(); s.scale = Vector3(1.1, 1.1, 1.1); listener.add_child(s)
	anim = s.find_child("AnimationPlayer", true, false)
	var skin = ORMMaterial3D.new()
	skin.albedo_texture = load("res://assets/creature2/skin_albedo.jpg"); skin.albedo_color = Color(0.5, 0.36, 0.33)
	skin.normal_enabled = true; skin.normal_texture = load("res://assets/creature2/skin_nor.png"); skin.normal_scale = 1.5
	skin.orm_texture = load("res://assets/creature2/skin_orm.jpg")
	skin.clearcoat_enabled = true; skin.clearcoat = 0.5; skin.clearcoat_roughness = 0.15
	skin.subsurf_scatter_enabled = true; skin.subsurf_scatter_strength = 0.35; skin.subsurf_scatter_skin_mode = true
	skin.subsurf_scatter_transmittance_enabled = true; skin.subsurf_scatter_transmittance_color = Color(0.5, 0.08, 0.05); skin.subsurf_scatter_transmittance_depth = 0.08
	var claw = ORMMaterial3D.new(); claw.albedo_texture = load("res://assets/creature2/claws_albedo.jpg"); claw.orm_texture = load("res://assets/creature2/claws_orm.jpg")
	claw.clearcoat_enabled = true; claw.clearcoat = 0.4
	var mem = ORMMaterial3D.new(); mem.albedo_texture = load("res://assets/creature2/membrane_albedo.jpg"); mem.albedo_color = Color(0.56, 0.34, 0.32)
	mem.orm_texture = load("res://assets/creature2/membrane_orm.jpg"); mem.cull_mode = BaseMaterial3D.CULL_DISABLED
	mem.subsurf_scatter_enabled = true; mem.subsurf_scatter_strength = 0.6; mem.subsurf_scatter_skin_mode = true
	mem.subsurf_scatter_transmittance_enabled = true; mem.subsurf_scatter_transmittance_color = Color(0.7, 0.12, 0.08); mem.subsurf_scatter_transmittance_depth = 0.25
	mem.clearcoat_enabled = true; mem.clearcoat = 0.6
	for mi in _meshes_under(s, []):
		mi.visible = not ("LOD1" in mi.name or "LOD2" in mi.name)     # Godot 4 also auto-generates LODs at import
		for i in mi.mesh.get_surface_count():
			var nm = mi.mesh.surface_get_material(i).resource_name if mi.mesh.surface_get_material(i) else ""
			mi.set_surface_override_material(i, claw if "Claw" in nm else (mem if ("Membrane" in nm or "Cartilage" in nm) else skin))
	listener.visible = false

func _first_person():
	cam = Camera3D.new(); cam.fov = 75; cam.near = 0.02; cam.far = 200; art.add_child(cam); cam.current = true
	lamp = SpotLight3D.new(); lamp.position = Vector3(0.125, -0.108, -0.33); lamp.spot_range = 20; lamp.spot_angle = 28
	lamp.spot_angle_attenuation = 0.75; lamp.light_energy = 2.8; lamp.light_color = Color(1.0, 0.95, 0.85)
	lamp.shadow_enabled = true; lamp.light_volumetric_fog_energy = 2.0; lamp.light_projector = _projector()
	cam.add_child(lamp)
	fp = Node3D.new(); cam.add_child(fp)
	var torch = load("res://assets/fp/fp_torch.gltf").instantiate(); var radio = load("res://assets/fp/fp_radio.gltf").instantiate()
	var tn = Node3D.new(); tn.position = Vector3(0.125, -0.125, -0.25); tn.rotation_degrees = Vector3(5, 4, 0); fp.add_child(tn); tn.add_child(torch)
	var rn = Node3D.new(); rn.name = "Radio"; rn.position = Vector3(-0.125, -0.13, -0.25); rn.rotation_degrees = Vector3(8, 18, 4); fp.add_child(rn); rn.add_child(radio)
	var M = _fp_materials()
	for root in [torch, radio]:
		for mi in _meshes_under(root, []):
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			for i in mi.mesh.get_surface_count():
				var sm = mi.mesh.surface_get_material(i)
				if sm and M.has(sm.resource_name): mi.set_surface_override_material(i, M[sm.resource_name])

func _m(albedo: Color, rough: float, metal := 0.0) -> StandardMaterial3D:
	var m = StandardMaterial3D.new(); m.albedo_color = albedo; m.roughness = rough; m.metallic = metal
	return m

func _mt(m: StandardMaterial3D, path: String, normal_path := "", sc := 1.0, nscale := 1.0) -> StandardMaterial3D:
	if path != "": m.albedo_texture = load(path)
	if normal_path != "":
		m.normal_enabled = true; m.normal_texture = load(normal_path); m.normal_scale = nscale
	m.uv1_scale = Vector3(sc, sc, sc)
	return m

func _fp_materials() -> Dictionary:
	# the same values as game/scripts/fp_models.gd
	var lens = _m(Color(0.75, 0.82, 0.9, 0.35), 0.05); lens.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lens.emission_enabled = true; lens.emission = Color(1.0, 0.96, 0.85); lens.emission_energy_multiplier = 1.5
	var lcd = _mt(_m(Color(1, 1, 1), 0.3), "res://assets/fp/lcd.png")
	lcd.emission_enabled = true; lcd.emission_texture = lcd.albedo_texture; lcd.emission_energy_multiplier = 1.0
	var meter = _mt(_m(Color(1, 1, 1), 0.4), "res://slice/tex/meter.png"); meter.emission_enabled = true; meter.emission_texture = meter.albedo_texture; meter.emission_energy_multiplier = 0.4
	var glove = _mt(_m(Color(1, 1, 1), 0.55), "res://slice/tex/glove_albedo.png", "res://assets/fp/leather_nor.png", 40.0, 0.8)
	glove.clearcoat_enabled = true; glove.clearcoat = 0.25; glove.clearcoat_roughness = 0.5
	return {
		"M_TorchAlu": _m(Color(0.06, 0.062, 0.068), 0.36, 0.85),
		"M_TorchKnurl": _mt(_m(Color(0.06, 0.062, 0.068), 0.42, 0.85), "", "res://assets/fp/knurl_nor.png", 42.0, 1.4),
		"M_KnobKnurl": _mt(_m(Color(0.03, 0.03, 0.03), 0.55), "", "res://assets/fp/knurl_nor.png", 42.0, 1.2),
		"M_RubberDark": _mt(_m(Color(0.04, 0.04, 0.042), 0.7), "", "res://textures/Rubber004/normal.jpg", 30.0, 0.6),
		"M_Chrome": _m(Color(0.85, 0.86, 0.88), 0.07, 1.0),
		"M_LEDEmit": lens, "M_Lens": lens,
		"M_Steel": _m(Color(0.6, 0.6, 0.62), 0.3, 1.0),
		"M_Glove": glove,
		"M_Cuff": _mt(_m(Color(0.07, 0.07, 0.08), 0.95), "", "res://textures/Fabric086/normal.jpg", 30.0, 1.0),
		"M_Sleeve": _mt(_m(Color(0.86, 0.34, 0.08), 0.9), "res://textures/Fabric086/albedo.jpg", "res://textures/Fabric086/normal.jpg", 9.0, 1.0),
		"M_Reflective": _m(Color(0.62, 0.64, 0.64), 0.25, 0.6),
		"M_RxRubber": _mt(_m(Color(0.11, 0.125, 0.1), 0.62), "", "res://textures/Rubber004/normal.jpg", 25.0, 0.7),
		"M_RxPlate": _mt(_m(Color(0.7, 0.71, 0.72), 0.38, 1.0), "res://textures/Metal063/albedo.jpg", "", 10.0),
		"M_RxLCD": lcd,
		"M_RxLabel": _mt(_m(Color(1, 1, 1), 0.6), "res://assets/fp/label_hx7.png"),
		"M_RxGrille": _mt(_m(Color(1, 1, 1), 0.7), "res://assets/fp/grille.png", "", 1.0),
		"M_RxMeter": meter,
	}

func _projector() -> Texture2D:
	# a torch's beam is not a clean disc: a hot core, a soft ring, faint spill
	var n = 256; var img = Image.create(n, n, false, Image.FORMAT_RGB8)
	for y in n:
		for x in n:
			var r = Vector2(x - n * 0.5, y - n * 0.5).length() / (n * 0.5)
			var v = clamp(1.0 - r, 0.0, 1.0)
			var core = exp(-pow(r / 0.28, 2.0)); var ring = 0.35 * exp(-pow((r - 0.62) / 0.08, 2.0))
			var c = clamp(0.25 * v + core + ring, 0.0, 1.0)
			img.set_pixel(x, y, Color(c, c * 0.97, c * 0.9))
	return ImageTexture.create_from_image(img)

# ------------------------------------------------------------------ shots (same viewpoints as the Godot 3.5 captures)
const SHOTS = [
	# name, eye position, yaw, pitch, listener [x, z, yaw, anim] or null, torch on, radio up
	["g4_s01_corridor", Vector3(5.0, 1.67, 20.6), 0.0, -2.0, null, true, false],
	["g4_s04_listener_corridor", Vector3(6.6, 1.67, 7.05), -90.0, 6.0, [10.6, 7.0, 90.0, "listen"], true, false],
	["g4_s06_room", Vector3(20.9, 1.67, 7.2), -96.0, -6.0, null, false, false],
	["g4_s07_console", Vector3(25.85, 1.67, 7.05), -90.0, -24.0, null, true, true],
	["g4_s10_creature_close", Vector3(5.05, 1.67, 11.7), 0.0, 16.0, [5.0, 9.9, 180.0, "listen"], true, false],
	["g4_s11_creature_room", Vector3(24.4, 1.67, 8.3), -55.0, 8.0, [26.0, 6.4, 120.0, "search"], true, false],
]

func _run():
	var out = OS.get_environment("DF_OUT"); var only = OS.get_environment("DF_SHOTS").split(",") if OS.has_environment("DF_SHOTS") else []
	var frames = int(OS.get_environment("DF_FRAMES")) if OS.has_environment("DF_FRAMES") else 48
	for s in SHOTS:
		if only.size() and not s[0] in only: continue
		cam.global_position = s[1]; cam.rotation_degrees = Vector3(s[3], s[2], 0)
		listener.visible = s[4] != null
		lamp.visible = s[5]; fp.get_node("Radio").visible = s[6]
		if s[4] != null:
			listener.global_position = Vector3(s[4][0], 0, s[4][1]); listener.rotation_degrees = Vector3(0, s[4][2], 0)
			if anim: anim.play(s[4][3]); anim.seek(0.35, true); anim.speed_scale = 0.0
		var t0 = Time.get_ticks_msec()
		for i in frames: await process_frame
		var img = get_root().get_texture().get_image(); img.save_png(out + "/" + s[0] + ".png")
		print("%s: %d frames in %.1f s  (%s, %s)" % [s[0], frames, (Time.get_ticks_msec() - t0) / 1000.0, RenderingServer.get_video_adapter_name(), str(get_root().size)])
	quit()
