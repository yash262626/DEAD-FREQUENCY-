extends SceneTree
# Renders a scene to a PNG:  DF_SCENE=res://... DF_OUT=/path.png [DF_CAM=NodeName] godot3 --path game -s res://slice/dev/shot.gd
func _initialize():
	var s = load(OS.get_environment("DF_SCENE")).instance()
	get_root().add_child(s)
	if OS.has_environment("DF_CAM"):
		var c = s.find_node(OS.get_environment("DF_CAM"), true, false)
		if c: c.current = true
	call_deferred("_shot")
func _shot():
	for i in int(OS.get_environment("DF_FRAMES")) if OS.has_environment("DF_FRAMES") else 12: yield(self, "idle_frame")
	var img = get_root().get_texture().get_data(); img.flip_y()
	img.save_png(OS.get_environment("DF_OUT")); printerr("saved ", OS.get_environment("DF_OUT"))
	quit()
