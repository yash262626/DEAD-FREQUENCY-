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
		# Detach now, free later: event scripts suspended on UI coroutines (dialogue, waits) can then
		# resume, see the level is dead and exit cleanly instead of resuming into a freed instance.
		level.dead = true
		remove_child(level)
		_bury(level)
	level = null
	if menu and is_instance_valid(menu): menu.queue_free()
	menu = null
	if credits and is_instance_valid(credits): credits.queue_free()
	credits = null
	ui.set_hud(false); ui.set_cine(false); ui.sub.bbcode_text = ""
	if ui.modal != null: ui.close_modal()
	ui.modals = 0

var _graves := []
func _bury(n):
	_graves.append(n)
	yield(get_tree().create_timer(45.0), "timeout")
	_graves.erase(n)
	if is_instance_valid(n): n.free()

func _exit_tree():
	for n in _graves:
		if is_instance_valid(n): n.free()
	_graves.clear()

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
	if G.load_game():
		start_chapter(G.chapter)
		if G.load_error != "": ui.toast(G.load_error)
	else:
		ui.toast(G.load_error if G.load_error != "" else "No saved game found.")
		ui.fade(false, 0.5)

func new_game_plus():
	G.new_run_plus(); G.has_radio = false
	start_chapter(1)

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
		G.flags["hunts_start"] = int(G.flags.get("m_hunts", 0))
		yield(level.run([["cine", true]] + d.get("pre_ev", []) + [["card"], ["fade", false, 2.0]] + d.get("start_ev", []) + [["cine", false]]), "completed")
	else:
		if ui.objective_text != "": ui.objective(ui.objective_text)
		for e in d.get("resume_ev", []): level._exec(e)
		ui.fade(false, 1.2)

func next_chapter():
	var n = G.chapter + 1
	if G.chapter >= 2 and int(G.flags.get("m_hunts", 0)) == int(G.flags.get("hunts_start", -1)): G.achieve("no_hunt")
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
			if G.load_game():
				start_chapter(G.chapter)
				if G.load_error != "": ui.toast(G.load_error)
			else:
				show_menu()
				ui.toast(G.load_error if G.load_error != "" else "No checkpoint to return to.")
		"mainmenu": show_menu()

func play_ending():
	var id = G.ending_id()
	if not id in G.endings: G.endings.append(id)
	G.achieve("end_" + id)
	if G.endings.size() >= 4: G.achieve("all_endings")
	if G.flag("ngp"): G.achieve("second_signal")
	G.snapshot_memory()
	var d = Story.ending(id)
	_load(d)
	ui.set_cine(true); level.player.locked = true
	level.run(d.start_ev)

func play_credits(from_menu := false):
	_clear()
	ui.fade_rect.color.a = 0.0
	credits = load("res://scripts/credits.gd").new(); add_child(credits)
	credits.setup(self, ui)
