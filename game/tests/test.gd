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

# ------------------------------------------------------------ cross-chapter flag + layout validation
const NONSOLID = ["paper", "debris", "coat", "figure", "shade", "lamp", "board", "vent", "pipes", "glass"]
const AUTO_FLAGS = ["cs_run", "radio_tut", "m_radio", "m_hunts", "m_unseen", "hunts_start"]

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
		match kind:
			"choice":
				G.flags["_test_choice"] = int(key); continue
			"wait":
				yield(frames(int(float(key) * 60)), "completed"); continue
			"crate":
				var c = _ent(lv, key); var pl = _ent(lv, s[2])
				ok(_reach(lv, c.pos, pl.pos), "ch%02d: crate %s can be pushed to plate %s" % [n, key, s[2]])
				c.node.global_transform.origin = pl.pos + Vector3(0, 0.6, 0); c.node.linear_velocity = Vector3()
				yield(_settle(lv), "completed"); continue
		var e = _ent(lv, key)
		if e == null:
			ok(false, "ch%02d: walkthrough step '%s' has no entity" % [n, key]); continue
		var pp = lv.player.global_transform.origin
		var target = e.pos
		var reach = _reach(lv, pp, target)
		if not reach and e.kind == "door":
			for o in [Vector3(2, 0, 0), Vector3(-2, 0, 0), Vector3(0, 0, 2), Vector3(0, 0, -2)]:
				var c = lv.cell_of(target + o)
				if lv.is_floor(int(c.x), int(c.y)) and _reach(lv, pp, target + o):
					reach = true; target = target + o; break
		ok(reach, "ch%02d: step '%s' reachable from %s" % [n, key, str(lv.cell_of(pp))])
		if kind == "radio":
			lv.player.global_transform.origin = target + Vector3(0, 0.1, 0)
			lv.radio.on = true; lv.radio.f = e.d.f; G.has_radio = true; G.radio_batt = 100
			for i in 600:
				yield(get_tree(), "physics_frame"); G.skip = true
				if e.done: break
			ok(e.done, "ch%02d: transmission '%s' received" % [n, key])
			lv.radio.on = false
		else:
			lv.player.global_transform.origin = (e.pos if e.kind != "door" else target) + Vector3(0, 0.1, 0)
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
