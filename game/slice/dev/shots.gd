extends SceneTree
# DF_SCENE=res://slice/Slice.tscn DF_OUT=<dir> DF_CAMS=Cam_a,Cam_b godot3 --path game -s res://slice/dev/shots.gd
func _initialize():
	var s = load(OS.get_environment("DF_SCENE")).instance()
	get_root().add_child(s)
	call_deferred("_run", s)
func _run(s):
	for i in 20: yield(self, "idle_frame")       # reflection probes render once
	for nm in OS.get_environment("DF_CAMS").split(","):
		var c = s.find_node(nm, true, false)
		if c == null:
			printerr("no camera ", nm)
			continue
		c.current = true
		for i in 6: yield(self, "idle_frame")
		var img = get_root().get_texture().get_data(); img.flip_y()
		img.save_png(OS.get_environment("DF_OUT") + "/" + nm + ".png"); printerr("saved ", nm)
	quit()
