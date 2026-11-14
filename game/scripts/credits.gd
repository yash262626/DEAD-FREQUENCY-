extends Node
# End-credit sequence. Names and roles are fixed by the project owner - do not edit.
var main
var ui
var root: Control
var scroll: VBoxContainer
var done := false
var _hold := 0.0
var speed := 46.0
var hint: Label

func setup(m, u):
	main = m; ui = u
	Snd.music("drone_c", -6)
	root = Control.new(); root.set_anchors_and_margins_preset(Control.PRESET_WIDE); root.theme = ui.root.theme
	ui.root.add_child(root); ui.root.move_child(root, ui.fade_rect.get_index())
	var bg = ColorRect.new(); bg.color = Color(0, 0, 0); bg.set_anchors_and_margins_preset(Control.PRESET_WIDE); root.add_child(bg)
	var fog = ColorRect.new(); fog.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	var fm = ShaderMaterial.new(); fm.shader = Shader.new(); fm.shader.code = ui.FOG_SHADER; fog.material = fm; root.add_child(fog)
	scroll = VBoxContainer.new(); scroll.anchor_left = 0.5; scroll.anchor_right = 0.5
	scroll.margin_left = -500; scroll.margin_right = 500; scroll.rect_position.y = 760
	scroll.add_constant_override("separation", 10); root.add_child(scroll)
	for row in Story.CREDITS:
		var kind = row[0]; var text = row[1]
		var l
		match kind:
			"title": l = ui._lbl(text, 64, "b", Color(0.9, 0.9, 0.9))
			"head": l = ui._lbl(ui._spaced(text), 17, "m", Color(0.7, 0.25, 0.2))
			"role": l = ui._lbl(text, 17, "r", Color(0.6, 0.62, 0.63))
			"name": l = ui._lbl(text, 34, "b", Color(0.92, 0.93, 0.94))
			"line": l = ui._lbl(text, 22, "r", Color(0.8, 0.8, 0.8))
			"gap":
				l = Control.new(); l.rect_min_size.y = float(text)
		if l is Label: l.align = Label.ALIGN_CENTER
		scroll.add_child(l)
	hint = ui._lbl("Hold SPACE / (A) to skip", 14, "r", Color(1, 1, 1, 0.4)); hint.anchor_left = 1; hint.anchor_right = 1
	hint.anchor_top = 1; hint.anchor_bottom = 1; hint.margin_left = -260; hint.margin_top = -36; root.add_child(hint)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _exit_tree():
	if root and is_instance_valid(root): root.queue_free()

func _process(dt):
	if done: return
	scroll.rect_position.y -= speed * dt * (1.0 if not G.test_mode else 60.0)
	if Input.is_action_pressed("skip"):
		_hold += dt
		if _hold > 0.8: _finish()
	else: _hold = 0.0
	# stop with the final card centred
	if scroll.rect_position.y + scroll.rect_size.y < 520: _finish()

func _finish():
	if done: return
	done = true
	scroll.rect_position.y = 520 - scroll.rect_size.y
	hint.text = ""
	var b = ui._btn("RETURN TO MAIN MENU", main, "show_menu")
	b.anchor_left = 0.5; b.anchor_right = 0.5; b.anchor_top = 1; b.anchor_bottom = 1
	b.margin_left = -160; b.margin_right = 160; b.margin_top = -90; b.margin_bottom = -50; b.align = Button.ALIGN_CENTER
	root.add_child(b); b.grab_focus()
