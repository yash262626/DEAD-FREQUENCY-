extends Spatial
# Cinematic main menu over a live 3D view: the vertical slice's service corridor (the new visual standard), the camera
# creeping towards the red emergency light; the old HELIX-9 portal exterior is kept for the automated tests.
const Fx = preload("res://scripts/fx.gd")
var main
var ui
var ext
var cam: Camera
var root: Control
var list: VBoxContainer
var _t := 0.0
var art = null
var ecg: Control

func setup(m, u):
	main = m; ui = u
	var use_art = (not G.test_mode or OS.has_environment("DF_MENU_ART")) and ResourceLoader.exists("res://slice/Slice.tscn")
	if use_art:
		art = load("res://slice/Slice.tscn").instance()
		var cams = art.get_node_or_null("Cams")
		if cams:
			art.remove_child(cams); cams.free()
		add_child(art); load("res://scripts/texq.gd").apply(art)
		var fxn = art.get_node_or_null("FX")
		if fxn and Mats.enabled():
			for m in fxn.get_children():
				if m.name.begins_with("steam"): Fx.steam(self, m.global_transform.origin)
				elif m.name.begins_with("drip"): Fx.drips(self, m.global_transform.origin, m.global_transform.origin.y)
		Snd.loop("amb", "hum", -22); Snd.music("drone_a", -11)
	else:
		var env = Environment.new(); env.background_mode = Environment.BG_COLOR
		env.fog_enabled = true; env.fog_depth_enabled = true; env.glow_enabled = true
		env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		var we = WorldEnvironment.new(); we.environment = env; add_child(we)
		ext = load("res://scripts/exterior.gd").new(); add_child(ext); ext.build("storm"); ext.apply_env(env)
		Snd.loop("amb", "rain", -12); Snd.music("drone_a", -9)
	cam = Camera.new(); cam.far = 500 if art == null else 60; cam.fov = 50 if art == null else 62; add_child(cam); cam.current = true
	_cam_pose()
	root = Control.new(); root.set_anchors_and_margins_preset(Control.PRESET_WIDE); root.theme = ui.root.theme
	ui.root.add_child(root); ui.root.move_child(root, ui.fade_rect.get_index())
	var shade = ColorRect.new(); shade.color = Color(0, 0, 0, 0.35); shade.anchor_bottom = 1; shade.margin_right = 560; root.add_child(shade)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t = ui.title_node(520, 90, 54); t.rect_position = Vector2(50, 90); t.rect_size = Vector2(520, 90); root.add_child(t)
	ecg = Control.new(); ecg.rect_position = Vector2(58, 168); ecg.rect_size = Vector2(500, 26); ecg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ecg.connect("draw", self, "_draw_ecg"); root.add_child(ecg)
	var tag = ui._lbl("HELIX-9 has been silent for twenty-eight years.", 15, "m", Color(0.6, 0.62, 0.63)); tag.rect_position = Vector2(64, 202); root.add_child(tag)
	list = VBoxContainer.new(); list.rect_position = Vector2(56, 262); list.rect_size = Vector2(420, 400); root.add_child(list)
	var ver = ui._lbl("Build 0.11 — pre-release  ·  Godot 3.5", 12, "m", Color(1, 1, 1, 0.3))
	ver.anchor_top = 1; ver.anchor_bottom = 1; ver.margin_top = -30; ver.margin_left = 20; root.add_child(ver)
	_main_list()

func _exit_tree():
	if root and is_instance_valid(root): root.queue_free()

func _process(dt):
	_t += dt
	_cam_pose()
	if ecg: ecg.update()

func _cam_pose():
	if art:
		# a slow creep down the wet corridor towards the red light, breathing a little; it loops every 70 s
		var k = fmod(_t, 70.0) / 70.0; var e = k * k * (3.0 - 2.0 * k)
		var p = Vector3(5.0 + sin(_t * 0.23) * 0.05, 1.5 + sin(_t * 0.31) * 0.03, lerp(20.2, 13.0, e))
		cam.look_at_from_position(p, Vector3(5.15 + sin(_t * 0.11) * 0.25, 1.25, 6.0), Vector3.UP)
	else:
		cam.look_at_from_position(ext.points.menu + Vector3(sin(_t * 0.07) * 1.5, sin(_t * 0.11) * 0.3, cos(_t * 0.05) * 1.5),
			ext.points.gate + Vector3(6, 6, 0), Vector3.UP)

func _draw_ecg():
	# a heartbeat trace under the title, its bright head sweeping left to right
	var w = ecg.rect_size.x; var h = ecg.rect_size.y; var mid = h * 0.6
	var pts = PoolVector2Array()
	for i in 201:
		var x = w * i / 200.0; var ph = fmod(x / 125.0, 1.0); var y = mid
		if ph > 0.40 and ph < 0.44: y = mid - (ph - 0.40) / 0.04 * h * 0.25
		elif ph >= 0.44 and ph < 0.48: y = mid - h * 0.25 + (ph - 0.44) / 0.04 * h * 1.05
		elif ph >= 0.48 and ph < 0.53: y = mid + h * 0.8 - (ph - 0.48) / 0.05 * h * 1.3
		elif ph >= 0.53 and ph < 0.56: y = mid - h * 0.5 + (ph - 0.53) / 0.03 * h * 0.5
		pts.append(Vector2(x, y))
	var head = fmod(_t * 160.0, w + 120.0)
	for i in pts.size() - 1:
		var d = head - pts[i].x
		var a = 0.22 if d < 0.0 or d > 260.0 else 0.22 + 0.78 * (1.0 - d / 260.0)
		ecg.draw_line(pts[i], pts[i + 1], Color(0.86, 0.12, 0.09, a), 2.0)

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
	items += [["CHAPTER SELECTION", "chapters", G.unlocked < 2], ["VERTICAL SLICE  —  VISUAL TARGET", "slice"], ["SETTINGS", "settings"], ["CREDITS", "credits"], ["EXIT GAME", "exit"]]
	_fill(items)

func _act(id):
	Snd.play("click", -4)
	match id:
		"new": _go("new_game")
		"ngplus": _go("new_game_plus")
		"slice": _go("start_slice")
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
