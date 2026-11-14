tool
extends EditorPlugin
# Command-line lightmap baking inside the real editor (BakedLightmap.bake() needs the editor's file system).
#   DF_BAKE=res://slice/Slice.tscn godot3 --path game --editor
# Opens the scene, bakes every BakedLightmap in it, saves the scene and quits. Without DF_BAKE it does nothing.

func _enter_tree():
	if OS.has_environment("DF_BAKE"):
		call_deferred("_bake_when_ready")

func _bake_when_ready():
	var fs = get_editor_interface().get_resource_filesystem()
	for i in 600:
		yield(get_tree(), "idle_frame")
		if i > 30 and not fs.is_scanning(): break
	var path = OS.get_environment("DF_BAKE")
	printerr("[df_tools] opening ", path)
	get_editor_interface().open_scene_from_path(path)
	for i in 30: yield(get_tree(), "idle_frame")
	var root = get_editor_interface().get_edited_scene_root()
	if root == null:
		printerr("[df_tools] could not open ", path); get_tree().quit(); return
	var ok = true
	for bl in _find(root, []):
		var t0 = OS.get_ticks_msec()
		var err = bl.bake(root, path.get_basename() + "_" + bl.name.to_lower() + ".lmbake")
		printerr("[df_tools] baked ", bl.name, " err=", err, " in ", (OS.get_ticks_msec() - t0) / 1000.0, " s")
		ok = ok and err == BakedLightmap.BAKE_ERROR_OK
	get_editor_interface().save_scene()
	for i in 10: yield(get_tree(), "idle_frame")
	printerr("[df_tools] done ok=", ok)
	get_tree().quit()

func _find(n, out: Array) -> Array:
	if n is BakedLightmap: out.append(n)
	for c in n.get_children(): _find(c, out)
	return out
