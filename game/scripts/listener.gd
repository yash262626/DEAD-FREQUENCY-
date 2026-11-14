extends Spatial
# THE LISTENER — sound-driven stalker AI.
# It never reads the player's position directly. It only knows:
#   * noises it "hears" (position blurred by distance),
#   * what it can see along an unobstructed line (limited range / cone),
#   * habits it has counted (lockers reused, radio overuse, sprinting).
# See docs/09_ENEMY_AI.md for the full specification and counterplay table.

enum S { DORMANT, PATROL, INVESTIGATE, SEARCH, STALK, HUNT, AMBUSH, RETREAT }
const NAMES = ["DORMANT", "PATROL", "INVESTIGATE", "SEARCH", "STALK", "HUNT", "AMBUSH", "RETREAT"]
const SPEED = [0.0, 1.5, 2.3, 1.8, 2.0, 4.4, 3.0, 3.2]
const MIMIC = [
	["MIRA?", "Daniel? I'm right here. Just follow my voice."],
	["EVELYN?", "It's safe now. You can come out."],
	["DANIEL?", "Hello? ...Hello? Is somebody there?"],
	["MARCUS?", "Arlen. Stay where you are. I'm coming to you."],
	["MIRA?", "Please. Please don't leave me alone down here."],
]

var level
var player
var ui
var st: int = S.PATROL
var st_t := 0.0
var route := []
var target := Vector3()
var last_known := Vector3()
var alert := 0.0            # 0..1 visual certainty
var sees := false
var lost_t := 0.0
var cloaked := false         # only visible on 107.9 (containment chapters)
var leash := Vector3()
var passive := false         # scripted "watch only" mode: never attacks
var blind := false           # final approach: it can only hear
var body: Spatial
var snd: AudioStreamPlayer3D
var _anim := 0.0
var _repath := 0.0
var _search_left := 0
var _step := 0.0
var _mimic_cd := 12.0
var _saw_hide = null
var _check_hide = null
var _rng := RandomNumberGenerator.new()
var heat := {}               # patrol marker index -> how often noise was heard nearby
var trace := []              # test hook: state history

func setup(lv, p, u, pos: Vector3, mode: String):
	level = lv; player = p; ui = u
	_rng.randomize()
	translation = pos
	body = level.Props.listener_body(); add_child(body)
	snd = AudioStreamPlayer3D.new(); snd.stream = Snd.bank["clicks"]; snd.unit_db = 2; snd.unit_size = 4.0; snd.max_distance = 26
	snd.bus = "SFX"; snd.translation.y = 2.4; add_child(snd); snd.play()
	cloaked = level.data.get("cloaked", false)
	command(mode, pos)

func command(mode: String, pos := Vector3()):
	passive = false
	match mode:
		"dormant": _go(S.DORMANT)
		"patrol": _go(S.PATROL)
		"hunt":
			last_known = player.global_transform.origin; _go(S.HUNT)
		"stalk":
			last_known = level.random_floor_near(player.global_transform.origin, 4.0); _go(S.STALK)
		"seek":
			target = pos; last_known = pos; _go(S.INVESTIGATE)
		"face":
			var d = player.global_transform.origin - global_transform.origin
			rotation.y = atan2(-d.x, -d.z); passive = true
			if st != S.DORMANT: _go(S.DORMANT)
		"blind": blind = true
		"sighted": blind = false
		"retreat": _go(S.RETREAT)
		"ambush": _go(S.AMBUSH)
		"watch":
			passive = true; _go(S.DORMANT)
		"goto":
			passive = true; target = pos; route = level.path(global_transform.origin, pos); st = S.INVESTIGATE; st_t = 0

func hear_mult(kind: String) -> float:
	# it learns: the more the radio is used, the further it hears the carrier
	if kind == "radio": return 1.0 + min(0.5, int(G.flags.get("m_radio", 0)) * 0.004)
	return 1.0

func hear(pos: Vector3, loud: float, kind: String):
	if passive: return
	var d = (pos - global_transform.origin).length()
	if kind == "radio": G.flags["m_radio"] = int(G.flags.get("m_radio", 0)) + 1
	if d > loud * hear_mult(kind): return
	if st == S.HUNT or st == S.RETREAT: return
	# blurred: the further the sound, the worse its fix
	var err = clamp(d * 0.18, 0.0, 5.0)
	var guess = level.random_floor_near(pos, err) if err > 0.8 else pos
	_heat(pos)
	if st == S.AMBUSH and d > 6.0: return
	if st == S.DORMANT and loud < 4.0 and d > 3.0: return
	target = guess; last_known = guess
	alert = min(1.0, alert + (0.12 if kind == "step" else 0.2))
	if st in [S.DORMANT, S.PATROL, S.SEARCH, S.INVESTIGATE, S.STALK]:
		if st != S.INVESTIGATE: Snd.play3d("clicks", level, global_transform.origin + Vector3(0, 2, 0), 4, 1.5)
		_go(S.INVESTIGATE)

func _heat(pos: Vector3):
	var pts = level.markers.get("P", [])
	var best = -1; var bd = 1e9
	for i in pts.size():
		var d = (pts[i] - pos).length()
		if d < bd:
			bd = d; best = i
	if best >= 0: heat[best] = heat.get(best, 0) + 1

func player_hid(e):
	# if it was looking when the door closed, the locker is not a hiding place
	if sees or (st == S.HUNT and lost_t < 1.0): _saw_hide = e

func _go(s: int):
	st = s; st_t = 0.0; route = []; _repath = 0.0
	trace.append(NAMES[s])
	match s:
		S.PATROL: _next_patrol()
		S.INVESTIGATE: route = level.path(global_transform.origin, target)
		S.SEARCH:
			_search_left = 3 + _rng.randi() % 2; _next_search()
		S.HUNT:
			Snd.play3d("screech", level, global_transform.origin + Vector3(0, 2, 0), 6, 1.0, 40)
			G.flags["m_hunts"] = int(G.flags.get("m_hunts", 0)) + 1
		S.RETREAT:
			var pts = level.markers.get("P", [])
			var far = global_transform.origin; var fd = -1.0
			for p in pts:
				var d = (p - player.global_transform.origin).length()
				if d > fd:
					fd = d; far = p
			route = level.path(global_transform.origin, far); alert = 0.0
		S.AMBUSH:
			# cut the player off: pick a spot ahead of where they are heading, out of sight
			var pv = player.vel; pv.y = 0
			var ahead = player.global_transform.origin + (pv.normalized() * 12.0 if pv.length() > 0.5 else -player.global_transform.basis.z * 12.0)
			target = level.random_floor_near(ahead, 4.0)
			route = level.path(global_transform.origin, target)

func _next_patrol():
	var pts = level.markers.get("P", [])
	if pts.size() == 0:
		target = level.random_floor_near(global_transform.origin, 10.0)
	else:
		# weighted toward places where it has heard the player before
		var total = 0.0; var w = []
		for i in pts.size():
			var x = 1.0 + min(4.0, heat.get(i, 0) * 0.5)
			if (pts[i] - global_transform.origin).length() < 3.0: x = 0.05
			w.append(x); total += x
		var r = _rng.randf() * total; var pick = 0
		for i in w.size():
			r -= w[i]
			if r <= 0:
				pick = i; break
		target = pts[pick]
	route = level.path(global_transform.origin, target)

func _next_search():
	_check_hide = null
	# lockers near the last known position are checked more often the more the player has used them
	for e in level.ents:
		if e.kind != "hide" or (e.pos - last_known).length() > 9.0: continue
		var uses = int(G.flags.get("m_hide_" + e.uid, 0))
		var p = 1.0 if e == _saw_hide else min(0.7, 0.08 + 0.18 * max(0, uses - 1))
		if _rng.randf() < p:
			_check_hide = e; target = e.pos; break
	if _check_hide == null: target = level.random_floor_near(last_known, 6.0)
	route = level.path(global_transform.origin, target)

func _can_see() -> bool:
	var me = global_transform.origin; var pp = player.global_transform.origin
	var to = pp - me; to.y = 0
	var d = to.length()
	if player.hidden: return false
	if blind: return d < 1.2
	var rng = 8.0
	if player.light_on: rng += 7.0
	if player.crouching: rng *= 0.55
	if st == S.HUNT: rng += 4.0
	if not level.power_on and not player.light_on: rng *= 0.7
	if d > rng: return false
	var fwd = -global_transform.basis.z
	if st != S.HUNT and d > 2.0 and fwd.dot(to.normalized()) < 0.15: return false
	return level.los(me, pp)

func _observed() -> bool:
	# is the player looking straight at it? (used by STALK: it freezes while watched)
	var to = global_transform.origin - player.global_transform.origin; to.y = 0
	return (-player.global_transform.basis.z).dot(to.normalized()) > 0.75 and level.los(global_transform.origin, player.global_transform.origin)

func _physics_process(dt):
	if level.dead: return
	st_t += dt; _mimic_cd -= dt
	var me = global_transform.origin; var pp = player.global_transform.origin
	var dist = (pp - me).length()
	sees = _can_see() and not passive
	if sees:
		last_known = pp; lost_t = 0.0
		alert = min(1.0, alert + dt * clamp(1.5 - dist / 9.0, 0.25, 1.4) * (1.6 if player.sprinting else 1.0))
	else:
		lost_t += dt
		alert = max(0.0, alert - dt * 0.05)
	var speed = SPEED[st]
	match st:
		S.DORMANT:
			if not passive and (alert > 0.5 or st_t > 25.0): _go(S.PATROL)
		S.PATROL:
			if alert >= 1.0: _go(S.HUNT)
			elif sees and alert > 0.35: _go(S.STALK)
			elif route.size() == 0:
				# sometimes it waits; sometimes it sets a trap where the player keeps going
				if int(G.flags.get("m_hunts", 0)) > 1 and _rng.randf() < 0.25: _go(S.AMBUSH)
				elif _rng.randf() < 0.3: _go(S.DORMANT)
				else: _next_patrol()
		S.INVESTIGATE:
			if alert >= 1.0 and sees: _go(S.HUNT)
			elif route.size() == 0:
				if passive:
					_go(S.DORMANT); passive = true
				else: _go(S.SEARCH)
		S.SEARCH:
			if alert >= 1.0 and sees: _go(S.HUNT)
			elif route.size() == 0:
				if _check_hide != null and player.hidden and player.hide_ent == _check_hide:
					_drag_out(); return
				_search_left -= 1
				if _search_left <= 0: _go(S.STALK if alert > 0.4 else S.PATROL)
				else: _next_search()
		S.STALK:
			if alert >= 1.0 and sees and (dist < 7.0 or player.light_on): _go(S.HUNT)   # never shine the light on it
			elif _observed() and dist > 2.5:
				speed = 0.0     # it does not move while you are looking at it
			else:
				_repath -= dt
				if _repath <= 0:
					_repath = 1.0
					route = level.path(me, last_known) if dist > 6.0 else []
				if _mimic_cd <= 0 and dist < 16.0 and level.running == 0 and not ui.in_cine:
					_mimic_cd = _rng.randf_range(22.0, 40.0)
					var m = MIMIC[_rng.randi() % MIMIC.size()]
					Snd.play3d("whisper", level, me + Vector3(0, 2, 0), 6, 0.8)
					ui.say(m[0], m[1])
			if st_t > 22.0: _go(S.AMBUSH if _rng.randf() < 0.4 else S.RETREAT)
		S.HUNT:
			_repath -= dt
			if _repath <= 0:
				_repath = 0.35
				route = level.path(me, pp if sees else last_known)
			if dist < 1.25 and not player.hidden and level.los(me, pp):
				_attack()
				return
			if player.hidden and _saw_hide == player.hide_ent and (me - player.hide_ent.pos).length() < 1.8:
				_drag_out(); return
			if lost_t > 4.5: _go(S.SEARCH)
			if st_t > 40.0: _go(S.RETREAT)   # fairness valve: no endless chases
		S.AMBUSH:
			if route.size() == 0:
				speed = 0.0
				if dist < 3.6 and level.los(me, pp) and not player.hidden: _go(S.HUNT)
				elif st_t > 26.0: _go(S.PATROL)
		S.RETREAT:
			if route.size() == 0: _go(S.DORMANT)
	_move(dt, speed)
	_animate(dt, speed)
	# presence audio
	snd.pitch_scale = [0.5, 0.8, 1.0, 1.0, 0.6, 1.6, 0.4, 0.8][st]
	snd.unit_db = [-12, 0, 2, 2, -6, 6, -30, 0][st]
	# visibility (cloaked variants can only be seen on 107.9 or at arm's length)
	body.visible = not cloaked or level.reveal_on or dist < 2.2

func _move(dt: float, speed: float):
	if route.size() == 0 or speed <= 0.0: return
	var me = global_transform.origin
	var nxt = route[0]; nxt.y = me.y
	var d = nxt - me
	if d.length() < 0.25:
		route.pop_front(); return
	# open unlocked doors in the way (noisy - the player can hear it coming)
	for e in level.by_char.get("__doors", []):
		if not e.open and not e.locked and (e.pos - me).length() < 2.4: level._door_open(e)
	if level.solid_at(me + d.normalized() * 0.9):
		var c = level.cell_of(me + d.normalized() * 0.9)
		var blocked = false
		for e in level.by_char.get("__doors", []):
			if e.cell == c and not e.open: blocked = true
		if blocked:
			route = []; return
	translation += d.normalized() * min(speed * dt, d.length())
	var ty = atan2(-d.x, -d.z)
	rotation.y = lerp_angle(rotation.y, ty, 6.0 * dt)
	_step += speed * dt
	if _step > 1.5:
		_step = 0.0
		Snd.play3d("step", level, me, 4 if st == S.HUNT else -2, 0.55, 22)

func _animate(dt: float, speed: float):
	_anim += dt * (2.0 + speed * 2.2)
	var sw = sin(_anim) * (0.12 + speed * 0.12)
	body.get_node("leg_l").rotation.x = sw; body.get_node("leg_r").rotation.x = -sw
	body.get_node("arm_l").rotation.x = -sw * 0.7 - (0.9 if st == S.HUNT else 0.0)
	body.get_node("arm_r").rotation.x = sw * 0.7 - (0.9 if st == S.HUNT else 0.0)
	body.translation.y = abs(sin(_anim)) * 0.03
	# the dish tilts toward whatever it is listening to
	var neck = body.get_node("neck")
	var want = 0.0
	if st in [S.INVESTIGATE, S.SEARCH, S.DORMANT, S.AMBUSH]: want = sin(_anim * 0.35) * 0.9
	neck.rotation.y = lerp(neck.rotation.y, want, 3 * dt)
	neck.rotation.z = lerp(neck.rotation.z, 0.5 if st == S.STALK else 0.0, 2 * dt)
	var pit = neck.get_node("pit").material_override
	pit.emission_enabled = st == S.HUNT or st == S.STALK
	pit.emission = Color(0.9, 0.08, 0.04); pit.emission_energy = 1.4 if st == S.HUNT else 0.3

func _attack():
	player.hurt(55.0)
	Snd.play("glitch", 2)
	if not level.dead:
		ui.toast("It lets go. This time.")
		_go(S.RETREAT)

func _drag_out():
	Snd.play3d("metal", level, global_transform.origin, 6, 0.7)
	player.toggle_hide(player.hide_ent)
	_saw_hide = null
	_attack()
