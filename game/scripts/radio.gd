extends Node
# The HX-7 field receiver. Four working bands + hidden puzzle frequencies.
# Every second it is switched on it broadcasts the player's position to the Listener.

const BANDS = {89.1: "89.1  ECHO — the past", 94.6: "94.6  PROXIMITY — movement", 101.3: "101.3  FORECAST — not yet", 107.9: "107.9  UNSEEN — what hides"}
const TOL := 0.16

var level
var ui
var player
var on := false
var f := 89.1
var sig := 0.0
var _hold := 0.0
var _emit := 0.0
var _beep := 0.0
var _lock_t := 0.0
var _lock_ent = null
var _forced := 0.0
var exposure := 0.0

func setup(lv, u, p):
	level = lv; ui = u; player = p

func band() -> float:
	for b in BANDS:
		if abs(f - b) < TOL: return b
	return 0.0

func force(state: bool, freq := -1.0):
	on = state
	if freq > 0: f = freq
	_forced = 1.0
	if state: Snd.play("glitch", -6)

func _tune(d: float):
	f = clamp(stepify(f + d, 0.1), 87.5, 108.0)
	Snd.play("tune", -10, 0.8 + (f - 87.5) / 20.0)
	_lock_t = 0.0

func _unhandled_input(ev):
	if not on or not G.has_radio or player._busy(): return
	if ev is InputEventMouseButton and ev.pressed:
		if ev.button_index == BUTTON_WHEEL_UP: _tune(0.1)
		elif ev.button_index == BUTTON_WHEEL_DOWN: _tune(-0.1)

func _process(dt):
	if level.dead: return
	_forced = max(0.0, _forced - dt)
	if G.has_radio and not player._busy():
		if Input.is_action_just_pressed("radio"):
			if not on and G.radio_batt <= 0 and not G.has("battery"): ui.toast("Receiver cell is dead.")
			else:
				on = not on; Snd.play("click", 0, 0.9)
				if on and not G.flag("radio_tut"):
					G.set_flag("radio_tut")
					ui.toast("Mouse wheel / ← → to tune.  Face the source: the antenna is directional.")
		if on:
			var dirn = Input.get_action_strength("tune_up") - Input.get_action_strength("tune_dn")
			if Input.is_action_just_pressed("tune_up"): _tune(0.1)
			elif Input.is_action_just_pressed("tune_dn"): _tune(-0.1)
			elif abs(dirn) > 0.5:
				_hold += dt
				if _hold > 0.35:
					_hold -= 0.05; _tune(0.1 * sign(dirn))
			else: _hold = 0.0
	var rs = ui.radio_state
	rs.on = on and G.has_radio; rs.f = f; rs.batt = G.radio_batt
	level.reveal_on = false
	var ld = 999.0
	if level.listener and is_instance_valid(level.listener):
		ld = (level.listener.global_transform.origin - player.global_transform.origin).length()
	# proximity interference exists whether or not the set is on
	var near = clamp(1.0 - ld / 9.0, 0.0, 1.0)
	if not rs.on:
		Snd.unloop("static"); rs.danger = near * 0.6; sig = 0; return
	G.radio_batt -= dt * (100.0 / 170.0)
	if G.radio_batt <= 0:
		if G.has("battery"):
			G.take("battery"); G.radio_batt = 100.0; ui.toast("Receiver cell replaced.")
		else:
			G.radio_batt = 0; on = false; Snd.play("power_down", -6, 1.6); return
	var b = band()
	rs.band = BANDS.get(b, "— no carrier —")
	var pp = player.global_transform.origin
	var fwd = -player.cam.global_transform.basis.z
	sig = 0.0
	var loud = 8.0
	# transmissions (echo / forecast / custom frequencies)
	var best = null
	for e in level.ents:
		if e.kind != "radio" or e.done or not level._cond(e.d): continue
		if abs(f - e.d.f) > TOL: continue
		var to = e.pos - pp; to.y = 0
		var dist = to.length(); var rng = e.d.get("r", 14.0)
		if dist > rng: continue
		var facing = 1.0 if dist < 1.5 else max(0.0, fwd.dot(to.normalized()))
		var s = (1.0 - dist / rng) * 0.55 + 0.45 * facing
		if dist < rng * 0.5 and facing > 0.8: s = max(s, 0.9)
		if s > sig:
			sig = s; best = e
	if best != null:
		rs.band = (BANDS.get(b, "%.1f  UNLISTED CARRIER" % f)) + "   ◂ SIGNAL"
		loud = 11.0
		if sig > 0.72 and level.running == 0:
			if _lock_ent != best:
				_lock_ent = best; _lock_t = 0.0
			_lock_t += dt
			if _lock_t > 1.0: _receive(best)
		else: _lock_t = max(0.0, _lock_t - dt)
	if b == 94.6:
		# movement detector: beeps faster as it closes; antenna direction sharpens the reading
		if ld < 60.0:
			var to2 = (level.listener.global_transform.origin - pp); to2.y = 0
			var facing2 = max(0.0, fwd.dot(to2.normalized()))
			sig = max(sig, clamp(1.0 - ld / 45.0, 0.05, 1.0) * (0.5 + 0.5 * facing2))
			_beep -= dt
			if _beep <= 0:
				_beep = clamp(ld / 14.0, 0.12, 2.2)
				Snd.play("beep_hi" if facing2 > 0.85 else "beep", -10 + sig * 6.0, 0.8 + sig * 0.5)
		else:
			_beep -= dt
			if _beep <= 0:
				_beep = 3.0; Snd.play("beep", -20, 0.5)
		loud = 10.0
	elif b == 107.9:
		level.reveal_on = true; loud = 15.0
		sig = max(sig, 0.5)
	# noise bed
	Snd.loop("static", "static", lerp(-10.0, -26.0, sig) + near * 6.0, 0.8 + (f - 87.5) / 30.0)
	# exposure: the carrier gives you away
	_emit -= dt
	if _emit <= 0:
		_emit = 1.2
		level.noise(pp, loud, "radio")
	var hm = 1.0
	if level.listener and is_instance_valid(level.listener): hm = level.listener.hear_mult("radio")
	exposure = clamp(1.3 - ld / (loud * hm), 0.0, 1.0) if ld < 900 else 0.0
	rs.sig = sig; rs.danger = max(exposure, near)

func _receive(e):
	_lock_t = 0.0; _lock_ent = null
	level._done(e)
	if e.d.has("flag"): G.set_flag(e.d.flag)
	Snd.play("glitch", -8)
	if e.d.has("lines"):
		var txt = ""
		for l in e.d.lines:
			if str(l[0]) != str(l[0]).to_lower() or str(l[0]) == "": txt += "%s: %s\n\n" % [l[0], l[1]]
		if e.d.has("title"): G.add_journal("%.1f MHz — %s" % [e.d.f, e.d.title], txt, "tape")
		yield(level.run(e.d.lines), "completed")
	if e.d.has("ev"): level.run(e.d.ev)
