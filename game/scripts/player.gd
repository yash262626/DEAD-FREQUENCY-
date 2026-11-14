extends KinematicBody
# First-person controller: walk / sprint / crouch / lean, stamina, flashlight,
# interaction ray, hiding, health, throwing, rigid-body pushing.

const WALK := 2.7
const SPRINT := 5.3
const CROUCH := 1.3

var level
var ui
var head: Spatial
var cam: Camera
var lamp: SpotLight
var ray: RayCast
var shape: CapsuleShape
var vel := Vector3()
var pitch := 0.0
var stamina := 100.0
var health := 100.0
var crouching := false
var sprinting := false
var light_on := false
var locked := false
var hidden := false
var hide_ent = null
var shake := 0.0
var lean := 0.0
var _step_acc := 0.0
var _bob := 0.0
var _winded := false
var _pre_hide: Vector3
var moving_speed := 0.0
var in_water := false
var _hurt_cd := 0.0
var sprint_recent := 0.0     # seconds since the player last sprinted (for the Listener's habit memory)

func setup(lv, u):
	level = lv; ui = u
	health = G.health
	collision_layer = 4; collision_mask = 1
	var cs = CollisionShape.new(); shape = CapsuleShape.new(); shape.radius = 0.34; shape.height = 1.05
	cs.shape = shape; cs.rotation_degrees.x = 90; cs.translation.y = 0.87; cs.name = "Col"; add_child(cs)
	head = Spatial.new(); head.translation.y = 1.62; add_child(head)
	cam = Camera.new(); cam.near = 0.06; cam.far = 120; cam.current = true; head.add_child(cam)
	lamp = SpotLight.new(); lamp.spot_range = 22; lamp.spot_angle = 26; lamp.spot_attenuation = 0.7; lamp.spot_angle_attenuation = 0.6
	lamp.light_energy = 0.0; lamp.light_color = Color(1.0, 0.95, 0.85); lamp.shadow_enabled = true; lamp.shadow_bias = 0.9
	lamp.translation = Vector3(0.21, -0.17, -0.2); cam.add_child(lamp)
	ray = RayCast.new(); ray.cast_to = Vector3(0, 0, -2.7); ray.collision_mask = 3; ray.enabled = true; cam.add_child(ray)
	var listener3d = Listener.new(); cam.add_child(listener3d); listener3d.make_current()
	if Mats.enabled(): load("res://scripts/fx.gd").dust(cam)
	_build_hands()
	apply_quality()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# ---------------------------------------------------------------- first-person hands
var hands: Spatial
var radio_model: Spatial
var light_model: Spatial
var _lens: SpatialMaterial
var _screen: SpatialMaterial
var _sway := Vector2()
var _reach := 0.0

func _hm(col: Color, emis := 0.0, rough := 0.8, metal := 0.0) -> SpatialMaterial:
	# the rig is scaled to 60 % and kept within ~0.25 m of the camera, inside the 0.34 m body radius, so it never clips walls
	var m = SpatialMaterial.new(); m.albedo_color = col; m.roughness = rough; m.metallic = metal
	if emis > 0.0:
		m.emission_enabled = true; m.emission = col; m.emission_energy = emis
	return m

func _part(parent: Node, mesh: Mesh, m: Material, pos: Vector3, rot := Vector3()) -> MeshInstance:
	var mi = MeshInstance.new(); mi.mesh = mesh; mi.material_override = m; mi.translation = pos; mi.rotation_degrees = rot
	mi.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi

func _cyl(r1: float, r2: float, h: float) -> CylinderMesh:
	var c = CylinderMesh.new(); c.top_radius = r1; c.bottom_radius = r2; c.height = h; c.radial_segments = 12; c.rings = 1
	return c

func _cube(s: Vector3) -> CubeMesh:
	var c = CubeMesh.new(); c.size = s
	return c

func _build_hands():
	hands = Spatial.new(); hands.name = "hands"; cam.add_child(hands)
	hands.scale = Vector3(0.6, 0.6, 0.6)
	var sleeve = _hm(Color(0.62, 0.24, 0.06), 0, 0.9)          # Northline orange
	var cuff = _hm(Color(0.2, 0.2, 0.22), 0, 0.9)
	var glove = _hm(Color(0.09, 0.09, 0.1), 0, 0.85)
	var metal = _hm(Color(0.16, 0.17, 0.18), 0, 0.35, 0.7)
	# right hand: the torch
	light_model = Spatial.new(); light_model.translation = Vector3(0.21, -0.2, -0.34); hands.add_child(light_model)
	_part(light_model, _cyl(0.045, 0.05, 0.3), sleeve, Vector3(0.03, -0.05, 0.2), Vector3(70, 0, 0))
	_part(light_model, _cyl(0.05, 0.05, 0.05), cuff, Vector3(0.025, -0.01, 0.07), Vector3(70, 0, 0))
	_part(light_model, _cube(Vector3(0.075, 0.07, 0.09)), glove, Vector3(0.01, 0.0, 0.0))
	_part(light_model, _cyl(0.022, 0.018, 0.2), metal, Vector3(0, 0.03, -0.06), Vector3(90, 0, 0))
	_lens = _hm(Color(1.0, 0.95, 0.8), 0.0)
	_part(light_model, _cyl(0.027, 0.027, 0.02), _lens, Vector3(0, 0.03, -0.165), Vector3(90, 0, 0))
	# left hand: the HX-7 receiver
	radio_model = Spatial.new(); radio_model.translation = Vector3(-0.2, -0.62, -0.36); hands.add_child(radio_model)
	_part(radio_model, _cyl(0.045, 0.05, 0.3), sleeve, Vector3(-0.04, -0.12, 0.17), Vector3(55, 0, 10))
	_part(radio_model, _cube(Vector3(0.13, 0.19, 0.05)), _hm(Color(0.2, 0.24, 0.2), 0, 0.6, 0.3), Vector3(0, 0, 0))
	_screen = _hm(Color(0.35, 1.0, 0.5), 1.4)
	_part(radio_model, _cube(Vector3(0.09, 0.035, 0.005)), _screen, Vector3(0, 0.055, -0.026))
	_part(radio_model, _cyl(0.018, 0.018, 0.012), metal, Vector3(0.035, -0.02, -0.028), Vector3(90, 0, 0))
	_part(radio_model, _cyl(0.004, 0.004, 0.24), metal, Vector3(0.05, 0.2, 0.0))
	_part(radio_model, _cube(Vector3(0.08, 0.1, 0.07)), glove, Vector3(-0.02, -0.08, 0.02))

func _animate_hands(dt: float):
	if hands == null: return
	hands.visible = not ui.in_cine and not hidden
	var radio_on = level.radio != null and level.radio.on and G.has_radio
	var ry = -0.24 if radio_on else -0.62
	radio_model.translation.y = lerp(radio_model.translation.y, ry, min(1.0, 9 * dt))
	radio_model.visible = radio_model.translation.y > -0.58
	_lens.emission_enabled = light_on
	_lens.emission = Color(1.0, 0.95, 0.8); _lens.emission_energy = 3.0
	_screen.emission_energy = 1.0 + (level.radio.sig * 1.5 if radio_on else 0.0)
	# sway: hands lag behind the view and bob with the stride
	_sway = _sway.linear_interpolate(Vector2(), min(1.0, 6 * dt))
	_reach = max(0.0, _reach - dt * 4.0)
	var bob = Vector3(cos(_bob) * 0.008, sin(_bob * 2.0) * 0.01, 0) if moving_speed > 0.5 else Vector3()
	hands.translation = hands.translation.linear_interpolate(Vector3(-_sway.x * 0.03, _sway.y * 0.03, -_reach * 0.06) + bob, min(1.0, 12 * dt))
	hands.rotation.z = lerp(hands.rotation.z, -lean * 0.15 + (rand_range(-1, 1) * shake * 0.05), min(1.0, 10 * dt))

func apply_quality():
	cam.fov = G.settings.fov
	lamp.shadow_enabled = int(G.settings.quality) >= 1

func _busy() -> bool:
	return locked or ui.modal != null or level.dead

func _input(ev):
	if _busy(): return
	if ev is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_look(ev.relative * 0.0022 * G.settings.sens)

func _look(d: Vector2):
	_sway += d * 6.0
	if hidden: d *= 0.4
	rotation.y -= d.x
	pitch = clamp(pitch - d.y * (-1.0 if G.settings.invert_y else 1.0), -1.45, 1.45)
	head.rotation.x = pitch

func look_at_point(p: Vector3):
	# cinematic head turn
	var d = p - head.global_transform.origin
	var ty = atan2(-d.x, -d.z); var tp = atan2(d.y, Vector2(d.x, d.z).length())
	if G.skip:
		rotation.y = ty; pitch = tp; head.rotation.x = pitch
		yield(get_tree(), "idle_frame")
		return
	var tw = Tween.new(); add_child(tw)
	var dy = wrapf(ty - rotation.y, -PI, PI)
	tw.interpolate_property(self, "rotation:y", rotation.y, rotation.y + dy, 0.7, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tw.interpolate_property(self, "pitch", pitch, tp, 0.7, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tw.start()
	yield(tw, "tween_all_completed")
	tw.queue_free()

func _process(dt):
	head.rotation.x = pitch
	_animate_hands(dt)
	_hurt_cd = max(0.0, _hurt_cd - dt)
	# flashlight
	if light_on:
		G.battery -= dt * (100.0 / 260.0)
		if G.battery <= 0:
			if G.has("battery"):
				G.take("battery"); G.battery = 100.0; ui.toast("Flashlight cell replaced.")
			else:
				light_on = false; G.battery = 0; Snd.play("click", 0, 0.7)
	var target_e = 0.0
	if light_on: target_e = 2.6 * (1.0 if G.battery > 12 else (0.5 + 0.5 * randf()))
	lamp.light_energy = lerp(lamp.light_energy, target_e, 0.4)
	ui.stat.hp = health; ui.stat.batt = G.battery; ui.stat.stam = stamina; ui.stat.light = light_on
	ui.stat.cells = int(G.inv.get("battery", 0)); ui.stat.hidden = hidden
	if health < 40: Snd.loop("heart", "heart", -6.0 - health * 0.2, 1.0 + (40 - health) * 0.01)
	else: Snd.unloop("heart")
	if _busy() or ui.closed_this_frame():
		ui.prompt(""); return
	# gamepad look
	var jl = Vector2(Input.get_action_strength("look_r") - Input.get_action_strength("look_l"),
		Input.get_action_strength("look_d") - Input.get_action_strength("look_u"))
	if jl.length() > 0.05: _look(jl * dt * 2.6 * G.settings.sens)
	if Input.is_action_just_pressed("light") and G.has_light:
		if not light_on and G.battery <= 0 and not G.has("battery"): ui.toast("Flashlight cell is dead.")
		else:
			light_on = not light_on; Snd.play("click", -2, 1.2); level.noise(global_transform.origin, 2.0, "click")
	if Input.is_action_just_pressed("heal") and G.has("medkit") and health < 100:
		G.take("medkit"); health = min(100.0, health + 60.0); Snd.play("pickup", -4, 0.8); ui.toast("Medkit used.")
	if Input.is_action_just_pressed("throw") and not hidden:
		if G.has("bottle"): _throw()
		else: ui.toast("Nothing to throw.")
	if Input.is_action_just_pressed("journal"): ui.journal_screen()
	if Input.is_action_just_pressed("pause"): ui.pause_menu()
	# interaction
	var e = null
	if hidden: e = hide_ent
	elif ray.is_colliding():
		var c = ray.get_collider()
		if c and c.has_meta("ent"): e = c.get_meta("ent")
	var p = level.prompt_for(e)
	ui.prompt(("[F]  " + p) if p != "" else "")
	if p != "" and Input.is_action_just_pressed("interact"):
		_reach = 1.0
		level.interact(e)

func _physics_process(dt):
	if level.dead: return
	var busy = _busy() or hidden
	var inp = Vector2()
	if not busy:
		inp = Vector2(Input.get_action_strength("right") - Input.get_action_strength("left"),
			Input.get_action_strength("back") - Input.get_action_strength("fwd"))
		if inp.length() > 1: inp = inp.normalized()
		if G.settings.toggle_crouch:
			if Input.is_action_just_pressed("crouch"): crouching = not crouching
		else: crouching = Input.is_action_pressed("crouch")
	# crouch / stand
	var th = 0.95 if crouching else 1.62
	head.translation.y = lerp(head.translation.y, th, 10 * dt)
	shape.height = 0.4 if crouching else 1.05
	$Col.translation.y = 0.54 if crouching else 0.87
	# lean
	var tl = 0.0
	if not busy: tl = Input.get_action_strength("lean_r") - Input.get_action_strength("lean_l")
	lean = lerp(lean, tl, 8 * dt)
	head.translation.x = lean * 0.42; head.rotation.z = -lean * 0.22
	# sprint / stamina
	sprinting = not busy and Input.is_action_pressed("sprint") and inp.y < -0.2 and not crouching and not _winded
	sprint_recent = max(0.0, sprint_recent - dt)
	if sprinting:
		sprint_recent = 5.0
		stamina -= dt * 16.0
		if stamina <= 0:
			stamina = 0; _winded = true
	else:
		stamina = min(100.0, stamina + dt * (9.0 if inp.length() > 0.1 else 15.0))
		if _winded and stamina > 30: _winded = false
	if _winded: Snd.loop("breath", "breath", -8)
	else: Snd.unloop("breath")
	in_water = level.pal.has("water")
	var sp = SPRINT if sprinting else (CROUCH if crouching else WALK)
	if in_water: sp *= 0.72
	if health < 35: sp *= 0.85
	var dir = (global_transform.basis.x * inp.x + global_transform.basis.z * inp.y)
	dir.y = 0
	var tv = dir * sp
	vel.x = lerp(vel.x, tv.x, 12 * dt); vel.z = lerp(vel.z, tv.z, 12 * dt)
	vel.y = vel.y - 18.0 * dt if not is_on_floor() else -0.5
	if hidden:
		vel = Vector3(); moving_speed = 0.0
		return
	vel = move_and_slide(vel, Vector3.UP, true, 4, 0.8, false)
	for i in get_slide_count():
		var col = get_slide_collision(i)
		if col.collider is RigidBody:
			col.collider.apply_central_impulse(-col.normal * 2.4)
	moving_speed = Vector2(vel.x, vel.z).length()
	# footsteps → sound + noise the Listener can hear
	if moving_speed > 0.5 and is_on_floor():
		_step_acc += moving_speed * dt
		if _step_acc > (1.9 if not sprinting else 2.3):
			_step_acc = 0.0
			var loud = 12.5 if sprinting else (1.3 if crouching else 5.0)
			if in_water: loud *= 1.5
			Snd.play("step_wet" if in_water else "step", -14 if crouching else (-4 if sprinting else -9), rand_range(0.85, 1.15))
			level.noise(global_transform.origin, loud, "step")
		if G.settings.head_bob:
			_bob += moving_speed * dt * 3.2
			cam.translation.y = sin(_bob * 2.0) * 0.022; cam.translation.x = cos(_bob) * 0.014
	if shake > 0.0:
		shake = max(0.0, shake - dt)
		cam.rotation.z = rand_range(-1, 1) * shake * 0.05
		cam.translation.x += rand_range(-1, 1) * shake * 0.03
	else: cam.rotation.z = 0
	if global_transform.origin.y < -20: hurt(999)

func _throw():
	G.take("bottle")
	G.flags["m_bottles"] = int(G.flags.get("m_bottles", 0)) + 1
	var rb = RigidBody.new(); rb.mass = 0.4; rb.contact_monitor = true; rb.contacts_reported = 1
	var cs = CollisionShape.new(); var sh = SphereShape.new(); sh.radius = 0.07; cs.shape = sh; rb.add_child(cs)
	var mi = MeshInstance.new(); var cm = CylinderMesh.new(); cm.top_radius = 0.03; cm.bottom_radius = 0.045; cm.height = 0.22
	mi.mesh = cm; mi.material_override = level.Props.mat(Color(0.3, 0.6, 0.35, 0.7)); rb.add_child(mi)
	level.add_child(rb)
	rb.global_transform.origin = cam.global_transform.origin - cam.global_transform.basis.z * 0.5
	rb.linear_velocity = -cam.global_transform.basis.z * 11.0 + Vector3(0, 2.5, 0)
	rb.connect("body_entered", self, "_bottle_hit", [rb])
func _bottle_hit(_b, rb):
	if not is_instance_valid(rb) or rb.has_meta("hit"): return
	rb.set_meta("hit", true)
	var p = rb.global_transform.origin
	Snd.play3d("metal", level, p, 4, 1.8)
	level.noise(p, 16.0, "object")
	yield(get_tree().create_timer(1.5, false), "timeout")
	if is_instance_valid(rb): rb.queue_free()

func toggle_hide(e):
	if hidden:
		hidden = false; hide_ent = null
		global_transform.origin = _pre_hide
		Snd.play("door", -8, 1.6); level.noise(global_transform.origin, 4.0, "door")
	else:
		_pre_hide = global_transform.origin
		hidden = true; hide_ent = e; crouching = false
		light_on = false
		var n = e.node
		global_transform.origin = n.global_transform.origin
		rotation.y = n.rotation.y; pitch = 0
		Snd.play("door", -8, 1.8); level.noise(global_transform.origin, 4.0, "door")
		var k = "m_hide_" + e.uid
		G.flags[k] = int(G.flags.get(k, 0)) + 1
		if level.listener and is_instance_valid(level.listener): level.listener.player_hid(e)

func hurt(amount: float):
	if _hurt_cd > 0 or level.dead or G.test_god: return
	_hurt_cd = 1.5
	health -= amount; shake = 0.7
	Snd.play("impact", -2, 1.6)
	if health <= 0:
		health = 0; level.dead = true
		Snd.unloop("heart"); Snd.unloop("breath")
		level.main.on_death()
