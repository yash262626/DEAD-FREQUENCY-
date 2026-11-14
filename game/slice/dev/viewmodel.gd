extends SceneTree
# Renders the first-person models as the player sees them, in a dark test room lit by the torch.
func _initialize():
	var env = Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.02, 0.022, 0.025)
	env.ambient_light_color = Color(0.2, 0.22, 0.25); env.ambient_light_energy = 0.25; env.tonemap_mode = Environment.TONE_MAPPER_ACES_FITTED; env.tonemap_exposure = 1.2
	var we = WorldEnvironment.new(); we.environment = env; get_root().add_child(we)
	var wall = MeshInstance.new(); var cm = CubeMesh.new(); cm.size = Vector3(6, 4, 0.2); wall.mesh = cm; wall.translation = Vector3(0, 0, -3); get_root().add_child(wall)
	var fl = MeshInstance.new(); var pm = PlaneMesh.new(); pm.size = Vector2(8, 8); fl.mesh = pm; fl.translation = Vector3(0, -1.6, -2); get_root().add_child(fl)
	var cam = Camera.new(); cam.fov = 72; cam.near = 0.02; get_root().add_child(cam); cam.current = true
	var fp = load("res://scripts/fp_models.gd").build()
	var torch = Spatial.new(); torch.translation = Vector3(0.13, -0.13, -0.27); torch.rotation_degrees = Vector3(4, 3, 0); cam.add_child(torch); torch.add_child(fp.torch)
	var radio = Spatial.new(); radio.translation = Vector3(-0.13, -0.135, -0.26); radio.rotation_degrees = Vector3(12, 18, 4); cam.add_child(radio); radio.add_child(fp.radio)
	fp.lens.emission_energy = 3.0
	var lamp = SpotLight.new(); lamp.translation = Vector3(0.13, -0.11, -0.36); lamp.spot_range = 20; lamp.spot_angle = 22; lamp.spot_angle_attenuation = 2.4; lamp.spot_attenuation = 1.0; lamp.light_energy = 2.4; lamp.shadow_enabled = true; cam.add_child(lamp)
	var spill = SpotLight.new(); spill.translation = lamp.translation; spill.spot_range = 14; spill.spot_angle = 46; spill.spot_angle_attenuation = 1.2; spill.light_energy = 0.4; cam.add_child(spill)
	var key = OmniLight.new(); key.translation = Vector3(-0.4, 0.5, 0.1); key.light_energy = 0.6; key.omni_range = 4; key.light_color = Color(1.0, 0.85, 0.7); cam.add_child(key)
	var fill = OmniLight.new(); fill.translation = Vector3(-0.6, 0.3, 0.2); fill.light_energy = 0.35; fill.omni_range = 3; fill.light_color = Color(0.5, 1.0, 0.6); cam.add_child(fill)
	call_deferred("_shot")
func _shot():
	for i in 10: yield(self, "idle_frame")
	var img = get_root().get_texture().get_data(); img.flip_y(); img.save_png(OS.get_environment("DF_OUT")); quit()
