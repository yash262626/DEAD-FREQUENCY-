extends Node
# Global game state, settings, input map, save/load.

var SAVE := "user://save.json"
var PROFILE := "user://profile.json"
const SAVE_VERSION := 1
const LAST_CHAPTER := 13

signal settings_changed
signal toast(text)

var flags := {}
var inv := {}
var journal := []          # [{t:title, x:text, k:kind}]
var chapter := 1
var checkpoint := ""       # marker char in the current chapter
var health := 100.0
var battery := 100.0       # flashlight cell
var radio_batt := 100.0    # radio cell
var has_radio := false
var has_light := true

# profile (persists across runs)
var unlocked := 1
var endings := []
var achievements := []
var intro_seen := false
var ng_unlocked := false
var memory := {}           # selected habits of the last completed run (New Game+ "Second Signal")
var settings := {
	"master": 0.9, "music": 0.8, "sfx": 1.0,
	"sens": 1.0, "invert_y": false, "fov": 75.0,
	"quality": 2, "fullscreen": false, "vsync": true, "brightness": 1.0,
	"subtitles": true, "sub_size": 1, "head_bob": true, "toggle_crouch": true,
	"hold_skip": true, "reduce_flashes": false,
}

var skip := false          # cinematic fast-forward
var test_mode := false
var test_god := false

func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	if OS.has_environment("DF_TEST"):
		# automated tests never touch the player's real save or profile
		SAVE = "user://test_save.json"; PROFILE = "user://test_profile.json"
		var d = Directory.new()
		for f in [SAVE, PROFILE]:
			if d.file_exists(f): d.remove(f)
	_setup_input()
	_setup_buses()
	load_profile()
	apply_settings()

# ---------------------------------------------------------------- input
func _key(a, code):
	var e = InputEventKey.new(); e.scancode = code; InputMap.action_add_event(a, e)
func _mb(a, b):
	var e = InputEventMouseButton.new(); e.button_index = b; InputMap.action_add_event(a, e)
func _jb(a, b):
	var e = InputEventJoypadButton.new(); e.button_index = b; InputMap.action_add_event(a, e)
func _ja(a, axis, v):
	var e = InputEventJoypadMotion.new(); e.axis = axis; e.axis_value = v; InputMap.action_add_event(a, e)

func _setup_input():
	var acts = ["fwd","back","left","right","sprint","crouch","lean_l","lean_r","interact","light",
		"radio","tune_up","tune_dn","journal","heal","throw","pause","skip","look_l","look_r","look_u","look_d"]
	for a in acts:
		if not InputMap.has_action(a): InputMap.add_action(a, 0.3)
	_key("fwd", KEY_W); _key("back", KEY_S); _key("left", KEY_A); _key("right", KEY_D)
	_ja("fwd", JOY_AXIS_1, -1); _ja("back", JOY_AXIS_1, 1); _ja("left", JOY_AXIS_0, -1); _ja("right", JOY_AXIS_0, 1)
	_ja("look_l", JOY_AXIS_2, -1); _ja("look_r", JOY_AXIS_2, 1); _ja("look_u", JOY_AXIS_3, -1); _ja("look_d", JOY_AXIS_3, 1)
	_key("sprint", KEY_SHIFT); _jb("sprint", JOY_L3)
	_key("crouch", KEY_CONTROL); _key("crouch", KEY_C); _jb("crouch", JOY_XBOX_B)
	_key("lean_l", KEY_Q); _key("lean_r", KEY_E); _jb("lean_l", JOY_L); _jb("lean_r", JOY_R)
	_key("interact", KEY_F); _mb("interact", BUTTON_LEFT); _jb("interact", JOY_XBOX_A)
	_key("light", KEY_T); _mb("light", BUTTON_MIDDLE); _jb("light", JOY_XBOX_Y)
	_key("radio", KEY_R); _mb("radio", BUTTON_RIGHT); _jb("radio", JOY_XBOX_X)
	_key("tune_up", KEY_RIGHT); _jb("tune_up", JOY_DPAD_RIGHT)
	_key("tune_dn", KEY_LEFT); _jb("tune_dn", JOY_DPAD_LEFT)
	_key("journal", KEY_TAB); _jb("journal", JOY_SELECT)
	_key("heal", KEY_H); _jb("heal", JOY_DPAD_UP)
	_key("throw", KEY_G); _jb("throw", JOY_DPAD_DOWN)
	_key("pause", KEY_ESCAPE); _jb("pause", JOY_START)
	_key("skip", KEY_SPACE); _key("skip", KEY_ENTER); _jb("skip", JOY_XBOX_A)

func _setup_buses():
	for n in ["Music", "SFX", "Voice"]:
		if AudioServer.get_bus_index(n) < 0:
			AudioServer.add_bus()
			var i = AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, n)
			AudioServer.set_bus_send(i, "Master")
	var sfx = AudioServer.get_bus_index("SFX")
	if AudioServer.get_bus_effect_count(sfx) == 0:
		var rv = AudioEffectReverb.new()
		rv.room_size = 0.75; rv.damping = 0.4; rv.wet = 0.22; rv.dry = 1.0; rv.hipass = 0.15
		AudioServer.add_bus_effect(sfx, rv)

# ---------------------------------------------------------------- settings / profile
func _vol(bus, v):
	var i = AudioServer.get_bus_index(bus)
	AudioServer.set_bus_volume_db(i, linear2db(max(v, 0.0001)))
	AudioServer.set_bus_mute(i, v <= 0.001)

func apply_settings():
	_vol("Master", settings.master); _vol("Music", settings.music)
	_vol("SFX", settings.sfx); _vol("Voice", settings.sfx)
	if not test_mode:
		OS.window_fullscreen = settings.fullscreen
		OS.vsync_enabled = settings.vsync
	emit_signal("settings_changed")

func save_profile():
	var f = File.new()
	if f.open(PROFILE, File.WRITE) == OK:
		f.store_string(to_json({"settings": settings, "unlocked": unlocked, "endings": endings,
			"achievements": achievements, "intro_seen": intro_seen, "ng_unlocked": ng_unlocked, "memory": memory}))
		f.close()

func load_profile():
	var f = File.new()
	if not f.file_exists(PROFILE) or f.open(PROFILE, File.READ) != OK: return
	var r = JSON.parse(f.get_as_text()); f.close()
	if r.error != OK or typeof(r.result) != TYPE_DICTIONARY: return
	var d = r.result
	if d.has("settings"):
		for k in d.settings:
			if settings.has(k): settings[k] = d.settings[k]
	settings.quality = int(settings.quality); settings.sub_size = int(settings.sub_size)
	unlocked = int(d.get("unlocked", 1)); endings = d.get("endings", [])
	achievements = d.get("achievements", []); intro_seen = d.get("intro_seen", false)
	ng_unlocked = d.get("ng_unlocked", false)
	memory = d.get("memory", {}) if typeof(d.get("memory", {})) == TYPE_DICTIONARY else {}

func achieve(id):
	if not id in achievements:
		achievements.append(id); save_profile()
		emit_signal("toast", "ACHIEVEMENT  " + str(Story.ACH.get(id, id)))

# ---------------------------------------------------------------- run state
func new_run(ch := 1):
	flags = {}; inv = {}; journal = []; chapter = ch; checkpoint = ""
	health = 100.0; battery = 100.0; radio_batt = 100.0
	has_radio = ch > 1; has_light = true
	if ch > 1:
		inv = {"battery": 1, "medkit": 1}
		# chapter-select runs get neutral story defaults
		flags = {"cs_run": true}

# ---------------------------------------------------------------- New Game+ memory
# What the Listener keeps between runs is deliberately partial: habits, not knowledge.
func snapshot_memory():
	var hides = {}
	for k in flags:
		if str(k).begins_with("m_hide_") and int(flags[k]) > 0: hides[k] = int(flags[k])
	memory = {"radio": int(flags.get("m_radio", 0)), "hunts": int(flags.get("m_hunts", 0)), "hides": hides,
		"bottles": int(flags.get("m_bottles", 0)), "sprint_escapes": int(flags.get("m_sprint_esc", 0)),
		"ending": ending_id(), "runs": int(memory.get("runs", 0)) + 1}
	ng_unlocked = true
	save_profile()

func new_run_plus():
	new_run(1)
	flags["ngp"] = true
	flags["mem_end_" + str(memory.get("ending", "C"))] = true
	# carried at half strength: it remembers, but not perfectly
	flags["m_radio"] = int(memory.get("radio", 0) / 2)
	var hides = memory.get("hides", {})
	for k in hides: flags[k] = int(ceil(float(hides[k]) / 2.0))
	flags["m_hunts"] = int(min(2, memory.get("hunts", 0)))
	flags["mem_bottles"] = int(memory.get("bottles", 0))
	flags["mem_sprint"] = int(memory.get("sprint_escapes", 0))

func flag(n) -> bool: return flags.get(n, false)
func set_flag(n, v := true): flags[n] = v
func count(prefix) -> int:
	var c = 0
	for k in flags:
		if flags[k] and str(k).begins_with(prefix): c += 1
	return c
func give(id, n := 1): inv[id] = int(inv.get(id, 0)) + n
func has(id) -> bool: return int(inv.get(id, 0)) > 0
func take(id, n := 1):
	inv[id] = max(0, int(inv.get(id, 0)) - n)
func add_journal(title, text, kind := "note"):
	for j in journal:
		if j.t == title: return
	journal.append({"t": title, "x": text, "k": kind})

func has_save() -> bool:
	return File.new().file_exists(SAVE)

func save_game():
	var d = {"v": SAVE_VERSION, "flags": flags, "inv": inv, "journal": journal, "chapter": chapter,
		"checkpoint": checkpoint, "health": health, "battery": battery, "radio_batt": radio_batt,
		"has_radio": has_radio, "has_light": has_light}
	var f = File.new()
	if f.open(SAVE, File.WRITE) != OK: return false
	f.store_string(to_json(d)); f.close()
	return true

func load_game() -> bool:
	var f = File.new()
	if not f.file_exists(SAVE) or f.open(SAVE, File.READ) != OK: return false
	var r = JSON.parse(f.get_as_text()); f.close()
	if r.error != OK or typeof(r.result) != TYPE_DICTIONARY: return false
	var d = r.result
	if int(d.get("v", 0)) > SAVE_VERSION: return false
	flags = d.get("flags", {}); inv = d.get("inv", {}); journal = d.get("journal", [])
	for k in inv: inv[k] = int(inv[k])
	chapter = int(d.get("chapter", 1)); checkpoint = str(d.get("checkpoint", ""))
	health = float(d.get("health", 100)); battery = float(d.get("battery", 100))
	radio_batt = float(d.get("radio_batt", 100)); has_radio = d.get("has_radio", false)
	has_light = d.get("has_light", true)
	return true

func unlock_chapter(n):
	if n > unlocked and n <= LAST_CHAPTER:
		unlocked = n; save_profile()

func ending_id() -> String:
	# Decided by what the player learned and chose. See docs/02_STORY_BIBLE.md
	var tapes = count("tape_ev")
	if flag("final_open"): return "B"
	if flag("final_send") and flag("trust_mira") and flag("hale_truth") and tapes >= 5 and flag("shutdown_key"): return "D"
	if flag("final_silence") and flag("shutdown_key"): return "A"
	return "C"
