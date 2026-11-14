extends SceneTree
# DF_MODEL=res://.../x.gltf DF_OUT=<dir> : renders front / 3-4 / side / back views with a key + rim light
func _initialize():
	var env = Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.06, 0.065, 0.07)
	env.ambient_light_color = Color(0.4, 0.42, 0.45); env.ambient_light_energy = 0.35; env.tonemap_mode = Environment.TONE_MAPPER_ACES_FITTED
	env.ssao_enabled = true
	var we = WorldEnvironment.new(); we.environment = env; get_root().add_child(we)
	var key = DirectionalLight.new(); key.rotation_degrees = Vector3(-35, 35, 0); key.light_energy = 1.4; key.shadow_enabled = true; get_root().add_child(key)
	var rim = DirectionalLight.new(); rim.rotation_degrees = Vector3(-20, 200, 0); rim.light_energy = 1.0; rim.light_color = Color(0.6, 0.75, 1.0); get_root().add_child(rim)
	var floor_ = MeshInstance.new(); var pm = PlaneMesh.new(); pm.size = Vector2(10, 10); floor_.mesh = pm; get_root().add_child(floor_)
	var s
	if OS.get_environment("DF_MODEL").ends_with(".gd"):
		s = Spatial.new(); s.set_script(load(OS.get_environment("DF_MODEL"))); get_root().add_child(s)
	else:
		s = load(OS.get_environment("DF_MODEL")).instance(); get_root().add_child(s)
	call_deferred("_run", s)
func _run(s):
	var cam = Camera.new(); get_root().add_child(cam); cam.current = true; cam.fov = 40
	var h = float(OS.get_environment("DF_H")) if OS.has_environment("DF_H") else 1.3
	var d = float(OS.get_environment("DF_D")) if OS.has_environment("DF_D") else 4.6
	if OS.has_environment("DF_ANIM"):
		for i in 3: yield(self, "idle_frame")
		s.play(OS.get_environment("DF_ANIM"), 1.0, 0.0)
		s.anim.seek(float(OS.get_environment("DF_T")) if OS.has_environment("DF_T") else 0.3, true)
		s.anim.playback_speed = 0.0
	for v in [["front", 0.0], ["q34", 35.0], ["side", 90.0], ["back", 180.0]]:
		var a = deg2rad(v[1])
		cam.translation = Vector3(sin(a) * d, h + 0.3, -cos(a) * d)
		cam.look_at(Vector3(0, h, 0), Vector3.UP)
		for i in 8: yield(self, "idle_frame")
		var img = get_root().get_texture().get_data(); img.flip_y()
		img.save_png(OS.get_environment("DF_OUT") + "/" + v[0] + ".png")
	quit()
