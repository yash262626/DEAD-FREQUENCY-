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
	if OS.has_environment("DF_PRESET"): G.apply_preset(int(OS.get_environment("DF_PRESET")))   # every quality item of the preset
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
	# local play-time log: survives save/load, records time, deaths, completion and the ending per run
	G.new_run(1); G.stats_begin("new"); G.chapter = 3
	G.stats_tick(12.5); G.stats_event("death"); G.stats_event("done")
	var rid = G.run_id
	ok(G.save_game(), "save with play-time run id")
	G.run_id = "other"; ok(G.load_game() and G.run_id == rid, "load restores the play-time run id")
	G.stats_tick(2.0); G.stats_event("ending", "D")
	var pf = File.new(); pf.open(G.STATS, File.READ); var st = parse_json(pf.get_as_text()); pf.close()
	ok(typeof(st) == TYPE_DICTIONARY and st.has(rid) and st[rid].mode == "new", "play-time log written (user://test_playtest.json)")
	ok(abs(float(st[rid].ch["3"].t) - 14.5) < 0.01 and int(st[rid].ch["3"].deaths) == 1 and st[rid].ch["3"].done and st[rid].ending == "D", "per-chapter seconds, deaths, completion and ending recorded")
	ok(abs(G.run_seconds() - 14.5) < 0.01, "run time available to the pause menu")
	# corrupted saves: fall back to the previous good save, never crash, never load garbage
	G.new_run(4); G.set_flag("good_a"); G.chapter = 4; ok(G.save_game(), "first save")
	G.set_flag("good_b"); G.chapter = 5; ok(G.save_game(), "second save (first becomes .bak)")
	var sf = File.new(); sf.open(G.SAVE, File.WRITE); sf.store_string("{\"v\": 1, \"flags\": [garbage"); sf.close()
	G.new_run(1)
	ok(G.load_game() and G.chapter == 4 and G.flag("good_a") and not G.flag("good_b") and G.load_error != "", "damaged save falls back to the previous checkpoint")
	sf.open(G.SAVE + ".bak", File.WRITE); sf.store_string("not json at all"); sf.close()
	sf.open(G.SAVE, File.WRITE); sf.store_string("{\"v\": 1, \"chapter\": 99, \"flags\": {}}"); sf.close()
	G.new_run(1)
	ok(not G.load_game() and G.load_error != "", "two damaged saves: refuses to load and reports it")
	ok(G.save_game() and G.load_game() and G.load_error == "", "a fresh save after damage loads cleanly")
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
	p.global_transform.origin = lv.pos_of("1") + Vector3(0, 0.1, 0); p.rotation_degrees.y = -90
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
	# a tap lasts exactly one rendered frame: held across a slow frame (a loaded machine), the 0.35 s auto-repeat would fire
	Input.action_press("tune_up"); yield(get_tree(), "idle_frame"); yield(get_tree(), "idle_frame"); Input.action_release("tune_up"); yield(frames(2), "completed")
	ok(abs(lv.radio.f - 94.1) < 0.01, "dial tunes in 0.1 MHz steps (%.1f)" % lv.radio.f)
	var rb = G.radio_batt; yield(frames(30), "completed"); ok(G.radio_batt < rb, "radio drains its cell")
	lv.radio.f = 107.9; yield(frames(5), "completed"); ok(lv.reveal_on, "107.9 enables reveal")
	lv.radio.f = 92.5; lv.radio.force(true, 96.1); yield(frames(2), "completed"); lv.radio.force(false)
	ok(lv.radio.on and abs(lv.radio.f - 92.5) < 0.01, "a scripted transmission hands the receiver back as the player left it")
	lv.radio.f = 94.6; yield(frames(5), "completed"); ok(not lv.reveal_on and lv.radio.band() == 94.6, "94.6 band recognised")
	# transmission lock: stand by the source, face it, tune 89.1
	var src = lv.ent_at("x")
	p.global_transform.origin = src.pos + Vector3(-2, 0.1, 0); p.rotation_degrees.y = -90; lv.radio.f = 89.1; G.skip = true
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

# ------------------------------------------------------------ cross-chapter flag + layout validation
const NONSOLID = ["paper", "debris", "coat", "figure", "shade", "lamp", "board", "vent", "pipes", "glass"]
const AUTO_FLAGS = ["cs_run", "radio_tut", "m_radio", "m_hunts", "m_unseen", "hunts_start", "ngp", "mem_end_A", "mem_end_B", "mem_end_C", "mem_end_D", "mem_bottles", "mem_sprint"]

func _walk_ev(evs, sets: Dictionary, refs: Array, where: String):
	for e in evs:
		if typeof(e) != TYPE_ARRAY or e.size() == 0: continue
		var c = str(e[0])
		match c:
			"flag": sets[e[1]] = true
			"if", "ifnot":
				refs.append([e[1], where]); _walk_ev(e[2], sets, refs, where)
				if e.size() > 3: _walk_ev(e[3], sets, refs, where)
			"choice":
				for o in e[2]: _walk_ev(o[1], sets, refs, where)

func _uids(d: Dictionary) -> Array:
	var out = []; var counts = {}
	for row in d.map:
		for ch in row:
			if ch in ["#", " ", "."]: continue
			if LevelScript.legend_of(d, ch) == null: continue
			counts[ch] = counts.get(ch, 0) + 1
			out.append("c%d_%s%d" % [d.n, ch, counts[ch]])
	return out

func _all_data() -> Array:
	var all = []
	for n in chapters(): all.append(Story.chapter(n))
	if ResourceLoader.exists("res://data/endings.gd"):
		for id in ["A", "B", "C", "D"]: all.append(Story.ending(id))
	return all

func t_flags():
	var sets = {}; var refs = []
	for f in AUTO_FLAGS: sets[f] = true
	for d in _all_data():
		var where = "ch%02d" % d.n
		sets["power%d" % d.n] = true
		for u in _uids(d):
			sets["u:" + u] = true; sets["o:" + u] = true; sets["e:" + u] = true
		for n in range(0, 15): sets["started%d" % n] = true
		for g in d.get("groups", {}): sets["solved_" + g] = true
		for ch in d.leg:
			var l = d.leg[ch]
			if l.has("flag"): sets[l.flag] = true
			for k in ["if", "ifnot", "needflag", "hidden"]:
				if l.has(k): refs.append([l[k], where + " '" + ch + "'"])
			for k in ["ev", "lines"]:
				if l.has(k): _walk_ev(l[k], sets, refs, where + " '" + ch + "'")
		for k in ["start_ev", "pre_ev", "resume_ev"]: _walk_ev(d.get(k, []), sets, refs, where + " " + k)
		for g in d.get("groups", {}): _walk_ev(d.groups[g], sets, refs, where + " group " + g)
		for s in d.get("ai", []):
			for k in ["if", "ifnot"]:
				if s.has(k): refs.append([s[k], where + " ai"])
	for r in refs:
		ok(sets.has(r[0]), "flag '%s' referenced in %s is never set anywhere" % r)
	# every story flag the ending logic reads must be settable somewhere
	for f in ["final_open", "final_send", "final_silence", "trust_mira", "hale_truth", "shutdown_key"]:
		ok(sets.has(f), "ending flag '%s' is never set" % f)
	var tapes = 0
	for f in sets:
		if str(f).begins_with("tape_ev"): tapes += 1
	ok(tapes >= 7, "seven Evelyn tapes exist (%d)" % tapes)

func _bfs(d: Dictionary, blocked: Dictionary) -> Dictionary:
	var grid = d.map; var seen = {}; var q = []
	for z in grid.size():
		var x = grid[z].find("S")
		if x >= 0: q.append(Vector2(x, z))
	while q.size():
		var c = q.pop_back()
		if seen.has(c): continue
		seen[c] = true
		for o in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
			var nb = c + o
			if nb.y < 0 or nb.y >= grid.size() or nb.x < 0 or nb.x >= grid[nb.y].length(): continue
			var ch = grid[nb.y][nb.x]
			if ch == "#" or ch == " " or blocked.has(nb) or seen.has(nb): continue
			q.append(nb)
	return seen

func t_layout():
	for d in _all_data():
		var solid = {}
		for z in d.map.size():
			for x in d.map[z].length():
				var l = LevelScript.legend_of(d, d.map[z][x])
				if l == null: continue
				var t = l.t
				if t in ["use", "save", "hide", "note", "tape", "item"] or l.get("block", false) or (t == "prop" and not l.p in NONSOLID):
					solid[Vector2(x, z)] = d.map[z][x]
		var before = _bfs(d, {}); var after = _bfs(d, solid)
		var cut = []
		for c in before:
			if not solid.has(c) and not after.has(c): cut.append(c)
		ok(cut.size() == 0, "%s: props cut off %d floor cells (first %s)" % [d.title, cut.size(), str(cut.slice(0, 2))])

# ------------------------------------------------------------ automated critical-path playthrough
func _ent(lv, key: String):
	var ch = key; var idx = 0
	if "#" in key:
		ch = key.split("#")[0]; idx = int(key.split("#")[1]) - 1
	var l = lv.by_char.get(ch, [])
	return l[idx] if idx < l.size() else null

func _reach(lv, from: Vector3, to: Vector3) -> bool:
	var p = lv.path(from, to)
	return p.size() > 0 and lv.cell_of(p[p.size() - 1]) == lv.cell_of(to)

func _settle(lv):
	for i in 2000:
		yield(get_tree(), "physics_frame")
		G.skip = true
		if not is_instance_valid(lv) or (lv.running == 0 and main.ui.modal == null): break
	yield(frames(6), "completed")

func _play_chapter(n: int):
	var lv = main.level
	var d = lv.data
	var steps = d.get("walk", [])
	ok(steps.size() > 0, "ch%02d has a walkthrough" % n)
	yield(_settle(lv), "completed")
	for s in steps:
		if not is_instance_valid(lv) or main.level != lv: break
		var kind = "go"; var key = s
		if typeof(s) == TYPE_ARRAY:
			kind = s[0]; key = s[1] if s.size() > 1 else ""
		# NB: GDScript 3 'continue' inside 'match' falls through to the next pattern, so use if/elif here
		if kind == "choice":
			G.flags["_test_choice"] = int(key)
			continue
		elif kind == "wait":
			yield(frames(int(float(key) * 60)), "completed")
			continue
		elif kind == "crate":
			var c = _ent(lv, key); var pl = _ent(lv, s[2])
			ok(_reach(lv, c.pos, pl.pos), "ch%02d: crate %s can be pushed to plate %s" % [n, key, s[2]])
			c.node.global_transform.origin = pl.pos + Vector3(0, 0.6, 0); c.node.linear_velocity = Vector3()
			yield(_settle(lv), "completed")
			ok(G.flag(pl.d.get("flag", "")) or pl.done, "ch%02d: plate %s pressed" % [n, s[2]])
			continue
		var e = _ent(lv, key)
		if e == null and G.flag("cs_run"):
			continue   # earned content (only_if) can't exist in a mid-campaign start
		if e == null:
			ok(false, "ch%02d: walkthrough step '%s' has no entity" % [n, key]); continue
		var pp = lv.player.global_transform.origin
		var target = e.pos
		var reach = _reach(lv, pp, target)
		if not reach and (e.kind == "door" or e.d.get("block", false)):
			for o in [Vector3(2, 0, 0), Vector3(-2, 0, 0), Vector3(0, 0, 2), Vector3(0, 0, -2)]:
				var c = lv.cell_of(target + o)
				if lv.is_floor(int(c.x), int(c.y)) and _reach(lv, pp, target + o):
					reach = true; target = target + o; break
		ok(reach, "ch%02d: step '%s' reachable from %s" % [n, key, str(lv.cell_of(pp))])
		if kind == "radio" and not lv._cond(e.d):
			# gated on earlier chapters: only a chapter-select (mid-campaign) start may lack it
			ok(G.flag("cs_run"), "ch%02d: transmission '%s' is unlocked by earlier play" % [n, key])
			continue
		if kind == "radio":
			lv.player.global_transform.origin = target + Vector3(0, 0.1, 0)
			lv.radio.on = true; lv.radio.f = e.d.f; G.has_radio = true; G.radio_batt = 100
			for i in 600:
				yield(get_tree(), "physics_frame"); G.skip = true
				if e.done: break
			ok(e.done, "ch%02d: transmission '%s' received" % [n, key])
			lv.radio.on = false
		else:
			lv.player.global_transform.origin = (target if (e.kind == "door" or e.d.get("block", false)) else e.pos) + Vector3(0, 0.1, 0)
			if e.kind != "trig" and e.kind != "mark":
				yield(frames(2), "completed")
				lv.interact(e)
		yield(_settle(lv), "completed")
	ok(main.level != lv or G.chapter != n, "ch%02d completes (chapter now %d)" % [n, G.chapter])

func t_play():
	G.test_god = true
	var from = int(OS.get_environment("DF_FROM")) if OS.has_environment("DF_FROM") else 1
	var to = int(OS.get_environment("DF_TO")) if OS.has_environment("DF_TO") else 13
	G.new_run(from); G.has_radio = from > 1
	G.flags["_test_choice"] = int(OS.get_environment("DF_CHOICE")) if OS.has_environment("DF_CHOICE") else 0
	main.start_chapter(from)
	for n in range(from, to + 1):
		var t0 = OS.get_ticks_msec()
		yield(frames(10), "completed")
		if main.level == null or G.chapter != n:
			ok(false, "chapter %d did not load" % n); break
		yield(_play_chapter(n), "completed")
		for i in 600:
			yield(get_tree(), "idle_frame"); G.skip = true
			if main.level and is_instance_valid(main.level) and main.level.player and main.level.data.n != n: break
		print("  ch%02d played in %.1fs, flags=%d, journal=%d" % [n, (OS.get_ticks_msec() - t0) / 1000.0, G.flags.size(), G.journal.size()])
	if to == 13:
		var reached = false
		for i in 4000:
			yield(get_tree(), "physics_frame"); G.skip = true
			if main.credits != null and is_instance_valid(main.credits):
				reached = true; break
		ok(reached, "full run reaches an ending and the credits")
		print("  endings unlocked: ", G.endings, "  tapes: ", G.count("tape_ev"), "  achievements: ", G.achievements)
		if from == 1: ok("D" in G.endings, "the complete walkthrough (all discoveries, trusted Mira, answered) earns ending D")

# ------------------------------------------------------------ endings: each flag combination reaches its ending + credits
func t_endings():
	G.test_god = true
	var cases = [
		["B", 0, []],
		["A", 1, ["shutdown_key"]],
		["C", 1, []],
		["C", 2, ["trust_mira", "shutdown_key"]],
		["D", 2, ["trust_mira", "hale_truth", "shutdown_key", "tape_ev1", "tape_ev2", "tape_ev3", "tape_ev4", "tape_ev5"]],
	]
	for c in cases:
		G.new_run(13); G.has_radio = true
		for f in c[2]: G.set_flag(f)
		G.flags["_test_choice"] = c[1]
		G.endings = []
		main.start_chapter(13)
		var lv = main.level
		for i in 600:
			yield(get_tree(), "physics_frame"); G.skip = true
			if lv.running == 0: break
		lv.interact(lv.ent_at("U"))
		var reached = false
		for i in 4000:
			yield(get_tree(), "physics_frame"); G.skip = true
			if main.credits != null and is_instance_valid(main.credits):
				reached = true; break
		ok(reached, "ending %s reaches the credits" % c[0])
		ok(c[0] in G.endings, "choice %d with %s → ending %s (got %s)" % [c[1], str(c[2]), c[0], str(G.endings)])
		# credits must show the owner-specified names
		if reached:
			var txt = ""
			for l in main.credits.scroll.get_children():
				if l is Label: txt += l.text + "|"
			ok("YASH AIL" in txt and "AJAY GOHIL" in txt and "ADARSH GUPTA" in txt and "TANISH SHETTY" in txt and "SHUBHAM GAONKAR" in txt, "credits list every contributor")
			ok("A game developed by YASH AIL" in txt and "THE SIGNAL NEVER ENDS." in txt, "final title card text")
			for i in 3000:
				yield(get_tree(), "physics_frame")
				if main.credits.done: break
			ok(main.credits.done, "credits finish and offer return to menu")
		main.show_menu()
		yield(frames(5), "completed")
	ok(G.endings.size() >= 1, "ending completion saved to profile")

# ------------------------------------------------------------ boot flow: intro → title → menu → new game → pause → menu → continue / chapter select
func t_flow():
	G.test_mode = true
	main.play_intro()
	var menu_up = false
	for i in 3000:
		yield(get_tree(), "physics_frame"); G.skip = true
		if main.menu != null and is_instance_valid(main.menu):
			menu_up = true; break
	ok(menu_up, "opening cinematic plays through to the main menu")
	ok(G.intro_seen, "intro marked as seen")
	G.skip = false
	var labels = []
	for b in main.menu.list.get_children(): labels.append(b.text)
	ok(labels == ["NEW GAME", "CONTINUE", "CHAPTER SELECTION", "VERTICAL SLICE  —  VISUAL TARGET", "SETTINGS", "CREDITS", "EXIT GAME"], "menu items %s" % str(labels))
	ok(main.menu.list.get_child(1).disabled, "CONTINUE disabled without a save")
	ok(main.menu.list.get_child(2).disabled, "CHAPTER SELECTION locked at first launch")
	main.new_game()
	yield(frames(5), "completed")
	ok(main.level != null and main.level.data.n == 1 and G.has_save(), "new game starts chapter 1 and writes a save")
	for i in 3000:
		yield(get_tree(), "physics_frame"); G.skip = true
		if main.level.running == 0: break
	G.skip = false
	main.focus_lost(); yield(frames(2), "completed")
	ok(main.ui.modal != null and get_tree().paused, "losing window focus during play opens the pause menu")
	main.ui.close_modal(); yield(frames(2), "completed")
	main.ui.set_cine(true); main.focus_lost(); yield(frames(2), "completed")
	ok(main.ui.modal == null, "but not during a cinematic")
	main.ui.set_cine(false)
	main.ui.pause_menu(); yield(frames(2), "completed")
	main.ui._menu("mainmenu"); yield(frames(5), "completed")
	ok(main.menu != null and main.level == null, "pause → main menu returns to the menu")
	ok(not main.menu.list.get_child(1).disabled, "CONTINUE enabled once a save exists")
	main.continue_game(); yield(frames(5), "completed")
	ok(main.level != null and main.level.data.n == 1, "continue resumes chapter 1")
	G.unlock_chapter(5); main.show_menu(); yield(frames(3), "completed")
	main.menu._act("chapters"); yield(frames(3), "completed")
	var enabled = 0
	for b in main.menu.list.get_children():
		if not b.disabled: enabled += 1
	ok(enabled == 6, "chapter select shows 5 unlocked chapters + back (%d)" % enabled)
	main.select_chapter(5); yield(frames(5), "completed")
	ok(main.level.data.n == 5 and G.has_radio, "chapter select starts chapter 5 with the receiver")
	# death → game over → reload checkpoint
	for i in 3000:
		yield(get_tree(), "physics_frame"); G.skip = true
		if main.level.running == 0: break
	G.skip = false
	main.level.player.hurt(500)
	yield(frames(90), "completed")
	ok(main.ui.modal != null and main.level.dead, "death shows the game-over screen")
	main.ui._menu("reload"); yield(frames(5), "completed")
	ok(main.level != null and not main.level.dead and main.level.data.n == 5, "reload checkpoint restores the chapter")

# ------------------------------------------------------------ gallery: renders key shots for visual QA / store screenshots
const SHOTS = [
	# [file, chapter, marker, yaw, pitch, power, light, listener_marker, radio_freq]
	["01_entrance", 1, "1", -90, 0, true, true, "2", 0.0],
	["02_silent_wing", 2, "1", 90, 5, true, false, "z", 0.0],
	["03_medical", 3, "w", -90, 0, true, false, "", 0.0],
	["04_quarters", 4, "f", 0, -5, true, false, "", 0.0],
	["05_power", 5, "w", 90, 12, true, false, "g", 0.0],
	["06_flood", 6, "m", 180, 0, true, true, "P", 94.6],
	["07_signal_room", 7, "x", 0, -8, true, false, "", 0.0],
	["08_labs", 8, "1", 90, 0, true, false, "", 101.3],
	["09_transport", 9, "R", -90, 0, true, false, "", 0.0],
	["10_containment", 10, "U", -90, 3, true, true, "x", 107.9],
	["11_archive", 11, "Z", -90, 0, true, true, "P", 0.0],
	["12_ring", 12, "f", 0, 8, true, false, "x", 0.0],
	["13_the_door", 13, "U", 0, 14, true, false, "x", 0.0],
]

func t_gallery():
	G.test_god = true
	var out = OS.get_environment("DF_OUT")
	var only = OS.get_environment("DF_ONLY")
	for s in SHOTS:
		if only != "" and not s[0].begins_with(only): continue
		G.new_run(s[1]); G.set_flag("started%d" % s[1]); G.has_radio = true
		if s[5]: G.set_flag("power%d" % s[1])
		main.start_chapter(s[1])
		yield(frames(4), "completed")
		var lv = main.level
		main.ui.objective_text = ""; main.ui.obj_lbl.modulate.a = 0
		lv.player.global_transform.origin = lv.pos_of(s[2]) + Vector3(0, 0.1, 0)
		lv.player.rotation_degrees.y = s[3]; lv.player.pitch = deg2rad(s[4])
		lv.player.light_on = s[6]
		if s[7] != "":
			lv.spawn_listener(s[7], "watch"); lv.listener.command("face")
		if s[8] > 0:
			lv.radio.on = true; lv.radio.f = s[8]
		main.ui.fade_rect.color.a = 0
		yield(frames(45), "completed")
		_save("%s/%s.png" % [out, s[0]])
	if only == "" or only == "menu":
		main.show_menu(); yield(frames(5), "completed"); main.ui.fade_rect.color.a = 0
		yield(frames(60), "completed"); _save(out + "/00_menu.png")
	if only == "" or only == "title":
		main._clear(); main.ui.fade_rect.color.a = 0
		main.ui.title_reveal("HELIX-9 HAS BEEN SILENT FOR TWENTY-EIGHT YEARS")
		yield(frames(150), "completed"); _save(out + "/00_title.png")
		yield(frames(400), "completed")
	if only == "" or only == "card":
		main._clear(); main.ui.fade_rect.color.a = 0
		main.ui.chapter_card(2, "THE SILENT WING", "SUBLEVEL 1 — ADMINISTRATION")
		yield(frames(120), "completed"); _save(out + "/00_card.png")
		yield(frames(400), "completed")
	if only == "" or only == "monitor":
		main._clear(); main.ui.fade_rect.color.a = 0
		main.ui.monitor(["SIGNAL IDENTIFIED", "SUBJECT: DANIEL ARLEN", "STATUS: ALREADY INSIDE"], 2.2)
		yield(frames(400), "completed"); _save(out + "/00_second_reveal.png")
		yield(frames(300), "completed")
	if only == "" or only == "ui":
		G.new_run(3); G.set_flag("started3"); G.set_flag("power3"); main.start_chapter(3)
		yield(frames(10), "completed"); main.ui.fade_rect.color.a = 0
		main.ui.objective("Find a way into the lower wards.")
		main.ui.pause_menu(); yield(frames(20), "completed"); _save(out + "/98_pause.png")
		main.ui.close_modal(); main.ui.settings_menu(); yield(frames(20), "completed"); _save(out + "/98_settings.png")
		main.ui.close_modal(); main.ui.game_over(); yield(frames(30), "completed"); _save(out + "/98_game_over.png")
		main.ui.close_modal()
	if only == "" or only == "credits":
		G.test_mode = false
		main.play_credits(); yield(frames(5), "completed")
		main.credits.scroll.rect_position.y = 150
		yield(frames(10), "completed"); _save(out + "/99_credits.png")
		main.credits.scroll.rect_position.y = 520 - main.credits.scroll.rect_size.y + 40
		yield(frames(10), "completed"); _save(out + "/99_credits_end.png")

# ------------------------------------------------------------ the vertical slice: data, art, gameplay loop
func _slice_ready():
	main.start_slice()
	for i in 3000:
		yield(get_tree(), "physics_frame"); G.skip = true
		if main.level and main.level.running == 0: break
	G.skip = false
	main.ui.fade_rect.color.a = 0

func t_slice():
	var d = Story.slice()
	var errs = LevelScript.validate(d)
	ok(errs.empty(), "slice data valid %s" % str(errs))
	yield(_slice_ready(), "completed")
	var lv = main.level
	ok(lv.art != null and lv.env == lv.art.get_node("Env").environment, "authored art scene and its environment loaded")
	ok(lv.art.get_node("Lightmap").light_data != null, "baked lightmap present")
	ok(lv.player.hq and lv.player.light_model.get_child_count() == 1 and lv.player._lcd != null and lv.player._tune_knob != null, "modelled hands, torch, live receiver display and tuning knob")
	ok(not G.has_save(), "the slice never writes the campaign save")
	# the forecast in the corridor
	var f = lv.ent_at("f")
	lv.player.global_transform.origin = f.pos + Vector3(0, 0.05, 2.0); lv.player.rotation_degrees.y = 0
	G.has_radio = true; lv.radio.on = true; lv.radio.f = 101.3
	for i in 900:
		yield(get_tree(), "physics_frame"); G.skip = true
		if G.flag("sl_fore"): break
	ok(G.flag("sl_fore"), "101.3 forecast received in the corridor")
	ok(lv.player._lcd.text == "101.3" and lv.player._lcd.band == "FORECAST", "receiver display shows the tuned frequency and band (%s %s)" % [lv.player._lcd.text, lv.player._lcd.band])
	lv.radio.on = false
	# the main receiver starts the encounter
	var u = lv.ent_at("U")
	lv.player.global_transform.origin = lv.pos_of("u") + Vector3(0, 0.05, 0)
	G.skip = true
	lv.interact(u)
	var dof = false
	for i in 30:                          # the event runner starts on the next idle frame
		yield(get_tree(), "idle_frame")
		if lv.env.dof_blur_far_enabled:
			dof = true; break
	ok(dof, "cinematic depth of field during the scripted encounter")
	for i in 600:
		yield(get_tree(), "physics_frame")
		if lv.listener and is_instance_valid(lv.listener): break
	ok(lv.listener and is_instance_valid(lv.listener) and lv.listener.hq, "the new Listener arrives through the vent")
	ok(lv.art.find_node("Beacon", true, false).visible, "red beacon switched on")
	var h = lv.ent_at("H")
	lv.player.toggle_hide(h)
	yield(frames(10), "completed")
	ok(lv.player.hidden and lv.player.head.translation.y < 1.2, "hiding under the desk lowers the view")
	yield(frames(60), "completed")
	ok(not lv.env.dof_blur_far_enabled, "depth of field released when the player has control")
	ok(lv.listener.body.anim.current_animation != "", "creature animation playing (%s)" % lv.listener.body.anim.current_animation)
	var hurt = false
	for i in 4000:
		yield(get_tree(), "physics_frame"); G.skip = true
		if lv and is_instance_valid(lv) and lv.player.health < 100: hurt = true
		if main.menu != null and is_instance_valid(main.menu): break
	G.skip = false
	ok(not hurt, "staying hidden and silent, the player is not found")
	ok(main.menu != null and is_instance_valid(main.menu), "the slice ends and returns to the menu")

func t_texq():
	# texture quality: Half swaps every large texture for its own half-resolution mip chain
	yield(_slice_ready(), "completed")
	var lv = main.level
	yield(frames(5), "completed")
	var mem_full = Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)
	var full = _tex_area(lv.art)
	G.settings.textures = 0
	load("res://scripts/texq.gd").apply(lv.art)
	yield(frames(5), "completed")
	var mem_half = Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)
	var half = _tex_area(lv.art)
	print("  texture memory: full %.0f MB, half %.0f MB; large textures: %d (largest %d px) -> largest %d px" % [mem_full / 1048576.0, mem_half / 1048576.0, full[0], full[2], half[2]])
	ok(full[0] > 10 and half[1] * 4 == full[1], "every large texture in the slice is at half resolution (texels %d -> %d)" % [full[1], half[1]])
	ok(mem_half < mem_full * 0.8, "texture memory drops (%.0f -> %.0f MB)" % [mem_full / 1048576.0, mem_half / 1048576.0])
	lv.spawn_listener("v", "watch")
	yield(frames(3), "completed")
	var skin = lv.listener.body.lods[0].get_surface_material(0).albedo_texture
	ok(skin.get_width() == 2048, "the Listener's 4K skin loads at 2K (%d)" % skin.get_width())
	G.settings.textures = 1

func _tex_area(n: Node, seen := {}, acc := [0, 0, 0]) -> Array:
	# [count, total texels, largest width] of the mipmapped textures of 1024 px or more (the ones Half affects)
	if n is MeshInstance and n.mesh:
		for i in n.mesh.get_surface_count():
			var m = n.get_surface_material(i) if n.get_surface_material(i) else n.mesh.surface_get_material(i)
			if m is SpatialMaterial:
				for k in SpatialMaterial.TEXTURE_MAX:
					var t = m.get_texture(k)
					if t == null or seen.has(t): continue
					seen[t] = true
					var big = t.get_width() >= 1024 if t is StreamTexture else t.get_width() >= 512
					if big and t.get_data() and t.get_data().has_mipmaps():
						acc[0] += 1; acc[1] += t.get_width() * t.get_height(); acc[2] = max(acc[2], t.get_width())
	for ch in n.get_children(): _tex_area(ch, seen, acc)
	return acc

func t_sliceperf():
	# frame cost of the slice at the corridor start and inside the comms room, per graphics preset
	yield(_slice_ready(), "completed")
	var lv = main.level
	for q in [0, 2, 3]:
		G.settings.quality = q; G.apply_settings(); G.emit_signal("settings_changed")
		for pose in [["corridor", Vector3(5.0, 0.05, 20.6), 0.0], ["room", Vector3(21.0, 0.05, 7.2), -96.0]]:
			lv.player.global_transform.origin = pose[1]; lv.player.rotation_degrees.y = pose[2]; lv.player.light_on = true
			yield(frames(30), "completed")
			var f0 = Engine.get_frames_drawn(); var t0 = OS.get_ticks_msec()
			yield(get_tree().create_timer(4.0), "timeout")
			var fps = (Engine.get_frames_drawn() - f0) * 1000.0 / max(1, OS.get_ticks_msec() - t0)
			print("PERF q%d %s: %.1f fps  vertices %d  draw calls %d  objects %d  video mem %.0f MB" % [q, pose[0], fps,
				Performance.get_monitor(Performance.RENDER_VERTICES_IN_FRAME), Performance.get_monitor(Performance.RENDER_DRAW_CALLS_IN_FRAME),
				Performance.get_monitor(Performance.RENDER_OBJECTS_IN_FRAME), Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0])

const SLICE_SHOTS = [
	# name, position, yaw, pitch, torch, radio MHz, listener [x, z, yaw, anim] or null, extra
	["s01_corridor", Vector3(5.0, 0, 20.6), 0.0, -2.0, true, 0.0, null, ""],
	["s02_receiver", Vector3(5.25, 0, 15.6), 4.0, -4.0, true, 101.3, null, ""],
	["s03_corner", Vector3(4.8, 0, 8.6), -62.0, -3.0, true, 0.0, null, ""],
	["s04_listener_corridor", Vector3(6.6, 0, 7.05), -90.0, 6.0, true, 0.0, [10.6, 7.0, 90.0, "listen"], ""],
	["s05_vestibule", Vector3(16.6, 0, 7.0), -90.0, -2.0, false, 0.0, null, ""],
	["s06_room", Vector3(20.9, 0, 7.2), -96.0, -6.0, false, 0.0, null, ""],
	["s07_console", Vector3(25.85, 0, 7.05), -90.0, -24.0, true, 89.1, null, ""],
	["s08_encounter", Vector3(27.5, 0, 11.3), 10.0, 4.0, false, 0.0, [25.6, 7.4, 160.0, "listen"], "hide"],
	["s09_hunt", Vector3(5.1, 0, 12.4), 0.0, 6.0, true, 0.0, [5.0, 9.4, 180.0, "run"], ""],
	["s10_creature_close", Vector3(5.05, 0, 12.3), 0.0, 4.0, true, 0.0, [5.0, 9.6, 155.0, "listen"], ""],
	["s11_creature_room", Vector3(24.4, 0, 8.3), -55.0, 8.0, true, 0.0, [26.0, 6.4, 120.0, "search"], "hide_no"],
	["s12_head_close", Vector3(5.0, 0, 11.75), 6.0, 3.0, true, 0.0, [5.1, 9.3, 170.0, "idle"], ""],
	["s15_creature_crts", Vector3(28.3, 0, 8.4), -72.0, -2.0, true, 0.0, [31.0, 6.7, 110.0, "listen"], ""],
	["s13_crawl", Vector3(17.4, 0, 6.9), 88.0, -9.0, true, 0.0, [13.2, 7.15, -62.0, "crawl"], ""],
	["s14_search_hidden", Vector3(27.5, 0, 11.3), 0.0, 6.0, false, 0.0, [26.3, 8.2, 200.0, "search"], "hide"],
]

func t_sliceshots():
	G.test_god = true
	var out = OS.get_environment("DF_OUT"); var only = OS.get_environment("DF_ONLY")
	yield(_slice_ready(), "completed")
	var lv = main.level
	G.has_radio = true
	main.ui.objective_text = ""; main.ui.obj_lbl.modulate.a = 0
	G.set_flag("sl_fore"); G.set_flag("sl_echo")          # no transmissions or triggers firing into the shots
	for e in lv.ents:
		if e.kind in ["trig", "radio"]: e.done = true
	for s in SLICE_SHOTS:
		if only != "" and not s[0].begins_with(only): continue
		lv.player.global_transform.origin = s[1] + Vector3(0, 0.05, 0)
		lv.player.rotation_degrees.y = s[2]; lv.player.pitch = deg2rad(s[3]); lv.player.head.rotation.x = lv.player.pitch
		lv.player.light_on = s[4]
		lv.radio.on = s[5] > 0.0
		if s[5] > 0.0: lv.radio.f = s[5]
		if lv.listener and is_instance_valid(lv.listener): lv.despawn_listener()
		if s[6] != null:
			lv.spawn_listener("v", "watch")
			lv.listener.translation = Vector3(s[6][0], 0, s[6][1]); lv.listener.rotation_degrees.y = s[6][2]
			lv.listener.force_anim = s[6][3]
		var beacon = lv.art.find_node("Beacon", true, false)
		beacon.visible = s[7] == "hide"
		if s[7] == "hide":
			lv.art.find_node("TrofferFlicker", true, false).light_energy = 0.0
			lv.player.hidden = true; lv.player.hide_ent = lv.ent_at("H")
		else:
			lv.player.hidden = false; lv.player.hide_ent = null
		yield(frames(int(OS.get_environment("DF_SETTLE")) if OS.has_environment("DF_SETTLE") else 70), "completed")
		_save("%s/%s.png" % [out, s[0]])

# ------------------------------------------------------------ gameplay recording of the slice (PNG sequence; tools/record_slice.sh)
# Real gameplay, scripted only at the controller: the player walks with the movement actions, raises and tunes the
# HX-7 with its own actions, the forecast arrives through the radio system, the console starts the real encounter
# script and the real Listener AI searches while the player hides. Run with DF_GODOT_ARGS="--fixed-fps 30": every
# rendered frame is exactly 1/30 s of game time, however slowly the machine renders.
var _rec_out := ""
var _rec_n := 0
var _rec_max := 100000

func _rec():
	yield(get_tree(), "idle_frame")
	if _rec_n < _rec_max:
		var img = get_viewport().get_texture().get_data(); img.flip_y()
		img.save_png("%s/f%05d.png" % [_rec_out, _rec_n])
	_rec_n += 1

func _rec_wait(sec: float):
	for i in int(sec * 30.0): yield(_rec(), "completed")

func _rec_turn(pl, yaw: float, pitch: float, sec: float):
	var y0 = pl.rotation_degrees.y; var p0 = rad2deg(pl.pitch)
	var dy = wrapf(yaw - y0, -180.0, 180.0); var n = max(1, int(sec * 30.0))
	for i in n:
		var k = smoothstep(0.0, 1.0, float(i + 1) / n)
		pl.rotation_degrees.y = y0 + dy * k
		pl.pitch = deg2rad(lerp(p0, pitch, k)); pl.head.rotation.x = pl.pitch
		yield(_rec(), "completed")

func _rec_walk(pl, to: Vector3, pitch := -3.0, speed := 1.0):
	for i in 900:
		var d = to - pl.global_transform.origin; d.y = 0
		if d.length() < 0.3: break
		var err = wrapf(rad2deg(atan2(-d.x, -d.z)) - pl.rotation_degrees.y, -180.0, 180.0)
		pl.rotation_degrees.y += clamp(err, -3.5, 3.5)          # turns at up to 105 degrees a second
		pl.pitch = lerp(pl.pitch, deg2rad(pitch), 0.06); pl.head.rotation.x = pl.pitch
		if abs(err) < 45.0: Input.action_press("fwd", clamp(d.length() / 1.2, 0.35, 1.0) * speed)
		else: Input.action_release("fwd")
		yield(_rec(), "completed")
	Input.action_release("fwd")

func _rec_tap(action: String):
	Input.action_press(action); yield(_rec(), "completed"); Input.action_release(action)

func t_slicerec():
	_rec_out = OS.get_environment("DF_OUT")
	if OS.has_environment("DF_FRAMES"): _rec_max = int(OS.get_environment("DF_FRAMES"))
	G.test_god = true                      # a safety net only: it disables hurt() and nothing else
	main.start_slice()
	while main.level == null: yield(_rec(), "completed")
	var lv = main.level; var pl = lv.player
	lv.radio.f = 100.0                     # the receiver was left just below the forecast band
	while lv.running > 0 and _rec_n < 900: yield(_rec(), "completed")     # title card, fade-in, first line
	yield(_rec_wait(0.6), "completed")
	yield(_rec_walk(pl, Vector3(5.0, 0, 18.4)), "completed")          # the trigger line plays as we pass
	yield(_rec_wait(1.2), "completed")
	yield(_rec_tap("radio"), "completed")                              # raise the HX-7
	yield(_rec_wait(0.8), "completed")
	Input.action_press("tune_up")
	for i in 150:
		yield(_rec(), "completed")
		if lv.radio.f >= 101.25: break
	Input.action_release("tune_up")
	yield(_rec_walk(pl, Vector3(5.0, 0, 17.3), -2.0, 0.5), "completed")
	for i in 300:                                                      # hold the antenna on the source until it locks
		yield(_rec(), "completed")
		if G.flag("sl_fore"): break
	yield(_rec_wait(2.5), "completed")
	yield(_rec_walk(pl, Vector3(5.0, 0, 9.4), -3.0, 0.6), "completed")
	yield(_rec_wait(1.0), "completed")
	yield(_rec_tap("radio"), "completed")                              # lower it: the carrier gives you away
	yield(_rec_walk(pl, Vector3(5.6, 0, 7.1)), "completed")
	yield(_rec_turn(pl, -90.0, -2.0, 0.7), "completed")
	for p in [Vector3(10.0, 0, 7.0), Vector3(16.0, 0, 7.0), Vector3(20.5, 0, 7.1), Vector3(24.6, 0, 7.05)]:
		yield(_rec_walk(pl, p), "completed")
	yield(_rec_turn(pl, -90.0, -20.0, 0.9), "completed")
	yield(_rec_wait(0.7), "completed")
	var u = lv.ent_at("U")
	yield(_rec_tap("interact"), "completed")
	if lv.running == 0 and not u.done: lv.interact(u)                  # same call the interact key makes
	for i in 2400:                                                     # the encounter script: the receiver, Evelyn, the lights fail
		yield(_rec(), "completed")
		if lv.listener and is_instance_valid(lv.listener) and not pl.locked: break
	yield(_rec_wait(1.0), "completed")
	yield(_rec_turn(pl, 160.0, -4.0, 0.9), "completed")
	yield(_rec_walk(pl, Vector3(26.6, 0, 9.6), -6.0), "completed")
	pl.toggle_hide(lv.ent_at("H"))                                     # same call the interact key makes on the desk
	var hold = float(OS.get_environment("DF_HIDE_SEC")) if OS.has_environment("DF_HIDE_SEC") else 24.0
	yield(_rec_wait(hold), "completed")
	ok(_rec_n > 300, "recorded %d frames (%.1f s at 30 fps)" % [min(_rec_n, _rec_max), min(_rec_n, _rec_max) / 30.0])
	ok(G.flag("sl_fore"), "the forecast was received through the radio system")
	ok(lv.listener and is_instance_valid(lv.listener), "the Listener is in the room")

# ------------------------------------------------------------ export all story data as JSON (docs are generated from it)
func t_export():
	var all = {"chapters": [], "titles": Story.TITLES, "credits": Story.CREDITS, "items": Story.ITEMS, "ach": Story.ACH}
	for n in chapters():
		var d = Story.chapter(n); d.erase("map_cells")
		all.chapters.append(d)
	for id in ["A", "B", "C", "D"]:
		var d = Story.ending(id); d["ending"] = id
		all.chapters.append(d)
	var f = File.new(); f.open(OS.get_environment("DF_OUT"), File.WRITE); f.store_string(to_json(all)); f.close()
	print("  exported ", all.chapters.size(), " scripts")

# ------------------------------------------------------------ Godot's licence and its third-party notices, from the engine itself
func t_licenses():
	var v = Engine.get_version_info()
	var out = "Godot Engine — https://godotengine.org\nVersion: %d.%d.%d-%s\n\n" % [v.major, v.minor, v.patch, v.status]
	out += Engine.get_license_text() + "\n\n"
	out += "=" .repeat(72) + "\nThird-party components included in Godot Engine\n" + "=".repeat(72) + "\n"
	for c in Engine.get_copyright_info():
		out += "\n%s\n" % c.name
		for part in c.parts:
			for cr in part.copyright: out += "  Copyright (c) %s\n" % cr
			out += "  License: %s\n" % part.license
	out += "\n" + "=".repeat(72) + "\nLicence texts\n" + "=".repeat(72) + "\n"
	var li = Engine.get_license_info()
	var names = li.keys(); names.sort()
	for n in names: out += "\n----- %s -----\n%s\n" % [n, li[n]]
	var f = File.new(); f.open(OS.get_environment("DF_OUT"), File.WRITE); f.store_string(out); f.close()
	ok(Engine.get_copyright_info().size() > 10 and out.length() > 20000, "licence text written (%d components, %d chars)" % [Engine.get_copyright_info().size(), out.length()])

# ------------------------------------------------------------ real-time length of the opening cinematic (no skipping)
func t_introtime():
	var t0 = OS.get_ticks_msec()
	main.play_intro()
	for i in 20000:
		yield(get_tree(), "idle_frame")
		if main.menu != null and is_instance_valid(main.menu): break
	var secs = (OS.get_ticks_msec() - t0) / 1000.0
	print("  opening cinematic + title reveal: %.1f s" % secs)
	ok(secs > 100 and secs < 200, "opening sequence runs 2–3 minutes (%.0f s)" % secs)

# ------------------------------------------------------------ performance sample (software renderer here; real GPUs will differ)
func t_perf():
	G.test_god = true
	for n in [1, 5, 8, 11, 13]:
		G.new_run(n); G.set_flag("started%d" % n); G.set_flag("power%d" % n)
		var t0 = OS.get_ticks_msec()
		main.start_chapter(n)
		var build_ms = OS.get_ticks_msec() - t0
		main.ui.fade_rect.color.a = 0
		yield(frames(30), "completed")
		var f0 = Engine.get_frames_drawn(); var t1 = OS.get_ticks_msec()
		for i in 120: yield(get_tree(), "idle_frame")
		var fps = (Engine.get_frames_drawn() - f0) * 1000.0 / max(1, OS.get_ticks_msec() - t1)
		print("  ch%02d  build %4d ms   %.1f fps   (%s, quality %d)" % [n, build_ms, fps, str(OS.window_size), G.settings.quality])

# ------------------------------------------------------------ New Game+ ("Second Signal")
func _receive(lv, key: String) -> bool:
	var e = lv.ent_at(key)
	if e == null: return false
	lv.player.global_transform.origin = e.pos + Vector3(0, 0.1, 0)
	lv.radio.on = true; lv.radio.f = e.d.f; G.has_radio = true; G.radio_batt = 100
	for i in 600:
		yield(get_tree(), "physics_frame"); G.skip = true
		if e.done: break
	lv.radio.on = false
	yield(_settle(lv), "completed")
	return e.done

func t_ngplus():
	G.test_god = true
	# 1. a completed first run: hid in one locker a lot, leaned on the radio, threw bottles, escaped by sprinting, opened the Door
	G.new_run(13)
	G.flags["m_hide_c2_H1"] = 6; G.flags["m_radio"] = 300; G.flags["m_hunts"] = 4; G.flags["m_bottles"] = 5; G.flags["m_sprint_esc"] = 3
	G.set_flag("final_open")
	G.snapshot_memory()
	ok(G.ng_unlocked and G.memory.ending == "B" and int(G.memory.runs) >= 1, "finishing a run unlocks New Game+ and remembers the ending")
	main.show_menu(); yield(frames(3), "completed")
	var labels = []
	for b in main.menu.list.get_children(): labels.append(b.text)
	ok("NEW GAME+  —  SECOND SIGNAL" in labels, "menu offers New Game+ once unlocked (%s)" % str(labels))
	# 2. start New Game+
	main.new_game_plus(); yield(frames(5), "completed")
	ok(G.flag("ngp") and G.flag("mem_end_B") and main.level.data.n == 1, "New Game+ starts at chapter 1 remembering ending B")
	ok(int(G.flags.get("m_hide_c2_H1", 0)) == 3 and int(G.flags.get("m_radio", 0)) == 150 and int(G.flags.get("m_hunts", 0)) == 2, "habits carried over at half strength")
	ok(main.level.ent_at("N") != null, "the dispatch slip exists in New Game+")
	# 3. chapter 2 in New Game+: 88.0 content present, adaptations bounded
	G.set_flag("started2"); G.chapter = 2; main.start_chapter(2); yield(frames(8), "completed")
	var lv = main.level
	ok(lv.ent_at("8") != null, "88.0 transmission exists in New Game+")
	lv.spawn_listener("Z", "patrol"); var L = lv.listener
	ok(L.ngp and L.hunt_speed < lv.player.SPRINT, "remembered sprint escapes make it faster, but still slower than a sprint (%.1f < %.1f)" % [L.hunt_speed, lv.player.SPRINT])
	ok(L.hunt_cap <= 45.0, "chases stay time-capped")
	ok(L.lure_wise, "a bottle-heavy previous run makes it lure-wise")
	ok(L.hear_mult("radio") <= 1.5, "radio learning still capped at +50%")
	var h = lv.ent_at("H"); L.last_known = h.pos
	var picks = 0
	for i in 400:
		L._next_search()
		if L._check_hide == h: picks += 1
	ok(picks > 40 and picks < 300, "remembered locker is checked more often but never certainly (%d/400)" % picks)
	# 88.0 is silent: listening there never reaches the Listener
	var r0 = int(G.flags.get("m_radio", 0))
	L.global_transform.origin = lv.ent_at("8").pos + Vector3(2, 0, 0); L.command("dormant")
	var got = yield(_receive(lv, "8"), "completed")
	ok(got and G.flag("ss1"), "88.0 transmission received")
	ok(int(G.flags.get("m_radio", 0)) == r0, "88.0 is below its band: no radio noise reached it")
	# 4. a normal run never builds New Game+ content
	G.new_run(2); G.set_flag("started2"); main.start_chapter(2); yield(frames(8), "completed")
	ok(main.level.ent_at("8") == null and not G.flag("ngp"), "normal runs have no 88.0 content")
	# 5. finishing New Game+ grants its achievement and still reaches an ending
	G.new_run_plus(); G.chapter = 13; G.set_flag("started13"); G.has_radio = true; G.flags["_test_choice"] = 1
	main.start_chapter(13)
	lv = main.level
	for i in 600:
		yield(get_tree(), "physics_frame"); G.skip = true
		if lv.running == 0: break
	lv.interact(lv.ent_at("U"))
	var reached = false
	for i in 4000:
		yield(get_tree(), "physics_frame"); G.skip = true
		if main.credits != null and is_instance_valid(main.credits):
			reached = true; break
	ok(reached and "second_signal" in G.achievements, "New Game+ reaches an ending and awards Second Signal")

# ------------------------------------------------------------ recorded voice-over is picked up automatically by filename
func t_vo():
	var line = "Twenty-eight years of dust, and the emergency lamps still think someone's coming home."
	var id = main.ui.vo_id("DANIEL", line)
	ok(ResourceLoader.exists("res://vo/%s.ogg" % id), "test recording present and imported (%s)" % id)
	var t0 = OS.get_ticks_msec()
	main.ui.say("DANIEL", line)
	yield(frames(5), "completed")
	var s = main.ui._voice.stream
	ok(s is AudioStreamOGGVorbis and main.ui._voice.playing, "say() plays the recorded file instead of the placeholder voice")
	while main.ui._saying: yield(get_tree(), "idle_frame")
	ok((OS.get_ticks_msec() - t0) / 1000.0 >= 4.4, "subtitle stays up for the whole recording")
	main.ui.say("DANIEL", "A line nobody has recorded yet.")
	yield(frames(5), "completed")
	ok(main.ui._voice.stream == Snd.bank["voice"], "unrecorded lines fall back to the radio-voice texture")
