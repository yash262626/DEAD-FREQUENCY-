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
	if "--smoketest" in OS.get_cmdline_args():
		_smoketest()
		return
	if "--menu" in OS.get_cmdline_args(): show_menu()
	else: play_intro()

# ---------------------------------------------------------------- built-in smoke test for release builds
# Usage:  DeadFrequency.exe --smoketest
# Writes user://smoketest.log and user://smoke_*.png, then quits (exit code 0 = all passed).
var _smoke_log := []
var _smoke_fail := 0
func _smoke(ok_: bool, what: String):
	_smoke_log.append(("PASS  " if ok_ else "FAIL  ") + what)
	if not ok_: _smoke_fail += 1
	print(_smoke_log[-1])

func _smoke_wait(sec: float):
	yield(get_tree().create_timer(sec), "timeout")

func _smoke_shot(name: String):
	yield(get_tree(), "idle_frame"); yield(get_tree(), "idle_frame")
	var img = get_viewport().get_texture().get_data(); img.flip_y()
	var path = "user://smoke_%s.png" % name
	_smoke(img.save_png(path) == OK, "screenshot " + path)

func _smoketest():
	var t0 = OS.get_ticks_msec()
	G.STATS = "user://smoke_playtest.json"     # keep the player's own play-time log untouched
	_smoke_log.append("DEAD FREQUENCY smoke test — %s — %s — video adapter: %s" % [OS.get_name(), Engine.get_version_info().string, VisualServer.get_video_adapter_name()])
	_smoke(Snd.bank.size() >= 39, "procedural audio bank built (%d sounds)" % Snd.bank.size())
	show_menu()
	yield(_smoke_wait(3.0), "completed")
	_smoke(menu != null and is_instance_valid(menu), "main menu shown")
	yield(_smoke_shot("menu"), "completed")
	new_game()
	yield(_smoke_wait(1.0), "completed")
	_smoke(level != null and level.data.n == 1, "new game loads chapter 1")
	for i in 600:
		yield(get_tree(), "idle_frame"); G.skip = true
		if level.running == 0: break
	G.skip = false
	ui.fade_rect.color.a = 0
	level.player.light_on = true
	G.has_radio = true; level.radio.on = true; level.radio.f = 89.1
	yield(_smoke_wait(4.0), "completed")
	_smoke(level.player.lamp.light_energy > 1.0, "flashlight on")
	_smoke(level.radio.on and G.radio_batt < 100.0, "radio on and draining")
	yield(_smoke_shot("chapter01"), "completed")
	var f0 = Engine.get_frames_drawn(); var t1 = OS.get_ticks_msec()
	yield(_smoke_wait(5.0), "completed")
	var fps = (Engine.get_frames_drawn() - f0) * 1000.0 / max(1, OS.get_ticks_msec() - t1)
	_smoke(fps > 1.0, "rendering: %.1f fps average over 5 s at %s, preset %d" % [fps, str(OS.window_size), int(G.settings.quality)])
	_smoke(G.save_game() and G.load_game(), "save and load round-trip")
	for n in [5, 12]:
		select_chapter(n)
		yield(_smoke_wait(2.0), "completed")
		for i in 600:
			yield(get_tree(), "idle_frame"); G.skip = true
			if level.running == 0: break
		G.skip = false; ui.fade_rect.color.a = 0
		yield(_smoke_wait(2.0), "completed")
		_smoke(level != null and level.data.n == n, "chapter %d loads and runs" % n)
		yield(_smoke_shot("chapter%02d" % n), "completed")
	G.new_run(13); G.set_flag("final_silence"); G.set_flag("shutdown_key")
	play_ending()
	for i in 6000:
		yield(get_tree(), "idle_frame"); G.skip = true
		if credits != null and is_instance_valid(credits): break
	_smoke(credits != null and is_instance_valid(credits), "ending A plays through to the credits")
	yield(_smoke_wait(1.0), "completed")
	yield(_smoke_shot("credits"), "completed")
	_smoke_log.append("RESULT: %d failures, %.1f s" % [_smoke_fail, (OS.get_ticks_msec() - t0) / 1000.0])
	var f = File.new()
	if f.open("user://smoketest.log", File.WRITE) == OK:
		f.store_string(PoolStringArray(_smoke_log).join("\n") + "\n"); f.close()
	print(_smoke_log[-1])
	print("log: ", ProjectSettings.globalize_path("user://smoketest.log"))
	get_tree().quit(1 if _smoke_fail > 0 else 0)

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

# ---------------------------------------------------------------- play-time log, focus loss, quit
func _process(dt):
	if level and is_instance_valid(level) and not level.dead and ui.hud_on and not get_tree().paused:
		G.stats_tick(dt)

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		G.stats_flush()
	elif what == MainLoop.NOTIFICATION_WM_FOCUS_OUT:
		# alt-tab / another window: never leave the player exposed to the Listener while they are away
		if G.test_mode or "--smoketest" in OS.get_cmdline_args(): return
		focus_lost()

func focus_lost():
	if level and is_instance_valid(level) and not level.dead and ui.hud_on and not ui.in_cine and ui.modal == null:
		ui.pause_menu()

func show_menu():
	G.stats_flush()
	_clear()
	G.intro_seen = true; G.save_profile()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	menu = load("res://scripts/menu.gd").new(); add_child(menu)
	menu.setup(self, ui)
	ui.fade(false, 2.0)

func new_game():
	G.new_run(1); G.has_radio = false
	G.stats_begin("new")
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
	G.stats_begin("ngplus")
	start_chapter(1)

func select_chapter(n: int):
	G.new_run(n)
	G.stats_begin("chapter_%02d" % n)
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
	G.stats_event("done")
	G.checkpoint = ""
	if level and level.player: G.health = max(level.player.health, 40.0)
	G.chapter = n; G.save_game()
	yield(ui.fade(true, 1.5), "completed")
	start_chapter(n)

func on_death():
	G.stats_event("death")
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
	G.stats_event("done"); G.stats_event("ending", id)
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
