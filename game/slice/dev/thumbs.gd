extends SceneTree
# Renders a thumbnail of every model in res://assets/models into DF_OUT/<id>.png and prints its size.
var ids = []
var holder
func _initialize():
	var d = Directory.new(); d.open("res://assets/models"); d.list_dir_begin(true, true)
	var n = d.get_next()
	while n != "":
		if d.current_is_dir(): ids.append(n)
		n = d.get_next()
	ids.sort(); printerr("models: ", ids.size())
	var env = Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.18, 0.18, 0.2)
	env.ambient_light_color = Color(0.5, 0.5, 0.55); env.ambient_light_energy = 0.6; env.tonemap_mode = Environment.TONE_MAPPER_ACES_FITTED
	var we = WorldEnvironment.new(); we.environment = env; get_root().add_child(we)
	var sun = DirectionalLight.new(); sun.rotation_degrees = Vector3(-40, 30, 0); sun.light_energy = 1.2; get_root().add_child(sun)
	call_deferred("_run")

func _aabb(n: Node, xf: Transform, acc: Array):
	if n is VisualInstance and n.has_method("get_aabb"):
		var a = (xf * n.transform).xform(n.get_aabb()) if false else n.get_transformed_aabb()
		if acc[0] == null: acc[0] = a
		else: acc[0] = acc[0].merge(a)
	for c in n.get_children(): _aabb(c, xf, acc)

func _run():
	printerr("run"); var cam = Camera.new(); get_root().add_child(cam); cam.current = true; cam.fov = 40
	for id in ids:
		var path = "res://assets/models/%s/%s.gltf" % [id, id]
		if not ResourceLoader.exists(path):
			printerr("missing ", path)
			continue
		printerr("load ", id); var s = load(path).instance(); get_root().add_child(s); printerr("added")
		yield(self, "idle_frame")
		var acc = [null]; _aabb(s, Transform(), acc)
		var a: AABB = acc[0]
		var c = a.position + a.size * 0.5; var r = a.size.length() * 0.5
		cam.translation = c + Vector3(1, 0.6, 1.4).normalized() * r * 3.2
		cam.look_at(c, Vector3.UP)
		for i in 3: yield(self, "idle_frame")
		var img = get_root().get_texture().get_data(); img.flip_y()
		img.save_png(OS.get_environment("DF_OUT") + "/" + id + ".png")
		printerr("%s size %.2f x %.2f x %.2f" % [id, a.size.x, a.size.y, a.size.z])
		s.queue_free()
	quit()
