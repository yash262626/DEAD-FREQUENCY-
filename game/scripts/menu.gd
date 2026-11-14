extends Spatial
# Cinematic main menu over a live 3D view of the HELIX-9 portal.
var main
var ui
var ext
var cam: Camera
var root: Control
var list: VBoxContainer
var _t := 0.0

func setup(m, u):
	main = m; ui = u
	var env = Environment.new(); env.background_mode = Environment.BG_COLOR
	env.fog_enabled = true; env.fog_depth_enabled = true; env.glow_enabled = true
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we = WorldEnvironment.new(); we.environment = env; add_child(we)
	ext = load("res://scripts/exterior.gd").new(); add_child(ext); ext.build("storm"); ext.apply_env(env)
	cam = Camera.new(); cam.far = 500; cam.fov = 50; add_child(cam); cam.current = true
	cam.look_at_from_position(ext.points.menu, ext.points.gate + Vector3(6, 6, 0), Vector3.UP)
	Snd.loop("amb", "rain", -12); Snd.music("drone_a", -9)
	root = Control.new(); root.set_anchors_and_margins_preset(Control.PRESET_WIDE); root.theme = ui.root.theme
	ui.root.add_child(root); ui.root.move_child(root, ui.fade_rect.get_index())
	var shade = ColorRect.new(); shade.color = Color(0, 0, 0, 0.35); shade.anchor_bottom = 1; shade.margin_right = 560; root.add_child(shade)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t = ui.title_node(520, 90, 54); t.rect_position = Vector2(50, 90); t.rect_size = Vector2(520, 90); root.add_child(t)
	var tag = ui._lbl("HELIX-9 has been silent for twenty-eight years.", 15, "m", Color(0.6, 0.62, 0.63)); tag.rect_position = Vector2(64, 184); root.add_child(tag)
	list = VBoxContainer.new(); list.rect_position = Vector2(56, 250); list.rect_size = Vector2(420, 400); root.add_child(list)
	var ver = ui._lbl("Build 0.9.0 — pre-release  ·  Godot 3.5", 12, "m", Color(1, 1, 1, 0.3))
	ver.anchor_top = 1; ver.anchor_bottom = 1; ver.margin_top = -30; ver.margin_left = 20; root.add_child(ver)
	_main_list()

func _exit_tree():
	if root and is_instance_valid(root): root.queue_free()

func _process(dt):
	_t += dt
	cam.look_at_from_position(ext.points.menu + Vector3(sin(_t * 0.07) * 1.5, sin(_t * 0.11) * 0.3, cos(_t * 0.05) * 1.5),
		ext.points.gate + Vector3(6, 6, 0), Vector3.UP)

func _fill(items: Array):
	for c in list.get_children(): c.queue_free()
	var first = null
	for it in items:
		var b = ui._btn(it[0], self, "_act", [it[1]]); b.disabled = it.size() > 2 and it[2]
		if b.disabled: b.focus_mode = Control.FOCUS_NONE
		list.add_child(b)
		if first == null and not b.disabled: first = b
	if first: first.call_deferred("grab_focus")

func _main_list():
	var items = [["NEW GAME", "new"], ["CONTINUE", "continue", not G.has_save()]]
	if G.ng_unlocked: items.append(["NEW GAME+  —  SECOND SIGNAL", "ngplus"])
	items += [["CHAPTER SELECTION", "chapters", G.unlocked < 2], ["SETTINGS", "settings"], ["CREDITS", "credits"], ["EXIT GAME", "exit"]]
	_fill(items)

func _act(id):
	Snd.play("click", -4)
	match id:
		"new": _go("new_game")
		"ngplus": _go("new_game_plus")
		"continue": _go("continue_game")
		"chapters":
			var items = []
			for n in range(1, G.LAST_CHAPTER + 1):
				items.append(["%02d  %s" % [n, Story.chapter_title(n)] if n <= G.unlocked else "%02d  — — —" % n, n, n > G.unlocked])
			items.append(["BACK", "back"])
			_fill(items)
			for c in list.get_children(): c.add_font_override("font", ui.font(17, "b"))
		"back": _main_list()
		"settings": ui.settings_menu()
		"credits": _go("play_credits")
		"exit": get_tree().quit()
		_:
			if typeof(id) == TYPE_INT: _go("select_chapter", id)

func _go(method: String, arg = null):
	set_process(true)
	yield(ui.fade(true, 1.0), "completed")
	if arg == null: main.call(method)
	else: main.call(method, arg)
