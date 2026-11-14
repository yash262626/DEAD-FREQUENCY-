extends Node
# Automated test harness. Run:  DF_TEST=<mode> godot3 tests/Test.tscn   (see tools/test.sh)
const LevelScript = preload("res://scripts/level.gd")
var main
var fails := 0
var checks := 0

func ok(cond: bool, what: String):
	checks += 1
	if not cond:
		fails += 1; print("  FAIL: ", what)

func _ready():
	G.test_mode = true
	G.settings.quality = int(OS.get_environment("DF_Q")) if OS.has_environment("DF_Q") else 0
	main = load("res://scripts/main.gd").new(); add_child(main)
	call_deferred("_go")

func _go():
	var mode = OS.get_environment("DF_TEST")
	print("== TEST ", mode)
	var r = call("t_" + mode)
	if r is GDScriptFunctionState: yield(r, "completed")
	print("== RESULT %s: %d checks, %d failures" % [mode, checks, fails])
	get_tree().quit(1 if fails > 0 else 0)

func frames(n: int):
	for i in n: yield(get_tree(), "physics_frame")

func chapters() -> Array:
	var out = []
	for n in range(0, 14):
		if ResourceLoader.exists("res://data/ch%02d.gd" % n): out.append(n)
	return out

# ------------------------------------------------------------ static data validation
func t_validate():
	for n in chapters():
		var d = Story.chapter(n)
		var errs = LevelScript.validate(d)
		for e in errs: print("  ch%02d: %s" % [n, e])
		ok(errs.size() == 0, "chapter %d data valid" % n)
		var w = d.map[0].length()
		for row in d.map: ok(row.length() == w, "ch%d row width %d != %d: %s" % [n, row.length(), w, row])
	if ResourceLoader.exists("res://data/endings.gd"):
		for id in ["A", "B", "C", "D"]:
			var d = Story.ending(id)
			var errs = LevelScript.validate(d)
			for e in errs: print("  ending %s: %s" % [id, e])
			ok(errs.size() == 0, "ending %s valid" % id)
	ok(Story.CREDITS[5][1] == "YASH AIL", "primary credit")
	var names = []
	for r in Story.CREDITS:
		if r[0] == "name": names.append(r[1])
	ok(names == ["YASH AIL", "AJAY GOHIL", "ADARSH GUPTA", "TANISH SHETTY", "SHUBHAM GAONKAR"], "credit names exact")

# ------------------------------------------------------------ screenshots
func t_shot():
	var n = int(OS.get_environment("DF_CH"))
	G.new_run(n); G.set_flag("started%d" % n)
	if OS.has_environment("DF_POWER"): G.set_flag("power%d" % n)
	main.start_chapter(n)
	yield(frames(5), "completed")
	var lv = main.level
	var at = OS.get_environment("DF_AT")
	if at != "": lv.player.global_transform.origin = lv.pos_of(at) + Vector3(0, 0.1, 0)
	lv.player.rotation_degrees.y = float(OS.get_environment("DF_YAW"))
	if OS.has_environment("DF_LIGHT"): lv.player.light_on = true
	if OS.has_environment("DF_LISTENER"): lv.spawn_listener(OS.get_environment("DF_LISTENER"), "watch")
	if OS.has_environment("DF_RADIO"):
		G.has_radio = true; lv.radio.on = true; lv.radio.f = float(OS.get_environment("DF_RADIO"))
	main.ui.fade_rect.color.a = 0
	yield(frames(40), "completed")
	_save(OS.get_environment("DF_OUT"))

func _save(path: String):
	var img = get_viewport().get_texture().get_data(); img.flip_y()
	img.save_png(path); print("  saved ", path)

# ------------------------------------------------------------ save / load
func t_save():
	G.new_run(1); G.set_flag("alpha"); G.give("fuse", 2); G.add_journal("T", "X"); G.health = 61.0; G.checkpoint = "o"; G.chapter = 3
	ok(G.save_game(), "save written")
	G.new_run(1)
	ok(not G.flag("alpha"), "state cleared")
	ok(G.load_game(), "load ok")
	ok(G.flag("alpha") and G.inv.fuse == 2 and G.journal.size() == 1 and G.health == 61.0 and G.checkpoint == "o" and G.chapter == 3, "state restored")
	# ending logic
	G.new_run(13); ok(G.ending_id() == "C", "default ending C")
	G.set_flag("final_open"); ok(G.ending_id() == "B", "open → B")
	G.new_run(13); G.set_flag("final_silence"); G.set_flag("shutdown_key"); ok(G.ending_id() == "A", "silence+key → A")
	G.new_run(13); G.set_flag("final_silence"); ok(G.ending_id() == "C", "silence without key → C")
	G.new_run(13)
	for f in ["final_send", "trust_mira", "hale_truth", "shutdown_key", "tape_ev1", "tape_ev2", "tape_ev3", "tape_ev4", "tape_ev5"]: G.set_flag(f)
	ok(G.ending_id() == "D", "full knowledge → D")
	G.set_flag("tape_ev5", false); ok(G.ending_id() == "C", "missing tape → not D")
	# checkpoint respawn through the real flow
	G.new_run(1); G.set_flag("started1"); G.set_flag("power1"); G.checkpoint = "o"; G.save_game()
	main.continue_game()
	yield(frames(5), "completed")
	var lv = main.level
	ok(lv != null and (lv.player.global_transform.origin - lv.pos_of("o")).length() < 1.0, "respawn at checkpoint marker")
	ok(lv.power_on, "power state restored from flags")

# ------------------------------------------------------------ player + systems
func t_systems():
	G.new_run(1); G.set_flag("started1"); G.set_flag("power1")
	main.start_chapter(1)
	yield(frames(10), "completed")
	var lv = main.level; var p = lv.player
	for e in lv.ents:
		if e.kind == "trig": e.done = true
	p.global_transform.origin = lv.pos_of("x") + Vector3(0, 0.1, 0); p.rotation_degrees.y = -90
	yield(frames(20), "completed")
	var x0 = p.global_transform.origin.x
	Input.action_press("fwd")
	yield(frames(25), "completed")
	var walked = p.global_transform.origin.x - x0
	ok(walked > 0.5 and abs(p.moving_speed - p.WALK) < 0.3, "walk forward moves player (%.2f m, %.2f m/s)" % [walked, p.moving_speed])
	Input.action_press("sprint")
	var st0 = p.stamina
	yield(frames(25), "completed")
	ok(abs(p.moving_speed - p.SPRINT) < 0.5, "sprint is faster than walk (%.2f m/s)" % p.moving_speed)
	ok(p.stamina < st0, "sprint drains stamina")
	Input.action_release("sprint"); Input.action_release("fwd")
	p.stamina = 1.0; Input.action_press("fwd"); Input.action_press("sprint"); yield(frames(25), "completed")
	ok(p._winded and p.moving_speed < 3.2, "empty stamina forces a walk")
	Input.action_release("sprint"); Input.action_release("fwd"); p.stamina = 100; p._winded = false
	Input.action_press("crouch"); yield(frames(3), "completed"); Input.action_release("crouch")
	yield(frames(30), "completed")
	ok(p.crouching and p.head.translation.y < 1.2, "crouch lowers the camera")
	Input.action_press("crouch"); yield(frames(3), "completed"); Input.action_release("crouch")
	Input.action_press("lean_r"); yield(frames(30), "completed")
	ok(p.head.translation.x > 0.25, "lean shifts the camera"); Input.action_release("lean_r")
	Input.action_press("light"); yield(frames(3), "completed"); Input.action_release("light")
	yield(frames(10), "completed")
	ok(p.light_on and p.lamp.light_energy > 1.0, "flashlight toggles on")
	var b0 = G.battery; yield(frames(30), "completed"); ok(G.battery < b0, "flashlight drains battery")
	G.battery = 0.01; G.give("battery"); yield(frames(10), "completed")
	ok(G.battery > 90 and not G.has("battery"), "spare cell auto-loads")
	# radio
	G.has_radio = true
	Input.action_press("radio"); yield(frames(3), "completed"); Input.action_release("radio")
	ok(lv.radio.on, "radio toggles on")
	lv.radio.f = 94.0
	Input.action_press("tune_up"); yield(frames(2), "completed"); Input.action_release("tune_up"); yield(frames(2), "completed")
	ok(abs(lv.radio.f - 94.1) < 0.01, "dial tunes in 0.1 MHz steps")
	var rb = G.radio_batt; yield(frames(30), "completed"); ok(G.radio_batt < rb, "radio drains its cell")
	lv.radio.f = 107.9; yield(frames(5), "completed"); ok(lv.reveal_on, "107.9 enables reveal")
	lv.radio.f = 94.6; yield(frames(5), "completed"); ok(not lv.reveal_on and lv.radio.band() == 94.6, "94.6 band recognised")
	# transmission lock: stand by the source, face it, tune 89.1
	var src = lv.ent_at("x")
	p.global_transform.origin = src.pos + Vector3(3, 0.1, 0); p.rotation_degrees.y = 90; lv.radio.f = 89.1; G.skip = true
	for i in 200:
		yield(get_tree(), "physics_frame"); G.skip = true
		if src.done: break
	ok(src.done and G.flag("first_signal"), "facing a source on its frequency receives the transmission")
	G.skip = false
	# hiding
	var h = lv.ent_at("H")
	lv.interact(h); yield(frames(3), "completed")
	ok(p.hidden, "locker hides player"); lv.interact(h); yield(frames(3), "completed"); ok(not p.hidden, "leaving locker")
	# items / doors
	var e = lv.ent_at("E")
	ok(not e.open, "door starts closed"); lv.interact(e); yield(frames(90), "completed"); ok(e.open, "powered door opens")
	var c = lv.ent_at("C")
	lv.interact(c); yield(frames(5), "completed"); ok(not c.open, "locked door refuses without key")
	G.give("comms_key"); lv.interact(c); yield(frames(5), "completed"); ok(c.open, "key opens locked door")
	# damage / death
	p.hurt(30); ok(p.health == 70, "damage applies")
	G.give("medkit"); Input.action_press("heal"); yield(frames(3), "completed"); Input.action_release("heal")
	ok(p.health > 99 and not G.has("medkit"), "medkit heals")
	# pause menu + settings
	main.ui.pause_menu(); yield(frames(2), "completed")
	ok(get_tree().paused and main.ui.modal != null, "pause menu pauses")
	main.ui._menu("settings"); yield(frames(2), "completed"); ok(main.ui.modal != null, "settings opens from pause")
	main.ui._set(0.5, "master"); ok(abs(db2linear(AudioServer.get_bus_volume_db(0)) - 0.5) < 0.01, "volume setting applies")
	main.ui._set(1.0, "master"); main.ui._set_close(); yield(frames(2), "completed"); ok(not get_tree().paused, "closing unpauses")
	main.ui.journal_screen(); yield(frames(2), "completed"); ok(main.ui.modal != null, "journal opens"); main.ui.close_modal()
	yield(frames(2), "completed")

# ------------------------------------------------------------ listener AI
func t_ai():
	G.new_run(1); G.set_flag("started1"); G.set_flag("power1")
	main.start_chapter(1)
	yield(frames(10), "completed")
	Engine.time_scale = 4.0
	var lv = main.level; var p = lv.player
	lv.interact(lv.ent_at("E")); lv._door_open(lv.ent_at("K"))
	p.global_transform.origin = lv.pos_of("x") + Vector3(0, 0.1, 0)
	lv.spawn_listener("2", "dormant")
	var L = lv.listener
	yield(frames(30), "completed")
	ok(L.st == L.S.DORMANT, "starts dormant")
	lv.noise(lv.pos_of("S"), 5.0, "step")
	yield(frames(5), "completed")
	ok(L.st == L.S.DORMANT, "ignores noise beyond its hearing radius")
	lv.noise(lv.pos_of("y"), 14.0, "object")
	yield(frames(5), "completed")
	ok(L.st == L.S.INVESTIGATE, "loud noise in range → INVESTIGATE (%s)" % L.NAMES[L.st])
	for i in 400:
		yield(get_tree(), "physics_frame")
		if L.st == L.S.SEARCH: break
	ok(L.st == L.S.SEARCH, "arrives and begins SEARCH (%s)" % L.NAMES[L.st])
	ok((L.global_transform.origin - p.global_transform.origin).length() > 8.0, "did not home in on the silent player")
	# sight: put the player in front of it with the flashlight on
	L.command("patrol"); L.route = []; L.alert = 0
	L.global_transform.origin = lv.pos_of("y"); L.rotation.y = PI / 2     # facing -x (west)
	p.global_transform.origin = lv.pos_of("y") + Vector3(-7, 0.1, 0); p.light_on = true
	var hunted = false
	for i in 300:
		yield(get_tree(), "physics_frame")
		L.rotation.y = PI / 2 if L.st != L.S.HUNT else L.rotation.y
		if L.st == L.S.HUNT:
			hunted = true; break
	ok(hunted, "sustained line of sight escalates to HUNT (%s, alert %.2f)" % [L.NAMES[L.st], L.alert])
	ok("STALK" in L.trace or L.alert >= 1.0, "alert builds over time rather than instantly")
	# break line of sight and stay silent → it must lose the player
	p.global_transform.origin = lv.pos_of("j") + Vector3(0, 0.1, 0); p.light_on = false
	var lost = false
	for i in 900:
		yield(get_tree(), "physics_frame")
		if L.st == L.S.SEARCH or L.st == L.S.PATROL or L.st == L.S.STALK:
			lost = true; break
	ok(lost, "loses a player it can no longer see or hear (%s)" % L.NAMES[L.st])
	# attack → retreat (non-lethal first hit)
	p.health = 100.0; p._hurt_cd = 0
	p.global_transform.origin = L.global_transform.origin + Vector3(0.8, 0.1, 0)
	L.command("hunt")
	for i in 120:
		yield(get_tree(), "physics_frame")
		if L.st == L.S.RETREAT: break
	ok(L.st == L.S.RETREAT and p.health < 100 and p.health > 0, "catch wounds, then it retreats (hp %.0f)" % p.health)
	# learning: a locker used repeatedly is checked more often
	var h = lv.ent_at("H")
	G.flags["m_hide_" + h.uid] = 5
	L.last_known = h.pos; var picks = 0
	for i in 200:
		L._next_search()
		if L._check_hide != null: picks += 1
	ok(picks > 60, "habitual hiding spots get searched (%d/200)" % picks)
	G.flags["m_hide_" + h.uid] = 0
	for e in lv.ents:
		if e.kind == "hide": G.flags["m_hide_" + e.uid] = 0
	picks = 0
	for i in 200:
		L._next_search()
		if L._check_hide != null: picks += 1
	ok(picks < 60, "fresh hiding spots are mostly safe (%d/200)" % picks)
	ok(L.hear_mult("radio") >= 1.0 and L.hear_mult("radio") <= 1.5, "radio learning is bounded")
	Engine.time_scale = 1.0
