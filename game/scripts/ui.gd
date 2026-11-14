extends CanvasLayer
# All 2D presentation: HUD, subtitles, menus, cards, title reveal, journal, settings.

signal closed            # generic "modal finished"
signal chosen(idx)
signal menu_action(id)

const W := 1280.0
const H := 720.0
const WHO := {
	"DANIEL": [Color(0.86, 0.88, 0.9), 0.86], "EVELYN": [Color(0.75, 0.9, 1.0), 1.22],
	"MARCUS": [Color(1.0, 0.82, 0.6), 0.72], "MIRA": [Color(0.8, 1.0, 0.82), 1.38],
	"LISTENER": [Color(1.0, 0.45, 0.45), 0.5], "RADIO": [Color(0.7, 0.85, 0.75), 1.0],
	"PA": [Color(0.9, 0.85, 0.55), 0.95], "": [Color(0.8, 0.8, 0.8), 1.0],
}

var root: Control
var fade_rect: ColorRect
var post: ColorRect
var sub: RichTextLabel
var obj_lbl: Label
var prompt_lbl: Label
var cross: ColorRect
var toast_lbl: Label
var bars: Control
var radio_panel: Control
var big_lbl: Label
var modal: Control = null
var modals := 0
var _saying := false
var _fonts := {}
var objective_text := ""
var hud_on := false
var radio_state := {"on": false, "f": 89.1, "sig": 0.0, "batt": 100.0, "band": "", "danger": 0.0}
var stat := {"hp": 100.0, "batt": 100.0, "stam": 100.0, "light": false, "cells": 0, "hidden": false}
var _voice: AudioStreamPlayer
var _skip_hold := 0.0
var in_cine := false
var skip_lbl: Label

func font(size: int, kind := "r") -> DynamicFont:
	var k = "%s%d" % [kind, size]
	if _fonts.has(k): return _fonts[k]
	var f = DynamicFont.new()
	f.font_data = load({"r": "res://fonts/LiberationSans-Regular.ttf", "b": "res://fonts/LiberationSans-Bold.ttf",
		"m": "res://fonts/LiberationMono-Regular.ttf"}[kind])
	f.size = size; f.use_filter = true
	_fonts[k] = f
	return f

func _lbl(text, size, kind := "r", col := Color(0.85, 0.87, 0.88)) -> Label:
	var l = Label.new(); l.text = text
	l.add_font_override("font", font(size, kind)); l.add_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _ready():
	layer = 10
	pause_mode = Node.PAUSE_MODE_PROCESS
	root = Control.new(); root.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(root)
	root.theme = _theme()
	# post overlay (grain / vignette / damage / interference)
	post = ColorRect.new(); post.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sm = ShaderMaterial.new(); sm.shader = Shader.new(); sm.shader.code = POST_SHADER
	post.material = sm; root.add_child(post)
	# HUD
	cross = ColorRect.new(); cross.color = Color(1, 1, 1, 0.35); cross.rect_size = Vector2(3, 3)
	cross.set_anchors_and_margins_preset(Control.PRESET_CENTER); cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(cross)
	prompt_lbl = _lbl("", 18, "r"); prompt_lbl.align = Label.ALIGN_CENTER
	prompt_lbl.anchor_left = 0; prompt_lbl.anchor_right = 1; prompt_lbl.anchor_top = 0.56; prompt_lbl.anchor_bottom = 0.56
	prompt_lbl.margin_bottom = 30; root.add_child(prompt_lbl)
	obj_lbl = _lbl("", 16, "r", Color(0.8, 0.82, 0.8, 0.9))
	obj_lbl.rect_position = Vector2(28, 22); obj_lbl.modulate.a = 0; root.add_child(obj_lbl)
	toast_lbl = _lbl("", 16, "b", Color(0.9, 0.85, 0.6)); toast_lbl.align = Label.ALIGN_RIGHT
	toast_lbl.anchor_left = 1; toast_lbl.anchor_right = 1; toast_lbl.margin_left = -620; toast_lbl.margin_right = -28
	toast_lbl.margin_top = 22; toast_lbl.modulate.a = 0; root.add_child(toast_lbl)
	bars = Control.new(); bars.set_script(preload("res://scripts/hud_draw.gd")); bars.ui = self
	bars.set_anchors_and_margins_preset(Control.PRESET_WIDE); bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bars)
	sub = RichTextLabel.new(); sub.bbcode_enabled = true; sub.scroll_active = false
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub.anchor_left = 0.14; sub.anchor_right = 0.86; sub.anchor_top = 1; sub.anchor_bottom = 1
	sub.margin_top = -150; sub.margin_bottom = -40
	root.add_child(sub); _sub_fonts()
	big_lbl = _lbl("", 30, "b"); big_lbl.align = Label.ALIGN_CENTER; big_lbl.valign = Label.VALIGN_CENTER
	big_lbl.set_anchors_and_margins_preset(Control.PRESET_WIDE); big_lbl.modulate.a = 0
	fade_rect = ColorRect.new(); fade_rect.color = Color(0, 0, 0, 1)
	fade_rect.set_anchors_and_margins_preset(Control.PRESET_WIDE); fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fade_rect); root.add_child(big_lbl)
	# subtitles must stay readable above fades
	root.move_child(sub, root.get_child_count() - 1)
	skip_lbl = _lbl("", 14, "r", Color(1, 1, 1, 0.5)); skip_lbl.align = Label.ALIGN_RIGHT
	skip_lbl.anchor_left = 1; skip_lbl.anchor_right = 1; skip_lbl.anchor_top = 1; skip_lbl.anchor_bottom = 1
	skip_lbl.margin_left = -400; skip_lbl.margin_right = -28; skip_lbl.margin_top = -36; root.add_child(skip_lbl)
	_voice = AudioStreamPlayer.new(); _voice.bus = "Voice"; add_child(_voice)
	G.connect("toast", self, "toast")
	G.connect("settings_changed", self, "_sub_fonts")
	set_hud(false)

func _sub_fonts():
	if sub == null: return
	var s = [18, 22, 28][int(G.settings.sub_size)]
	sub.add_font_override("normal_font", font(s, "r")); sub.add_font_override("bold_font", font(s, "b"))

func _marg(sb: StyleBox, v: float):
	sb.content_margin_left = v; sb.content_margin_right = v; sb.content_margin_top = v; sb.content_margin_bottom = v

func _theme() -> Theme:
	var t = Theme.new()
	t.default_font = font(20, "r")
	var e = StyleBoxEmpty.new()
	var hov = StyleBoxFlat.new(); hov.bg_color = Color(1, 1, 1, 0.06); hov.border_width_left = 3
	hov.border_color = Color(0.75, 0.2, 0.15); hov.content_margin_left = 14
	var nrm = StyleBoxFlat.new(); nrm.bg_color = Color(0, 0, 0, 0); nrm.content_margin_left = 14
	for s in ["normal", "disabled", "pressed"]: t.set_stylebox(s, "Button", nrm)
	t.set_stylebox("hover", "Button", hov); t.set_stylebox("focus", "Button", hov)
	t.set_color("font_color", "Button", Color(0.72, 0.74, 0.75)); t.set_color("font_color_hover", "Button", Color(1, 1, 1))
	t.set_color("font_color_disabled", "Button", Color(0.3, 0.3, 0.3))
	t.set_font("font", "Button", font(22, "b"))
	var pn = StyleBoxFlat.new(); pn.bg_color = Color(0.03, 0.035, 0.04, 0.94); pn.border_color = Color(0.25, 0.27, 0.28)
	pn.set_border_width_all(1); _marg(pn, 22)
	t.set_stylebox("panel", "PanelContainer", pn); t.set_stylebox("panel", "Panel", pn)
	t.set_stylebox("focus", "CheckBox", e)
	return t

func _process(dt):
	var m = post.material
	m.set_shader_param("dmg", clamp((60.0 - stat.hp) / 60.0, 0, 1) if hud_on else 0.0)
	m.set_shader_param("stat", radio_state.danger if hud_on else 0.0)
	m.set_shader_param("hide", 1.0 if (hud_on and stat.hidden) else 0.0)
	# hold-to-skip for cinematics
	if in_cine and not G.skip:
		if Input.is_action_pressed("skip"):
			_skip_hold += dt
			skip_lbl.text = "Skipping" + ".".repeat(int(_skip_hold * 4) % 4)
			if _skip_hold > 0.8:
				G.skip = true; _voice.stop()
		else:
			_skip_hold = 0.0; skip_lbl.text = "Hold SPACE / (A) to skip"
	else:
		skip_lbl.text = ""; _skip_hold = 0.0
	bars.update()

func set_hud(on: bool):
	hud_on = on
	for c in [cross, prompt_lbl, obj_lbl, bars]: c.visible = on

func set_cine(on: bool):
	in_cine = on
	if not on: G.skip = false
	cross.visible = hud_on and not on; prompt_lbl.visible = hud_on and not on; bars.visible = hud_on and not on

# ------------------------------------------------------------ helpers
func wait(t: float):
	if G.skip or t <= 0:
		yield(get_tree(), "idle_frame")
	else:
		yield(get_tree().create_timer(t, false), "timeout")

func fade(to_black: bool, t := 1.0):
	var target = 1.0 if to_black else 0.0
	if G.skip or t <= 0:
		fade_rect.color.a = target
		yield(get_tree(), "idle_frame")
		return
	var tw = Tween.new(); add_child(tw)
	tw.interpolate_property(fade_rect, "color:a", fade_rect.color.a, target, t, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tw.start()
	yield(tw, "tween_all_completed")
	tw.queue_free()

func _fade_node(n: CanvasItem, a: float, t: float):
	if G.skip or t <= 0:
		n.modulate.a = a
		yield(get_tree(), "idle_frame")
		return
	var tw = Tween.new(); add_child(tw)
	tw.interpolate_property(n, "modulate:a", n.modulate.a, a, t)
	tw.start()
	yield(tw, "tween_all_completed")
	tw.queue_free()

func say(who: String, text: String, dur := -1.0):
	while _saying:
		yield(get_tree(), "idle_frame")
	if G.skip:
		yield(get_tree(), "idle_frame")
		return
	_saying = true
	if dur <= 0: dur = clamp(1.4 + text.length() * 0.058, 2.0, 9.0)
	var base = who.split(" ")[0].replace("?", "")
	var info = WHO.get(base, WHO[""])
	if G.settings.subtitles:
		var name = ("[b][color=#%s]%s[/color][/b]   " % [info[0].to_html(false), who]) if who != "" else ""
		sub.bbcode_text = "[center]" + name + text + "[/center]"
	if who != "" and Snd.bank.has("voice"):
		_voice.stream = Snd.bank["voice"]; _voice.pitch_scale = info[1] * rand_range(0.96, 1.04)
		_voice.volume_db = -13.0; _voice.play()
	var t = 0.0
	while t < dur and not G.skip:
		yield(get_tree(), "idle_frame")
		if not get_tree().paused: t += get_process_delta_time()
		if who != "" and not _voice.playing and t < dur - 0.9 and not get_tree().paused: _voice.play()
	_voice.stop(); sub.bbcode_text = ""
	_saying = false

func objective(text: String):
	objective_text = text
	obj_lbl.text = "▸ " + text if text != "" else ""
	obj_lbl.modulate.a = 1.0
	Snd.play("click", -10)
	yield(get_tree().create_timer(6.0, false), "timeout")
	if objective_text == text: _fade_node(obj_lbl, 0.0, 1.5)

func toast(text: String):
	toast_lbl.text = text; toast_lbl.modulate.a = 1.0
	yield(get_tree().create_timer(3.5), "timeout")
	if toast_lbl.text == text: _fade_node(toast_lbl, 0.0, 1.0)

func prompt(text: String):
	prompt_lbl.text = text

func big_text(text: String, dur := 3.0, size := 30):
	big_lbl.add_font_override("font", font(size, "b")); big_lbl.text = text
	yield(_fade_node(big_lbl, 1.0, 1.0), "completed")
	yield(wait(dur), "completed")
	yield(_fade_node(big_lbl, 0.0, 1.0), "completed")
	big_lbl.text = ""

# ------------------------------------------------------------ chapter card
func chapter_card(num: int, title: String, subt := "", tint := Color(0.75, 0.2, 0.15)):
	var c = Control.new(); c.set_anchors_and_margins_preset(Control.PRESET_WIDE); c.modulate.a = 0
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg = ColorRect.new(); bg.color = Color(0, 0, 0, 1); bg.set_anchors_and_margins_preset(Control.PRESET_WIDE); c.add_child(bg)
	var line = ColorRect.new(); line.color = tint; line.rect_position = Vector2(W / 2 - 1, 268); line.rect_size = Vector2(2, 2); c.add_child(line)
	var a = _lbl("CHAPTER %02d" % num, 20, "m", Color(0.6, 0.62, 0.63)); a.align = Label.ALIGN_CENTER
	a.rect_position = Vector2(0, 230); a.rect_size = Vector2(W, 30); c.add_child(a)
	var b = _lbl(_spaced(title), 54, "b", Color(0.92, 0.93, 0.94)); b.align = Label.ALIGN_CENTER
	b.rect_position = Vector2(0, 290); b.rect_size = Vector2(W, 70); c.add_child(b)
	var s = _lbl(subt, 18, "m", Color(0.55, 0.57, 0.58)); s.align = Label.ALIGN_CENTER
	s.rect_position = Vector2(0, 378); s.rect_size = Vector2(W, 30); c.add_child(s)
	for n in [a, b, s, line]:
		n.anchor_left = 0.5; n.anchor_right = 0.5; n.anchor_top = 0.5; n.anchor_bottom = 0.5
		n.margin_left = n.rect_position.x - W / 2; n.margin_right = n.margin_left + n.rect_size.x
		n.margin_top = n.rect_position.y - H / 2; n.margin_bottom = n.margin_top + n.rect_size.y
	root.add_child(c)
	Snd.play("impact", -6, 0.8 + 0.03 * (num % 5)); Snd.play("static", -18, 0.6 + 0.05 * (num % 4))
	var tw = Tween.new(); c.add_child(tw)
	if not G.skip:
		tw.interpolate_property(line, "margin_left", -1, -220, 1.6, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		tw.interpolate_property(line, "margin_right", 1, 220, 1.6, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		tw.start()
	yield(_fade_node(c, 1.0, 1.2), "completed")
	yield(wait(3.2), "completed")
	yield(_fade_node(c, 0.0, 1.4), "completed")
	c.queue_free()

func _spaced(s: String) -> String:
	var o = ""
	for ch in s: o += ch + " "
	return o.strip_edges()

# ------------------------------------------------------------ title reveal
func title_reveal(tagline := ""):
	var c = Control.new(); c.set_anchors_and_margins_preset(Control.PRESET_WIDE); c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg = ColorRect.new(); bg.color = Color(0, 0, 0, 1); bg.set_anchors_and_margins_preset(Control.PRESET_WIDE); c.add_child(bg)
	var fog = ColorRect.new(); fog.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	var fm = ShaderMaterial.new(); fm.shader = Shader.new(); fm.shader.code = FOG_SHADER; fog.material = fm; c.add_child(fog)
	var tr = title_node(1100, 220, 118)
	tr.anchor_left = 0.5; tr.anchor_right = 0.5; tr.anchor_top = 0.5; tr.anchor_bottom = 0.5
	tr.margin_left = -550; tr.margin_right = 550; tr.margin_top = -130; tr.margin_bottom = 90
	c.add_child(tr)
	var tg = _lbl(tagline, 18, "m", Color(0.6, 0.62, 0.63)); tg.align = Label.ALIGN_CENTER
	tg.anchor_left = 0; tg.anchor_right = 1; tg.anchor_top = 0.5; tg.anchor_bottom = 0.5; tg.margin_top = 110; tg.margin_bottom = 140
	tg.modulate.a = 0; c.add_child(tg)
	root.add_child(c)
	var m = tr.material
	m.set_shader_param("glitch", 1.0); m.set_shader_param("reveal", 0.0)
	Snd.play("glitch", 0); Snd.play("impact", 2, 0.7); Snd.play("static", -8)
	if not G.settings.reduce_flashes and not G.skip:
		for i in 5:
			m.set_shader_param("reveal", 1.0 if i % 2 == 0 else 0.15)
			yield(wait(0.06), "completed")
	m.set_shader_param("reveal", 1.0)
	var tw = Tween.new(); c.add_child(tw)
	tw.interpolate_property(m, "shader_param/glitch", 1.0, 0.12, 2.2, Tween.TRANS_EXPO, Tween.EASE_OUT)
	tw.interpolate_property(tr, "rect_scale", Vector2(1.06, 1.06), Vector2(1, 1), 6.0, Tween.TRANS_SINE, Tween.EASE_OUT)
	tr.rect_pivot_offset = Vector2(550, 110)
	tw.start()
	Snd.music("drone_d", -6)
	yield(wait(2.2), "completed")
	if tagline != "": _fade_node(tg, 1.0, 1.5)
	yield(wait(4.0), "completed")
	m.set_shader_param("glitch", 0.8); Snd.play("glitch", -4)
	yield(wait(0.25), "completed")
	fade_rect.color.a = 1.0
	c.queue_free()
	yield(wait(0.8), "completed")

func title_node(w: int, h: int, size: int) -> TextureRect:
	var vp = Viewport.new(); vp.size = Vector2(w, h); vp.transparent_bg = true
	vp.render_target_v_flip = true; vp.usage = Viewport.USAGE_2D; vp.render_target_update_mode = Viewport.UPDATE_ALWAYS
	var l = _lbl("DEAD FREQUENCY", size, "b", Color(1, 1, 1)); l.align = Label.ALIGN_CENTER; l.valign = Label.VALIGN_CENTER
	l.rect_size = Vector2(w, h); vp.add_child(l)
	var tr = TextureRect.new(); tr.add_child(vp)
	tr.texture = vp.get_texture(); tr.expand = true; tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sm = ShaderMaterial.new(); sm.shader = Shader.new(); sm.shader.code = TITLE_SHADER
	sm.set_shader_param("glitch", 0.1); sm.set_shader_param("reveal", 1.0)
	tr.material = sm
	return tr

# ------------------------------------------------------------ monitor overlay
func monitor(lines: Array, hold := 2.5):
	var c = ColorRect.new(); c.color = Color(0.0, 0.03, 0.01, 0.96); c.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l = _lbl("", 34, "m", Color(0.45, 1.0, 0.55)); l.align = Label.ALIGN_CENTER; l.valign = Label.VALIGN_CENTER
	l.set_anchors_and_margins_preset(Control.PRESET_WIDE); c.add_child(l)
	root.add_child(c); root.move_child(c, fade_rect.get_index() + 1)
	var txt = ""
	for ln in lines:
		for ch in ln:
			txt += ch; l.text = txt + "█"
			if not G.skip and ch != " ":
				Snd.play("click", -16, 1.6)
				yield(wait(0.045), "completed")
		txt += "\n\n"
		yield(wait(0.7), "completed")
	l.text = txt
	yield(wait(hold), "completed")
	Snd.play("glitch", -2)
	c.queue_free()

# ------------------------------------------------------------ modals
func _open_modal(c: Control, pause := true):
	modal = c; modals += 1
	root.add_child(c)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if pause: get_tree().paused = true

func close_modal(unpause := true):
	if modal and is_instance_valid(modal): modal.queue_free()
	modal = null; modals = max(0, modals - 1)
	if unpause: get_tree().paused = false
	if hud_on and modals == 0: Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	emit_signal("closed")

func _panel(w: float, h: float) -> PanelContainer:
	var p = PanelContainer.new()
	p.anchor_left = 0.5; p.anchor_right = 0.5; p.anchor_top = 0.5; p.anchor_bottom = 0.5
	p.margin_left = -w / 2; p.margin_right = w / 2; p.margin_top = -h / 2; p.margin_bottom = h / 2
	return p

func _dim() -> ColorRect:
	var d = ColorRect.new(); d.color = Color(0, 0, 0, 0.72); d.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	return d

func _btn(text: String, target: Object, method: String, binds := []) -> Button:
	var b = Button.new(); b.text = text; b.align = Button.ALIGN_LEFT; b.focus_mode = Control.FOCUS_ALL
	b.connect("pressed", target, method, binds)
	b.connect("mouse_entered", b, "grab_focus")
	b.connect("focus_entered", self, "_tick")
	return b

func _tick(): Snd.play("click", -18, 1.3)

func read(title: String, text: String):
	if G.test_mode:
		call_deferred("emit_signal", "closed"); return
	var d = _dim()
	var p = _panel(760, 560); d.add_child(p)
	var sb = StyleBoxFlat.new(); sb.bg_color = Color(0.82, 0.79, 0.7); _marg(sb, 34)
	p.add_stylebox_override("panel", sb)
	var v = VBoxContainer.new(); p.add_child(v)
	var t = _lbl(title, 24, "b", Color(0.12, 0.1, 0.08)); v.add_child(t)
	var r = RichTextLabel.new(); r.bbcode_enabled = false; r.text = text; r.size_flags_vertical = Control.SIZE_EXPAND_FILL
	r.add_font_override("normal_font", font(18, "m")); r.add_color_override("default_color", Color(0.15, 0.13, 0.1))
	v.add_child(r)
	var b = _btn("Close  [F / Esc]", self, "close_modal"); b.add_color_override("font_color", Color(0.3, 0.1, 0.08))
	b.add_color_override("font_color_hover", Color(0.5, 0.1, 0.08)); v.add_child(b)
	_open_modal(d); b.grab_focus()
	Snd.play("pickup", -8)

func choice(text: String, options: Array):
	var d = Control.new(); d.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	var p = _panel(720, 150 + 52 * options.size()); p.anchor_top = 0.62; p.anchor_bottom = 0.62; d.add_child(p)
	var v = VBoxContainer.new(); p.add_child(v)
	var t = _lbl(text, 20, "r"); t.autowrap = true; v.add_child(t)
	var first = null
	for i in options.size():
		var b = _btn(options[i], self, "_choose", [i]); v.add_child(b)
		if first == null: first = b
	_open_modal(d, false); first.grab_focus()

func _choose(i):
	close_modal(false)
	emit_signal("chosen", i)

var _kp_edit: LineEdit
var keypad_result := ""
func keypad(title: String):
	var d = _dim(); var p = _panel(420, 230); d.add_child(p)
	var v = VBoxContainer.new(); p.add_child(v)
	v.add_child(_lbl(title, 20, "b"))
	_kp_edit = LineEdit.new(); _kp_edit.max_length = 6; _kp_edit.add_font_override("font", font(34, "m"))
	_kp_edit.align = LineEdit.ALIGN_CENTER; v.add_child(_kp_edit)
	_kp_edit.connect("text_entered", self, "_kp_done")
	var h = HBoxContainer.new(); v.add_child(h)
	h.add_child(_btn("Enter", self, "_kp_done", [null])); h.add_child(_btn("Cancel", self, "_kp_cancel"))
	keypad_result = ""
	_open_modal(d); _kp_edit.grab_focus()
func _kp_done(_t):
	keypad_result = _kp_edit.text.strip_edges(); close_modal()
func _kp_cancel():
	keypad_result = ""; close_modal()

func game_over():
	var d = ColorRect.new(); d.color = Color(0, 0, 0, 0.0); d.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	var v = VBoxContainer.new(); v.anchor_left = 0.5; v.anchor_right = 0.5; v.anchor_top = 0.5; v.anchor_bottom = 0.5
	v.margin_left = -200; v.margin_right = 200; v.margin_top = -90; v.margin_bottom = 90; d.add_child(v)
	var t = _lbl("SIGNAL LOST", 44, "b", Color(0.75, 0.15, 0.12)); t.align = Label.ALIGN_CENTER; v.add_child(t)
	var b = _btn("Resume from last checkpoint", self, "_menu", ["reload"]); v.add_child(b)
	v.add_child(_btn("Main menu", self, "_menu", ["mainmenu"]))
	_open_modal(d); d.color.a = 0.9; b.grab_focus()

func pause_menu():
	if modal != null: return
	var d = _dim(); var p = _panel(420, 400); d.add_child(p)
	var v = VBoxContainer.new(); p.add_child(v)
	v.add_child(_lbl("PAUSED", 30, "b"))
	var o = _lbl(objective_text, 15, "r", Color(0.6, 0.62, 0.6)); o.autowrap = true; v.add_child(o)
	var b = _btn("Resume", self, "close_modal"); v.add_child(b)
	v.add_child(_btn("Journal", self, "_menu", ["journal"]))
	v.add_child(_btn("Settings", self, "_menu", ["settings"]))
	v.add_child(_btn("Reload checkpoint", self, "_menu", ["reload"]))
	v.add_child(_btn("Main menu", self, "_menu", ["mainmenu"]))
	_open_modal(d); b.grab_focus()

func _menu(id):
	if id == "settings":
		close_modal(false); settings_menu(); return
	if id == "journal":
		close_modal(false); journal_screen(); return
	close_modal()
	emit_signal("menu_action", id)

func _input(ev):
	if modal == null: return
	if ev.is_action_pressed("pause") or (ev.is_action_pressed("journal") and not _kp_edit_focus()):
		if modal.has_meta("noclose"): return
		get_tree().set_input_as_handled()
		close_modal()
func _kp_edit_focus() -> bool:
	return _kp_edit != null and is_instance_valid(_kp_edit) and _kp_edit.has_focus()

# ------------------------------------------------------------ journal / inventory
var _j_text: RichTextLabel
func journal_screen():
	if modal != null: return
	var d = _dim(); var p = _panel(1040, 600); d.add_child(p)
	var h = HBoxContainer.new(); p.add_child(h)
	var left = VBoxContainer.new(); left.rect_min_size.x = 360; h.add_child(left)
	left.add_child(_lbl("JOURNAL", 26, "b"))
	var o = _lbl("Objective: " + objective_text, 15, "r", Color(0.9, 0.85, 0.6)); o.autowrap = true; left.add_child(o)
	var inv = "Carrying: "
	var names = []
	for k in G.inv:
		if G.inv[k] > 0: names.append("%s ×%d" % [Story.ITEMS.get(k, k), G.inv[k]])
	inv += PoolStringArray(names).join(", ") if names.size() else "nothing"
	var il = _lbl(inv, 15, "r", Color(0.65, 0.7, 0.72)); il.autowrap = true; left.add_child(il)
	var sc = ScrollContainer.new(); sc.size_flags_vertical = Control.SIZE_EXPAND_FILL; left.add_child(sc)
	var lv = VBoxContainer.new(); lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL; sc.add_child(lv)
	_j_text = RichTextLabel.new(); _j_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_j_text.add_font_override("normal_font", font(17, "m")); h.add_child(_j_text)
	var first = null
	for i in range(G.journal.size() - 1, -1, -1):
		var j = G.journal[i]
		var b = _btn(("◉ " if j.k == "tape" else "▤ ") + j.t, self, "_j_show", [i])
		b.add_font_override("font", font(16, "r")); b.clip_text = true; lv.add_child(b)
		if first == null: first = b
	var cb = _btn("Close  [Tab / Esc]", self, "close_modal"); left.add_child(cb)
	_open_modal(d)
	if first:
		first.grab_focus(); _j_show(G.journal.size() - 1)
	else:
		cb.grab_focus(); _j_text.text = "Nothing recorded yet."
func _j_show(i): _j_text.text = G.journal[i].t + "\n\n" + G.journal[i].x

# ------------------------------------------------------------ settings
const SET_SPEC = [
	["master", "Master volume", "slider", 0, 1], ["music", "Music volume", "slider", 0, 1], ["sfx", "Effects & voice volume", "slider", 0, 1],
	["sens", "Look sensitivity", "slider", 0.2, 3], ["fov", "Field of view", "slider", 60, 100],
	["brightness", "Brightness", "slider", 0.6, 1.8],
	["quality", "Graphics preset", "opt", ["Low", "Medium", "High", "Ultra"]],
	["sub_size", "Subtitle size", "opt", ["Small", "Medium", "Large"]],
	["fullscreen", "Fullscreen", "check"], ["vsync", "V-Sync", "check"], ["subtitles", "Subtitles", "check"],
	["invert_y", "Invert Y axis", "check"], ["head_bob", "Head bob", "check"], ["toggle_crouch", "Toggle crouch", "check"],
	["reduce_flashes", "Reduce flashing effects", "check"],
]
func settings_menu():
	var d = _dim(); var p = _panel(760, 640); d.add_child(p)
	var v = VBoxContainer.new(); p.add_child(v)
	v.add_child(_lbl("SETTINGS", 28, "b"))
	var sc = ScrollContainer.new(); sc.size_flags_vertical = Control.SIZE_EXPAND_FILL; v.add_child(sc)
	var g = GridContainer.new(); g.columns = 2; g.size_flags_horizontal = Control.SIZE_EXPAND_FILL; sc.add_child(g)
	g.add_constant_override("hseparation", 30); g.add_constant_override("vseparation", 8)
	var first = null
	for s in SET_SPEC:
		var l = _lbl(s[1], 18); l.rect_min_size.x = 320; g.add_child(l)
		var c
		match s[2]:
			"slider":
				c = HSlider.new(); c.min_value = s[3]; c.max_value = s[4]; c.step = (s[4] - s[3]) / 40.0
				c.value = G.settings[s[0]]; c.rect_min_size = Vector2(300, 24)
				c.connect("value_changed", self, "_set", [s[0]])
			"opt":
				c = OptionButton.new()
				for it in s[3]: c.add_item(it)
				c.selected = int(G.settings[s[0]]); c.connect("item_selected", self, "_set", [s[0]])
			"check":
				c = CheckBox.new(); c.pressed = G.settings[s[0]]; c.connect("toggled", self, "_set", [s[0]])
		g.add_child(c)
		if first == null: first = c
	var ctl = _lbl("Controls — WASD move · Shift sprint · Ctrl/C crouch · Q/E lean · F/LMB interact · T flashlight · R/RMB radio · Wheel/←→ tune · G throw · H medkit · Tab journal\nGamepad — sticks move/look · A interact · B crouch · X radio · Y flashlight · L3 sprint · LB/RB lean · D-pad ←→ tune, ↑ medkit, ↓ throw", 13, "r", Color(0.55, 0.57, 0.58))
	ctl.autowrap = true; v.add_child(ctl)
	var b = _btn("Back", self, "_set_close"); v.add_child(b)
	_open_modal(d); first.grab_focus()
func _set(val, key):
	G.settings[key] = val; G.apply_settings()
func _set_close():
	G.save_profile(); close_modal()

# ------------------------------------------------------------ shaders
const POST_SHADER = """
shader_type canvas_item;
uniform float dmg = 0.0; uniform float stat = 0.0; uniform float hide = 0.0;
float h(vec2 p){ return fract(sin(dot(p, vec2(12.9898,78.233))) * 43758.5453); }
void fragment(){
	vec2 p = UV - 0.5; float r = length(p);
	float n = h(UV * vec2(1280.0, 720.0) + fract(TIME) * 91.7);
	float v = smoothstep(0.38, 0.9, r) * 0.75;
	float line = step(0.975, h(vec2(floor(UV.y * 220.0), floor(TIME * 24.0)))) * stat;
	float d = dmg * smoothstep(0.15, 0.75, r) * (0.75 + 0.25 * sin(TIME * 5.0));
	float slit = hide * (1.0 - smoothstep(0.0, 0.06, abs(fract(UV.y * 6.0) - 0.5) - 0.18)) ;
	vec3 c = vec3(0.45, 0.0, 0.0) * d + vec3(n) * (stat * 0.5 + 0.04) + vec3(line * 0.6);
	float a = clamp(v + n * 0.05 + d * 0.7 + stat * n * 0.45 + line * 0.35 + slit * 0.93, 0.0, 1.0);
	COLOR = vec4(c * (1.0 - slit), a);
}"""
const TITLE_SHADER = """
shader_type canvas_item;
uniform float glitch = 0.1; uniform float reveal = 1.0;
float h(vec2 p){ return fract(sin(dot(p, vec2(12.9898,78.233))) * 43758.5453); }
void fragment(){
	vec2 uv = UV;
	float band = floor(uv.y * 34.0);
	float on = step(0.72, h(vec2(floor(TIME * 11.0), band)));
	uv.x += (h(vec2(band, floor(TIME * 19.0))) - 0.5) * glitch * 0.09 * on;
	float sp = 0.0025 + glitch * 0.012;
	float a = texture(TEXTURE, uv).a;
	float ar = texture(TEXTURE, uv + vec2(sp, 0.0)).a;
	float ab = texture(TEXTURE, uv - vec2(sp, 0.0)).a;
	float g = 0.58 + 0.42 * sin(uv.y * 11.0 + 0.6);
	float sc = h(vec2(floor(uv.x * 700.0), floor(uv.y * 9.0)));
	float chips = step(0.16, h(floor(uv * vec2(260.0, 70.0))) * 0.6 + h(floor(uv * vec2(46.0, 16.0))) * 0.5);
	vec3 metal = vec3(0.66, 0.67, 0.69) * g * (0.82 + 0.3 * sc);
	metal = mix(metal, vec3(0.32, 0.16, 0.1), (1.0 - chips) * 0.8);
	float body = a * mix(0.55, 1.0, chips);
	vec3 col = metal * body + vec3(0.9, 0.1, 0.08) * ar * 0.4 * (1.0 - a) + vec3(0.1, 0.65, 0.85) * ab * 0.4 * (1.0 - a);
	float al = max(body, max(ar, ab) * 0.4);
	col *= 0.9 + 0.1 * sin(uv.y * 320.0 + TIME * 6.0);
	COLOR = vec4(col, al * reveal);
}"""
const FOG_SHADER = """
shader_type canvas_item;
float h(vec2 p){ return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
float n(vec2 p){ vec2 i = floor(p); vec2 f = fract(p); f = f*f*(3.0-2.0*f);
	return mix(mix(h(i), h(i+vec2(1,0)), f.x), mix(h(i+vec2(0,1)), h(i+vec2(1,1)), f.x), f.y); }
void fragment(){
	vec2 p = UV * vec2(3.0, 2.0);
	float f = n(p + vec2(TIME * 0.05, 0.0)) * 0.6 + n(p * 2.3 - vec2(TIME * 0.08, TIME * 0.02)) * 0.4;
	float m = smoothstep(0.9, 0.2, abs(UV.y - 0.55) * 2.0);
	COLOR = vec4(vec3(0.42, 0.46, 0.5) * f * m * 0.22, 1.0);
}"""
