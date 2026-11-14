extends Node
# Top-level flow: boot → opening cinematic → title → main menu → chapters → ending → credits.

const LevelScript = preload("res://scripts/level.gd")
var ui
var level = null
var menu = null
var credits = null

func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	ui = load("res://scripts/ui.gd").new(); add_child(ui)
	ui.connect("menu_action", self, "_on_menu_action")
	randomize()
	if G.test_mode: return
	if "--menu" in OS.get_cmdline_args(): show_menu()
	else: play_intro()

func _clear():
	get_tree().paused = false
	Snd.stop_all_loops()
	if level and is_instance_valid(level):
		level.dead = true; level.queue_free()
	level = null
	if menu and is_instance_valid(menu): menu.queue_free()
	menu = null
	if credits and is_instance_valid(credits): credits.queue_free()
	credits = null
	ui.set_hud(false); ui.set_cine(false); ui.sub.bbcode_text = ""
	if ui.modal != null: ui.close_modal()
	ui.modals = 0

func _load(d: Dictionary):
	_clear()
	ui.fade_rect.color.a = 1.0
	level = LevelScript.new(); level.pause_mode = Node.PAUSE_MODE_STOP; add_child(level)
	level.build(d, self, ui)

func play_intro():
	G.new_run(1); G.has_radio = false
	_load(Story.chapter(0))
	ui.set_cine(true); level.player.locked = true
	level.run(Story.chapter(0).start_ev)

func show_menu():
	_clear()
	G.intro_seen = true; G.save_profile()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	menu = load("res://scripts/menu.gd").new(); add_child(menu)
	menu.setup(self, ui)
	ui.fade(false, 2.0)

func new_game():
	G.new_run(1); G.has_radio = false
	start_chapter(1)

func continue_game():
	if G.load_game(): start_chapter(G.chapter)

func select_chapter(n: int):
	G.new_run(n)
	start_chapter(n)

func start_chapter(n: int):
	G.chapter = n
	var d = Story.chapter(n)
	_load(d)
	ui.set_hud(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var key = "started%d" % n
	if not G.flag(key):
		G.set_flag(key); G.checkpoint = ""; G.health = level.player.health
		G.save_game()
		yield(level.run([["cine", true], ["card"], ["fade", false, 2.0]] + d.get("start_ev", []) + [["cine", false]]), "completed")
	else:
		if ui.objective_text != "": ui.objective(ui.objective_text)
		for e in d.get("resume_ev", []): level._exec(e)
		ui.fade(false, 1.2)

func next_chapter():
	var n = G.chapter + 1
	G.unlock_chapter(n)
	G.checkpoint = ""
	if level and level.player: G.health = max(level.player.health, 40.0)
	G.chapter = n; G.save_game()
	yield(ui.fade(true, 1.5), "completed")
	start_chapter(n)

func on_death():
	ui.set_cine(false)
	Snd.play("glitch", 0); Snd.music("")
	yield(ui.fade(true, 0.8), "completed")
	ui.game_over()

func _on_menu_action(id):
	match id:
		"reload":
			if G.load_game(): start_chapter(G.chapter)
			else: new_game()
		"mainmenu": show_menu()

func play_ending():
	var id = G.ending_id()
	if not id in G.endings: G.endings.append(id)
	G.achieve("end_" + id)
	if G.endings.size() >= 4: G.achieve("all_endings")
	G.save_profile()
	var d = Story.ending(id)
	_load(d)
	ui.set_cine(true); level.player.locked = true
	level.run(d.start_ev)

func play_credits(from_menu := false):
	_clear()
	ui.fade_rect.color.a = 0.0
	credits = load("res://scripts/credits.gd").new(); add_child(credits)
	credits.setup(self, ui)
