extends Spatial
# Mountain exterior of HELIX-9: opening cinematic, Daniel's arrival, main menu, endings.
# Everything here renders on visual layer 2 and its lights only touch layer 2,
# so the moonlight never leaks into the interior levels that share the scene.
const Props = preload("res://scripts/props.gd")
const LAYER := 2
var points := {}
var sun: DirectionalLight
var rain: CPUParticles
var beacon: OmniLight
var gate_light: OmniLight
var mode := "storm"
var _t := 0.0
var _flash := 0.0

func build(m: String):
	var rng = RandomNumberGenerator.new(); rng.seed = 1998
	var rock = Props.mat(Color(0.09, 0.1, 0.11), 0, 0.95)
	var snow = Props.mat(Color(0.55, 0.57, 0.6), 0, 0.9)
	var ground = MeshInstance.new(); var pm = PlaneMesh.new(); pm.size = Vector2(600, 600)
	ground.mesh = pm; ground.material_override = Props.mat(Color(0.07, 0.08, 0.08), 0, 1.0); add_child(ground)
	for i in 26:
		var mi = MeshInstance.new(); var cm = CylinderMesh.new()
		var r = rng.randf_range(30, 80); var h = rng.randf_range(50, 150)
		cm.top_radius = rng.randf_range(0, 4); cm.bottom_radius = r; cm.height = h; cm.radial_segments = 7; cm.rings = 2
		mi.mesh = cm; mi.material_override = rock
		var a = rng.randf_range(0, TAU); var d = rng.randf_range(90, 240)
		if abs(wrapf(a - PI / 2, -PI, PI)) < 0.45: d += 120      # keep the approach valley open
		mi.translation = Vector3(cos(a) * d, h / 2 - 2, sin(a) * d - 60); mi.rotation.y = rng.randf() * TAU
		add_child(mi)
		var cap = MeshInstance.new(); var cc = CylinderMesh.new()
		cc.top_radius = cm.top_radius; cc.bottom_radius = r * 0.28; cc.height = h * 0.28; cc.radial_segments = 7
		cap.mesh = cc; cap.material_override = snow; cap.translation = mi.translation + Vector3(0, h * 0.36 + 0.5, 0); cap.rotation.y = mi.rotation.y
		add_child(cap)
	var big = MeshInstance.new(); var bm = CylinderMesh.new(); bm.top_radius = 6; bm.bottom_radius = 110; bm.height = 190; bm.radial_segments = 9
	big.mesh = bm; big.material_override = rock; big.translation = Vector3(0, 93, -118); add_child(big)
	var conc = Color(0.3, 0.31, 0.3)
	Props.box(self, Vector3(22, 9, 6), Vector3(0, 4.5, -10), conc)
	Props.box(self, Vector3(26, 1.2, 8), Vector3(0, 9.4, -10), conc * 0.8)
	Props.box(self, Vector3(6, 5, 0.4), Vector3(0, 2.5, -6.9), Color(0.16, 0.17, 0.18), 0, false, 0.6)
	Props.box(self, Vector3(6.4, 0.5, 0.5), Vector3(0, 5.3, -6.9), Color(0.6, 0.5, 0.1))
	for sx in [-8, 8]: Props.box(self, Vector3(1.2, 9, 1.2), Vector3(sx, 4.5, -6.6), conc * 0.7)
	var sign_ = Label3D.new(); sign_.text = "HELIX-9"; sign_.pixel_size = 0.03; sign_.modulate = Color(0.75, 0.75, 0.7)
	sign_.translation = Vector3(0, 7.2, -6.9); add_child(sign_)
	Props.box(self, Vector3(8, 0.1, 70), Vector3(0, 0.05, 28), Color(0.12, 0.12, 0.12))
	for i in 9: Props.box(self, Vector3(0.15, 2.2, 0.15), Vector3(-5 + (i % 2) * 10, 1.1, 2 + i * 7), Color(0.2, 0.2, 0.2))
	# Daniel's truck
	var truck = Spatial.new(); truck.translation = Vector3(2.5, 0, 16); add_child(truck)
	Props.box(truck, Vector3(2.0, 1.1, 4.6), Vector3(0, 0.95, 0), Color(0.55, 0.12, 0.08), 0, false, 0.4)
	Props.box(truck, Vector3(1.9, 0.8, 2.0), Vector3(0, 1.9, 0.3), Color(0.5, 0.11, 0.07), 0, false, 0.4)
	Props.box(truck, Vector3(1.8, 0.5, 0.05), Vector3(0, 1.95, -0.71), Color(0.2, 0.25, 0.3, 0.7))
	for sx in [-0.7, 0.7]:
		Props.box(truck, Vector3(0.3, 0.2, 0.05), Vector3(sx, 1.0, -2.31), Color(1, 0.95, 0.8), 3.0)
		Props.box(truck, Vector3(0.3, 0.15, 0.05), Vector3(sx, 1.0, 2.31), Color(1, 0.1, 0.05), 1.5)
	var hl = SpotLight.new(); hl.spot_range = 40; hl.spot_angle = 30; hl.light_energy = 3.0; hl.light_color = Color(1, 0.95, 0.85)
	hl.translation = Vector3(0, 1.0, -2.4); truck.add_child(hl); hl.light_cull_mask = 1 << (LAYER - 1)
	Props.cyl(self, 0.35, 46, Vector3(16, 32, -12), Color(0.25, 0.26, 0.27))
	for i in 4: Props.box(self, Vector3(5 - i, 0.15, 0.15), Vector3(16, 30 + i * 6, -12), Color(0.25, 0.26, 0.27))
	var dish = Props.make("dish"); dish.scale = Vector3(3, 3, 3); dish.translation = Vector3(-14, 9.9, -10); add_child(dish)
	beacon = OmniLight.new(); beacon.light_color = Color(1, 0.1, 0.05); beacon.omni_range = 40; beacon.translation = Vector3(16, 55.5, -12); add_child(beacon)
	Props.box(self, Vector3(0.6, 0.6, 0.6), Vector3(16, 55.2, -12), Color(1, 0.1, 0.05), 3.0).name = "bulb"
	gate_light = OmniLight.new(); gate_light.light_color = Color(1.0, 0.85, 0.6); gate_light.omni_range = 18; gate_light.light_energy = 1.6
	gate_light.translation = Vector3(0, 6.2, -4.5); add_child(gate_light)
	sun = DirectionalLight.new(); sun.rotation_degrees = Vector3(-35, 40, 0); add_child(sun)
	rain = CPUParticles.new(); rain.amount = 900; rain.lifetime = 1.2; rain.emission_shape = CPUParticles.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(40, 1, 40); rain.direction = Vector3(0.15, -1, 0); rain.spread = 2
	rain.initial_velocity = 38; rain.gravity = Vector3(0, -20, 0)
	var q = QuadMesh.new(); q.size = Vector2(0.03, 0.9)
	var rm = SpatialMaterial.new(); rm.flags_unshaded = true; rm.albedo_color = Color(0.6, 0.65, 0.7, 0.3); rm.flags_transparent = true
	rm.params_billboard_mode = SpatialMaterial.BILLBOARD_FIXED_Y; q.material = rm
	rain.mesh = q; rain.translation = Vector3(0, 30, 20); add_child(rain)
	points = {"air1": Vector3(60, 70, 150), "air2": Vector3(20, 34, 70), "gate": Vector3(0, 5, -8), "mast": Vector3(16, 50, -12),
		"road1": Vector3(-3, 1.7, 46), "road2": Vector3(0, 1.7, 12), "low": Vector3(9, 1.2, 14), "door": Vector3(0, 2.4, -6.5),
		"menu": Vector3(-13, 3.2, 30), "menu2": Vector3(-9, 3.6, 26), "up": Vector3(0, 30, -30), "sky": Vector3(0, 80, -200),
		"truck": Vector3(2.5, 1.6, 16), "cab": Vector3(2.9, 2.05, 16.6), "behind": Vector3(4, 2.2, 26), "far": Vector3(0, 2, 120)}
	_layer(self)
	for l in [sun, beacon, gate_light]: l.light_cull_mask = 1 << (LAYER - 1)
	set_mode(m)

func _layer(n: Node):
	for c in n.get_children():
		if c is VisualInstance and not c is Light: c.layers = 1 << (LAYER - 1)
		_layer(c)

func set_mode(m: String):
	mode = m
	rain.emitting = m == "storm"
	match m:
		"storm":
			sun.light_color = Color(0.45, 0.55, 0.8); sun.light_energy = 0.22; sun.rotation_degrees = Vector3(-35, 40, 0)
		"night":
			sun.light_color = Color(0.4, 0.5, 0.75); sun.light_energy = 0.3; sun.rotation_degrees = Vector3(-35, 40, 0)
		"dawn":
			sun.light_color = Color(1.0, 0.72, 0.5); sun.light_energy = 1.1; sun.rotation_degrees = Vector3(-12, 150, 0)

func apply_env(env: Environment):
	var dawn = mode == "dawn"
	env.fog_depth_end = 260.0; env.fog_depth_begin = 12.0
	env.background_color = Color(0.5, 0.36, 0.28) if dawn else Color(0.015, 0.02, 0.03)
	env.fog_color = Color(0.45, 0.34, 0.28) if dawn else Color(0.03, 0.04, 0.05)
	env.ambient_light_color = Color(0.8, 0.6, 0.5) if dawn else Color(0.3, 0.38, 0.5)
	env.ambient_light_energy = 0.5 if dawn else 0.3

func _process(dt):
	_t += dt
	var on = fmod(_t, 2.4) < 0.35
	beacon.light_energy = 3.0 if on else 0.0
	get_node("bulb").visible = on
	if mode == "storm":
		_flash = max(0.0, _flash - dt * 3.0)
		if randf() < dt * 0.09 and not G.settings.reduce_flashes: _flash = 1.0
		sun.light_energy = 0.22 + _flash * 2.5
