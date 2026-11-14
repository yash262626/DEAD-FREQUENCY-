extends Spatial
# Builds a chapter from data (ASCII map + legend), owns entities, events,
# interaction, checkpoints, noise propagation and the cinematic camera.

const Props = preload("res://scripts/props.gd")
const Fx = preload("res://scripts/fx.gd")
const C := 2.0   # cell size in metres

const PALETTES = {
	"entrance": {"floor": Color(0.23, 0.24, 0.24), "wall": Color(0.36, 0.37, 0.36), "trim": Color(0.5, 0.42, 0.12), "ceil": Color(0.18, 0.18, 0.18), "fog": Color(0.05, 0.06, 0.07), "fog_end": 38, "amb": Color(0.35, 0.4, 0.5), "amb_e": 0.32, "light": Color(1.0, 0.9, 0.75), "h": 3.2, "tex": ["Concrete046", "Concrete047A", "Concrete034", "PaintedPlaster017"]},
	"security": {"floor": Color(0.2, 0.21, 0.22), "wall": Color(0.33, 0.35, 0.37), "trim": Color(0.16, 0.24, 0.34), "ceil": Color(0.16, 0.16, 0.17), "fog": Color(0.04, 0.05, 0.06), "fog_end": 34, "amb": Color(0.35, 0.42, 0.55), "amb_e": 0.28, "light": Color(0.85, 0.92, 1.0), "h": 3.0, "tex": ["PaintedPlaster017", "Tiles043", "PaintedPlaster006", "MetalPlates006"]},
	"medical": {"floor": Color(0.42, 0.45, 0.43), "wall": Color(0.6, 0.63, 0.6), "trim": Color(0.3, 0.5, 0.45), "ceil": Color(0.5, 0.5, 0.48), "fog": Color(0.07, 0.09, 0.08), "fog_end": 36, "amb": Color(0.45, 0.6, 0.55), "amb_e": 0.3, "light": Color(0.85, 1.0, 0.92), "h": 3.0, "tex": ["Tiles141", "Tiles043", "PaintedPlaster006", "PaintedPlaster017"]},
	"residential": {"floor": Color(0.3, 0.24, 0.2), "wall": Color(0.5, 0.45, 0.36), "trim": Color(0.36, 0.2, 0.15), "ceil": Color(0.3, 0.28, 0.25), "fog": Color(0.07, 0.05, 0.04), "fog_end": 32, "amb": Color(0.6, 0.45, 0.3), "amb_e": 0.26, "light": Color(1.0, 0.8, 0.55), "h": 2.8, "tex": ["PaintedPlaster006", "Wood096", "PaintedPlaster006", "Wood096"]},
	"power": {"floor": Color(0.2, 0.19, 0.17), "wall": Color(0.3, 0.27, 0.22), "trim": Color(0.6, 0.45, 0.08), "ceil": Color(0.12, 0.12, 0.12), "fog": Color(0.07, 0.05, 0.03), "fog_end": 40, "amb": Color(0.6, 0.4, 0.2), "amb_e": 0.25, "light": Color(1.0, 0.72, 0.4), "h": 5.0, "tex": ["Concrete046", "MetalWalkway014", "Concrete034", "Metal063"]},
	"flooded": {"floor": Color(0.14, 0.17, 0.16), "wall": Color(0.2, 0.26, 0.25), "trim": Color(0.12, 0.2, 0.18), "ceil": Color(0.1, 0.12, 0.12), "fog": Color(0.03, 0.07, 0.07), "fog_end": 24, "amb": Color(0.2, 0.5, 0.5), "amb_e": 0.24, "light": Color(0.6, 1.0, 0.9), "h": 2.8, "water": 0.45, "tex": ["Concrete049", "Tiles084", "Concrete046", "Metal063"]},
	"comms": {"floor": Color(0.16, 0.17, 0.2), "wall": Color(0.25, 0.27, 0.32), "trim": Color(0.1, 0.3, 0.2), "ceil": Color(0.1, 0.1, 0.12), "fog": Color(0.03, 0.05, 0.05), "fog_end": 34, "amb": Color(0.3, 0.55, 0.45), "amb_e": 0.26, "light": Color(0.7, 1.0, 0.85), "h": 3.6, "tex": ["PaintedPlaster017", "Rubber004", "PaintedPlaster006", "MetalPlates006"]},
	"lab": {"floor": Color(0.5, 0.52, 0.54), "wall": Color(0.7, 0.72, 0.74), "trim": Color(0.2, 0.4, 0.6), "ceil": Color(0.6, 0.6, 0.6), "fog": Color(0.08, 0.1, 0.12), "fog_end": 40, "amb": Color(0.55, 0.65, 0.8), "amb_e": 0.3, "light": Color(0.9, 0.96, 1.0), "h": 3.4, "tex": ["Tiles141", "Tiles043", "PaintedPlaster006", "PaintedPlaster017"]},
	"transport": {"floor": Color(0.15, 0.15, 0.15), "wall": Color(0.24, 0.23, 0.22), "trim": Color(0.6, 0.5, 0.1), "ceil": Color(0.08, 0.08, 0.08), "fog": Color(0.04, 0.04, 0.04), "fog_end": 44, "amb": Color(0.45, 0.42, 0.35), "amb_e": 0.22, "light": Color(1.0, 0.85, 0.5), "h": 4.0, "tex": ["Concrete046", "Concrete049", "Concrete034", "Metal063"]},
	"containment": {"floor": Color(0.12, 0.12, 0.13), "wall": Color(0.18, 0.18, 0.2), "trim": Color(0.5, 0.08, 0.06), "ceil": Color(0.07, 0.07, 0.08), "fog": Color(0.06, 0.02, 0.02), "fog_end": 26, "amb": Color(0.6, 0.25, 0.2), "amb_e": 0.24, "light": Color(1.0, 0.45, 0.35), "h": 3.4, "tex": ["MetalPlates006", "MetalWalkway014", "MetalPlates006", "Metal063"]},
	"archive": {"floor": Color(0.22, 0.2, 0.17), "wall": Color(0.33, 0.3, 0.25), "trim": Color(0.2, 0.16, 0.1), "ceil": Color(0.14, 0.13, 0.11), "fog": Color(0.06, 0.055, 0.04), "fog_end": 30, "amb": Color(0.55, 0.5, 0.35), "amb_e": 0.26, "light": Color(1.0, 0.88, 0.6), "h": 4.2, "tex": ["PaintedPlaster017", "Concrete047A", "PaintedPlaster006", "Wood096"]},
	"chamber": {"floor": Color(0.1, 0.11, 0.13), "wall": Color(0.16, 0.18, 0.22), "trim": Color(0.5, 0.15, 0.1), "ceil": Color(0.05, 0.05, 0.06), "fog": Color(0.03, 0.04, 0.07), "fog_end": 60, "amb": Color(0.3, 0.4, 0.7), "amb_e": 0.38, "light": Color(0.7, 0.8, 1.0), "h": 7.0, "tex": ["MetalPlates006", "MetalWalkway014", "Concrete046", "Metal063"]},
}
const CMDS = ["wait", "obj", "flag", "sfx", "music", "lights", "card", "title", "fade", "cine", "cam", "camoff", "give", "take",
	"checkpoint", "next", "ending", "choice", "if", "ifnot", "unlock", "listener", "hurt", "shake", "toast", "journal", "look",
	"text", "monitor", "tp", "loop", "unloop", "credits", "menu", "ach", "radio_on", "reveal", "hide_ent", "show_ent", "ext", "save", "lock", "pulse", "noise_mult", "close", "loop3d", "unloop3d", "group", "move"]
const BUILTIN = {
	"S": {"t": "start"}, "L": {"t": "light"}, "F": {"t": "light", "flicker": true}, "R": {"t": "light", "red": true},
	"P": {"t": "patrol"}, "H": {"t": "hide"}, "V": {"t": "save"}, "D": {"t": "door"},
}

var data: Dictionary
var main
var ui
var player
var listener = null
var radio
var grid := []
var gw := 0
var gh := 0
var pal: Dictionary
var astar := AStar2D.new()
var ents := []
var markers := {}
var by_char := {}
var lights := []
var env: Environment
var cine_cam: Camera
var ext = null
var ext_points := {}
var power_on := true
var reveal_on := false
var force_reveal := false
var _rng := RandomNumberGenerator.new()
var _cam_tw: Tween
var running := 0
var dead := false
var noise_mult := 1.0
var _walkers := []
var _loops3d := {}
var _outside := false

# ---------------------------------------------------------------- static helpers
static func legend_of(data: Dictionary, ch: String):
	if data.leg.has(ch): return data.leg[ch]
	if BUILTIN.has(ch): return BUILTIN[ch]
	return null

func cell_of(p: Vector3) -> Vector2:
	return Vector2(floor(p.x / C), floor(p.z / C))
func center(cx: int, cz: int) -> Vector3:
	return Vector3((cx + 0.5) * C, 0, (cz + 0.5) * C)
func is_floor(cx: int, cz: int) -> bool:
	if cx < 0 or cz < 0 or cz >= gh or cx >= gw: return false
	var ch = grid[cz][cx]
	return ch != "#" and ch != " "
func pid(cx: int, cz: int) -> int:
	return cz * gw + cx

func solid_at(p: Vector3) -> bool:
	var c = cell_of(p)
	if not is_floor(int(c.x), int(c.y)): return true
	for e in by_char.get("__doors", []):
		if not e.open and e.cell == c: return true
	return false

func los(a: Vector3, b: Vector3) -> bool:
	var d = b - a; d.y = 0
	var n = int(d.length() / 0.5) + 1
	for i in range(1, n):
		if solid_at(a + d * (float(i) / n)): return false
	return true

func pos_of(name: String) -> Vector3:
	if name.begins_with("@"): return ext_points.get(name, Vector3())
	if markers.has(name): return markers[name][0]
	push_warning("marker not found: " + name)
	return Vector3()

func path(a: Vector3, b: Vector3) -> Array:
	var ca = cell_of(a); var cb = cell_of(b)
	var ia = pid(int(ca.x), int(ca.y)); var ib = pid(int(cb.x), int(cb.y))
	if not astar.has_point(ia): ia = astar.get_closest_point(Vector2(ca.x, ca.y))
	if not astar.has_point(ib) or astar.is_point_disabled(ib): ib = astar.get_closest_point(Vector2(cb.x, cb.y))
	if ia < 0 or ib < 0: return []
	var out = []
	for p in astar.get_point_path(ia, ib): out.append(center(int(p.x), int(p.y)))
	return out

func random_floor_near(p: Vector3, radius: float) -> Vector3:
	for i in 20:
		var q = p + Vector3(_rng.randf_range(-radius, radius), 0, _rng.randf_range(-radius, radius))
		var c = cell_of(q)
		if is_floor(int(c.x), int(c.y)) and not solid_at(q): return center(int(c.x), int(c.y))
	return p

# ---------------------------------------------------------------- build
func build(d: Dictionary, main_ref, ui_ref):
	data = d; main = main_ref; ui = ui_ref
	_rng.seed = 9000 + int(d.n)
	pal = PALETTES[d.get("pal", "security")].duplicate()
	if d.has("h"): pal.h = d.h
	grid = d.map; gh = grid.size(); gw = 0
	for row in grid: gw = int(max(gw, row.length()))
	for i in gh:
		while grid[i].length() < gw: grid[i] += "#"
	_build_env()
	_build_geometry()
	_build_nav()
	_build_entities()
	if d.get("exterior", false):
		ext = load("res://scripts/exterior.gd").new(); add_child(ext)
		ext.translation = Vector3(0, 0, -600); ext.build(d.get("ext_mode", "storm"))
		for k in ext.points: ext_points["@" + k] = ext.translation + ext.points[k]
	cine_cam = Camera.new(); cine_cam.far = 400; add_child(cine_cam)
	_cam_tw = Tween.new(); add_child(_cam_tw)
	# player
	player = load("res://scripts/player.gd").new(); add_child(player)
	player.setup(self, ui)
	var sp = G.checkpoint if (G.checkpoint != "" and markers.has(G.checkpoint)) else "S"
	player.translation = pos_of(sp) + Vector3(0, 0.1, 0)
	if d.has("face"): player.rotation_degrees.y = d.face
	radio = load("res://scripts/radio.gd").new(); add_child(radio); radio.setup(self, ui, player)
	power_on = not d.get("dark", false) or G.flag("power%d" % d.n)
	_apply_power(true)
	G.connect("settings_changed", self, "_apply_quality")
	_apply_quality()
	_apply_ai()
	if d.has("amb_loop"): Snd.loop("amb", d.amb_loop, d.get("amb_db", -14.0))
	Snd.music(d.get("music", "drone_a"), -10)

func _exit_tree():
	Snd.unloop("amb"); Snd.unloop("static"); Snd.unloop("heart"); Snd.unloop("cine")

func _build_env():
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color(0, 0, 0)
	env.ambient_light_color = pal.amb; env.ambient_light_energy = pal.amb_e
	env.fog_enabled = true; env.fog_color = pal.fog; env.fog_depth_enabled = true
	env.fog_depth_begin = 2.0; env.fog_depth_end = pal.fog_end; env.fog_depth_curve = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC; env.tonemap_exposure = 1.1
	env.glow_enabled = true; env.glow_intensity = 0.6; env.glow_bloom = 0.08; env.glow_hdr_threshold = 0.9
	env.adjustment_enabled = true; env.adjustment_contrast = 1.08; env.adjustment_saturation = 0.9
	var we = WorldEnvironment.new(); we.environment = env; add_child(we)

func _env_mode(outside: bool):
	if outside == _outside: return
	_outside = outside
	if outside and ext:
		ext.apply_env(env)
	else:
		env.background_color = Color(0, 0, 0); env.fog_color = pal.fog
		env.fog_depth_begin = 2.0; env.fog_depth_end = pal.fog_end
		env.ambient_light_color = pal.amb
		_apply_power(true)

func _apply_ai():
	for s in data.get("ai", []):
		if _cond(s):
			spawn_listener(s.at, s.get("mode", "patrol"))
			break

func _apply_quality():
	var q = int(G.settings.quality)
	env.ssao_enabled = q >= 2; env.ssao_intensity = 1.5; env.ssao_radius = 1.2
	env.glow_enabled = q >= 1
	env.adjustment_brightness = G.settings.brightness
	env.ss_reflections_enabled = q >= 3
	for l in lights:
		l.node.shadow_enabled = q >= 2 and not l.d.get("noshadow", false)
	if player: player.apply_quality()

func _noise_tex(seed_: int, period: float, normal := false) -> NoiseTexture:
	var t = NoiseTexture.new(); var n = OpenSimplexNoise.new()
	n.seed = seed_; n.octaves = 4; n.period = period; n.persistence = 0.6
	t.noise = n; t.width = 256; t.height = 256; t.seamless = true
	t.as_normalmap = normal; t.bump_strength = 5.0
	return t

func _surf_mat(col: Color, seed_: int, rough: float, metal := 0.0) -> SpatialMaterial:
	var m = SpatialMaterial.new()
	m.albedo_color = col * 1.6; m.albedo_texture = _noise_tex(seed_, 40.0)
	m.normal_enabled = true; m.normal_texture = _noise_tex(seed_ + 1, 18.0, true); m.normal_scale = 0.7
	m.roughness = rough; m.metallic = metal
	m.uv1_triplanar = true; m.uv1_scale = Vector3(0.35, 0.35, 0.35)
	m.params_cull_mode = SpatialMaterial.CULL_DISABLED
	return m

func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3):
	# Godot front faces wind clockwise; keep winding consistent with the supplied normal
	if (c - a).cross(b - a).dot(n) < 0.0:
		var t = b; b = d; d = t
	for v in [a, b, c, a, c, d]:
		st.add_normal(n); st.add_vertex(v)

func _build_geometry():
	var h = float(pal.h)
	var st = {}
	for k in ["floor", "wall", "trim", "ceil"]:
		st[k] = SurfaceTool.new(); st[k].begin(Mesh.PRIMITIVE_TRIANGLES)
	var th = 1.0   # trim band height
	for cz in gh:
		for cx in gw:
			if not is_floor(cx, cz): continue
			var x0 = cx * C; var x1 = x0 + C; var z0 = cz * C; var z1 = z0 + C
			_quad(st.floor, Vector3(x0, 0, z0), Vector3(x1, 0, z0), Vector3(x1, 0, z1), Vector3(x0, 0, z1), Vector3.UP)
			_quad(st.ceil, Vector3(x0, h, z0), Vector3(x1, h, z0), Vector3(x1, h, z1), Vector3(x0, h, z1), Vector3.DOWN)
			var sides = [[cx - 1, cz, Vector3(x0, 0, z0), Vector3(x0, 0, z1), Vector3.RIGHT],
				[cx + 1, cz, Vector3(x1, 0, z0), Vector3(x1, 0, z1), Vector3.LEFT],
				[cx, cz - 1, Vector3(x0, 0, z0), Vector3(x1, 0, z0), Vector3.BACK],
				[cx, cz + 1, Vector3(x0, 0, z1), Vector3(x1, 0, z1), Vector3.FORWARD]]
			for s in sides:
				if is_floor(s[0], s[1]): continue
				var a = s[2]; var b = s[3]; var up = Vector3(0, 1, 0)
				_quad(st.trim, a, b, b + up * th, a + up * th, s[4])
				_quad(st.wall, a + up * th, b + up * th, b + up * h, a + up * h, s[4])
	var mats = {"floor": _surf_mat(pal.floor, 11, 0.55, 0.1), "wall": _surf_mat(pal.wall, 23, 0.85), "trim": _surf_mat(pal.trim, 37, 0.6, 0.3), "ceil": _surf_mat(pal.ceil, 41, 0.9)}
	if Mats.enabled() and pal.has("tex"):
		var tx = pal.tex
		mats = {"wall": Mats.surface(tx[0], Mats.hue_tint(pal.wall, 0.9), 0.5), "floor": Mats.surface(tx[1], Mats.hue_tint(pal.floor, 0.8), 0.5),
			"ceil": Mats.surface(tx[2], Mats.hue_tint(pal.ceil, 0.7), 0.5), "trim": Mats.surface(tx[3], Mats.hue_tint(pal.trim, 0.95), 0.5)}
		for k in mats: mats[k].params_cull_mode = SpatialMaterial.CULL_DISABLED
	var body = StaticBody.new(); body.name = "World"; add_child(body)
	for k in st:
		var mesh = st[k].commit()
		if mesh == null or mesh.get_surface_count() == 0: continue
		var mi = MeshInstance.new(); mi.mesh = mesh; mi.material_override = mats[k]; add_child(mi)
		var cs = CollisionShape.new(); cs.shape = mesh.create_trimesh_shape(); body.add_child(cs)
	# water
	if pal.has("water"):
		var wm = MeshInstance.new(); var pm = PlaneMesh.new(); pm.size = Vector2(gw * C, gh * C)
		wm.mesh = pm; wm.translation = Vector3(gw * C / 2, pal.water, gh * C / 2)
		var m = SpatialMaterial.new(); m.albedo_color = Color(0.05, 0.14, 0.13, 0.82); m.flags_transparent = true
		m.roughness = 0.08; m.metallic = 0.6; m.normal_enabled = true; m.normal_texture = _noise_tex(77, 30.0, true)
		m.uv1_scale = Vector3(gw / 3.0, gh / 3.0, 1)
		wm.material_override = m
		if Mats.enabled(): wm.material_override = Fx.water_material(_noise_tex(77, 24.0, true), _noise_tex(91, 13.0, true))
		add_child(wm); wm.name = "Water"
	# atmosphere: steam in the industrial levels, drips where there is water
	if Mats.enabled():
		var spots = 0
		for cz in gh:
			for cx in gw:
				if not is_floor(cx, cz) or grid[cz][cx] != "." or _wall_dir(cx, cz) == Vector3(): continue
				var roll = _rng.randf()
				var c0 = center(cx, cz)
				if data.get("pal", "") in ["power", "transport"] and roll < 0.025 and spots < 6:
					Fx.steam(self, c0 + _wall_dir(cx, cz) * 0.85 + Vector3(0, 0.3, 0)); spots += 1
				elif pal.has("water") and roll < 0.05 and spots < 10:
					Fx.drips(self, c0 + Vector3(0, pal.h - 0.05, 0), pal.h); spots += 1
	# automatic dressing: corridor pipes, conduits, debris
	var pipe = CylinderMesh.new(); pipe.top_radius = 0.07; pipe.bottom_radius = 0.07; pipe.height = C; pipe.radial_segments = 8
	var pm1 = Props.mat(Color(0.3, 0.2, 0.14), 0, 0.5, 0.6); var pm2 = Props.mat(Color(0.25, 0.27, 0.28), 0, 0.4, 0.7)
	for cz in gh:
		for cx in gw:
			if not is_floor(cx, cz): continue
			var we_ = not is_floor(cx - 1, cz) and not is_floor(cx + 1, cz)
			var ns = not is_floor(cx, cz - 1) and not is_floor(cx, cz + 1)
			var c = center(cx, cz)
			if we_ or ns:
				for i in 2:
					var mi = MeshInstance.new(); mi.mesh = pipe; mi.material_override = pm1 if i == 0 else pm2
					var off = 0.72 - i * 0.22
					if we_:
						mi.rotation_degrees.x = 90; mi.translation = c + Vector3(off, h - 0.18 - i * 0.05, 0)
					else:
						mi.rotation_degrees.z = 90; mi.translation = c + Vector3(0, h - 0.18 - i * 0.05, off)
					add_child(mi)
			elif grid[cz][cx] == "." and _rng.randf() < 0.035:
				var db = Props.make("debris"); db.translation = c; add_child(db)

func _build_nav():
	for cz in gh:
		for cx in gw:
			if is_floor(cx, cz): astar.add_point(pid(cx, cz), Vector2(cx, cz))
	for cz in gh:
		for cx in gw:
			if not is_floor(cx, cz): continue
			if is_floor(cx + 1, cz): astar.connect_points(pid(cx, cz), pid(cx + 1, cz))
			if is_floor(cx, cz + 1): astar.connect_points(pid(cx, cz), pid(cx, cz + 1))

func _wall_dir(cx: int, cz: int) -> Vector3:
	# direction from the cell centre toward an adjacent wall (zero if open)
	for d in [Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(1, 0, 0), Vector3(0, 0, 1)]:
		if not is_floor(cx + int(d.x), cz + int(d.z)): return d
	return Vector3()

func _place(node: Spatial, cx: int, cz: int, d: Dictionary, depth := 0.6, snap := true):
	var c = center(cx, cz)
	var wd = _wall_dir(cx, cz) if snap else Vector3()
	if d.has("rot"):
		node.rotation_degrees.y = d.rot; node.translation = c
	elif wd != Vector3():
		node.translation = c + wd * (C / 2 - depth / 2 - 0.03)
		node.rotation.y = atan2(-wd.x, -wd.z)
	else:
		node.translation = c
	if d.has("off"): node.translation += Vector3(d.off[0], 0, d.off[1])
	add_child(node)

func _ibody(e: Dictionary, size: Vector3, y: float):
	var sb = StaticBody.new(); sb.collision_layer = 2; sb.collision_mask = 0
	var cs = CollisionShape.new(); var sh = BoxShape.new(); sh.extents = size / 2; cs.shape = sh
	sb.add_child(cs); sb.translation = Vector3(0, y, 0); sb.set_meta("ent", e)
	e.node.add_child(sb); e.body = sb

func _build_entities():
	var counts = {}
	by_char["__doors"] = []
	for cz in gh:
		for cx in gw:
			var ch = grid[cz][cx]
			if ch == "#" or ch == " " or ch == ".": continue
			var c = center(cx, cz)
			if not markers.has(ch): markers[ch] = []
			markers[ch].append(c)
			var d = legend_of(data, ch)
			if d == null: continue
			counts[ch] = counts.get(ch, 0) + 1
			if d.get("ngp", false) and not G.flag("ngp"): continue   # New Game+ only content
			if d.has("only_if") and not G.flag(d.only_if): continue   # earned content (e.g. all notebook pages found)
			var e = {"d": d, "ch": ch, "kind": d.t, "pos": c, "cell": Vector2(cx, cz), "uid": "c%d_%s%d" % [data.n, ch, counts[ch]],
				"node": null, "body": null, "done": false, "open": false}
			e.done = G.flag("u:" + e.uid)
			if not by_char.has(ch): by_char[ch] = []
			by_char[ch].append(e)
			ents.append(e)
			call("_mk_" + d.t, e, cx, cz)
			if d.get("block", false): astar.set_point_disabled(pid(cx, cz), true)

func _mk_start(_e, _x, _z): pass
func _mk_mark(_e, _x, _z): pass
func _mk_patrol(_e, _x, _z): pass
func _mk_trig(_e, _x, _z): pass
func _mk_radio(_e, _x, _z): pass

func _mk_light(e, cx, cz):
	var d = e.d
	var l = OmniLight.new()
	var col = Color(1.0, 0.12, 0.08) if d.get("red", false) else d.get("c", pal.light)
	l.light_color = col; l.omni_range = d.get("r", 9.0); l.omni_attenuation = 1.4
	l.light_energy = d.get("e", 1.3); l.shadow_bias = 0.25
	l.translation = e.pos + Vector3(0, min(pal.h - 0.45, 3.4), 0); add_child(l)
	var rec = {"node": l, "d": d, "base": l.light_energy, "t": _rng.randf() * 10.0, "cone": null, "sparks": null, "was_on": true}
	if Mats.enabled():
		# fluorescent fitting + a soft light shaft through the fog
		rec.fx = Fx.fixture(self, e.pos + Vector3(0, pal.h - 0.06, 0), col, Props.mat(Color(0.3, 0.31, 0.3), 0, 0.5, 0.6)).get_node("diffuser")
		rec.cone = Fx.cone(self, e.pos + Vector3(0, pal.h - 0.12, 0), pal.h - 0.15, col)
		if d.get("flicker", false): rec.sparks = Fx.sparks(self, e.pos + Vector3(0, pal.h - 0.15, 0))
	else:
		rec.fx = Props.box(self, Vector3(0.9, 0.08, 0.25), e.pos + Vector3(0, pal.h - 0.05, 0), col, 2.5)
	e.node = l
	lights.append(rec)

func _mk_prop(e, cx, cz):
	var n = Props.make(e.d.p, e.d.get("tint", Color(1, 1, 1)))
	_place(n, cx, cz, e.d, e.d.get("depth", 0.7), e.d.p in Props.WALL_PROPS)
	e.node = n
	if e.d.has("hidden") and not G.flag(e.d.hidden): n.visible = false

func _mk_npc(e, cx, cz):
	var n = Props.make("figure", e.d.get("tint", Color(1, 1, 1)))
	_place(n, cx, cz, e.d, 0.5, false); e.node = n
	if e.d.get("hidden_at_start", false): n.visible = false

func _stand_with(e, cx, cz, top: String):
	var n = Spatial.new()
	n.add_child(Props.make("stand"))
	if top == "paper": n.add_child(Props.make("paper"))
	elif top == "recorder":
		var r = Props.make("recorder"); n.get_child(0).queue_free(); n.add_child(r)
	elif top == "item":
		var col = {"battery": Color(0.9, 0.8, 0.2), "medkit": Color(0.85, 0.15, 0.12), "bottle": Color(0.3, 0.6, 0.35)}.get(e.d.id, Color(0.8, 0.7, 0.4))
		Props.box(n, Vector3(0.2, 0.12, 0.14), Vector3(0, 0.92, 0), col, 0.35).name = "item"
	_place(n, cx, cz, e.d, 0.6, true); e.node = n
	_ibody(e, Vector3(0.9, 1.4, 0.9), 0.8)

func _mk_note(e, cx, cz):
	_stand_with(e, cx, cz, "paper")
func _mk_tape(e, cx, cz):
	_stand_with(e, cx, cz, "recorder")
func _mk_item(e, cx, cz):
	_stand_with(e, cx, cz, "item")
	if e.done:
		var it = e.node.get_node_or_null("item")
		if it: it.visible = false

func _mk_use(e, cx, cz):
	var p = e.d.get("p", "switch")
	var n = Props.make(p, e.d.get("tint", Color(1, 1, 1)))
	_place(n, cx, cz, e.d, e.d.get("depth", 0.7 if p != "switch" and p != "breaker" else 0.16), not e.d.has("cycle")); e.node = n
	if e.d.has("cycle"):
		e.base_rot = n.rotation.y
		n.rotation.y += TAU * int(G.flags.get("cyc_" + e.uid, e.d.get("init", 0))) / float(e.d.cycle)
	_ibody(e, e.d.get("size", Vector3(1.4, 1.8, 1.2)), 1.0)

func _mk_save(e, cx, cz):
	var n = Props.make("terminal"); _place(n, cx, cz, e.d, 0.4, true); e.node = n
	_ibody(e, Vector3(1.0, 1.6, 0.9), 0.9)

func _mk_hide(e, cx, cz):
	var n = Props.make("locker"); _place(n, cx, cz, e.d, 0.6, true); e.node = n
	_ibody(e, Vector3(1.0, 2.0, 0.8), 1.0)

func _mk_ghost(e, cx, cz):
	var n = Spatial.new()
	if e.d.has("text"):
		var l = Label3D.new(); l.text = e.d.text; l.font = ui.font(64, "b"); l.pixel_size = 0.004
		l.modulate = Color(0.55, 1.0, 0.85); l.translation = Vector3(0, 1.6, 0); l.double_sided = true
		l.width = 420; l.autowrap = true
		n.add_child(l)
	if e.d.has("p"): n.add_child(Props.make(e.d.p))
	_place(n, cx, cz, e.d, 0.06, e.d.has("text")); e.node = n
	n.visible = false

func _mk_plate(e, cx, cz):
	var n = Spatial.new()
	Props.box(n, Vector3(1.3, 0.06, 1.3), Vector3(0, 0.03, 0), Color(0.7, 0.55, 0.1), 0.25, false, 0.5)
	n.translation = e.pos; add_child(n); e.node = n

func _mk_pcrate(e, cx, cz):
	var rb = RigidBody.new(); rb.mass = 18.0; rb.linear_damp = 0.6; rb.angular_damp = 0.9
	rb.physics_material_override = PhysicsMaterial.new(); rb.physics_material_override.friction = 0.8
	rb.axis_lock_angular_x = true; rb.axis_lock_angular_z = true
	var cs = CollisionShape.new(); var sh = BoxShape.new(); sh.extents = Vector3(0.45, 0.45, 0.45); cs.shape = sh; rb.add_child(cs)
	Props.box(rb, Vector3(0.9, 0.9, 0.9), Vector3(), Props.WOOD)
	Props.box(rb, Vector3(0.93, 0.1, 0.93), Vector3(), Props.STEEL, 0, false, 0.6)
	rb.translation = e.pos + Vector3(0, 0.5, 0); add_child(rb); rb.add_to_group("pcrate"); e.node = rb

func _mk_door(e, cx, cz):
	var n = Spatial.new(); n.translation = e.pos; add_child(n)
	var along_x = not is_floor(cx, cz - 1) and not is_floor(cx, cz + 1)   # passage runs along x → panel spans z
	if along_x: n.rotation_degrees.y = 90
	var h = min(pal.h, 2.6)
	var col = e.d.get("c", Color(0.28, 0.3, 0.31))
	var panel = Spatial.new(); n.add_child(panel)
	Props.box(panel, Vector3(C, h, 0.16), Vector3(0, h / 2, 0), col, 0, false, 0.5)
	Props.box(panel, Vector3(C, 0.12, 0.2), Vector3(0, 1.1, 0), Color(0.6, 0.5, 0.1) if not e.d.has("lock") else Color(0.6, 0.12, 0.08))
	var sb = StaticBody.new(); sb.collision_layer = 3
	var cs = CollisionShape.new(); var sh = BoxShape.new(); sh.extents = Vector3(C / 2, h / 2, 0.14); cs.shape = sh
	sb.add_child(cs); sb.translation = Vector3(0, h / 2, 0); sb.set_meta("ent", e); panel.add_child(sb)
	if pal.h > h + 0.05:
		Props.box(n, Vector3(C, pal.h - h, 0.3), Vector3(0, h + (pal.h - h) / 2, 0), pal.wall, 0, true)
	e.node = n; e.panel = panel; e.h = h
	e.locked = (e.d.has("lock") or e.d.has("code") or e.d.has("needflag") or e.d.get("sealed", false)) and not e.done
	by_char["__doors"].append(e)
	if e.locked: astar.set_point_disabled(pid(cx, cz), true)
	if G.flag("o:" + e.uid): _door_open(e, true)

func _door_open(e, instant := false):
	if e.open: return
	e.open = true; e.locked = false
	astar.set_point_disabled(pid(int(e.cell.x), int(e.cell.y)), false)
	G.set_flag("o:" + e.uid)
	if instant:
		e.panel.translation.y = e.h - 0.12
		return
	Snd.play3d("door", self, e.pos + Vector3(0, 1.2, 0), 2)
	noise(e.pos, 9.0, "door")
	var tw = Tween.new(); add_child(tw)
	tw.interpolate_property(e.panel, "translation:y", 0, e.h - 0.12, 1.1, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	tw.start()
	yield(tw, "tween_all_completed")
	tw.queue_free()

func _door_close(e):
	if not e.open: return
	e.open = false; G.set_flag("o:" + e.uid, false)
	e.panel.translation.y = 0
	Snd.play3d("metal", self, e.pos, 0, 0.6)

# ---------------------------------------------------------------- per-frame
func _physics_process(dt):
	if player == null or dead: return
	for w in _walkers:
		w.t = min(w.dur, w.t + dt)
		var k = w.t / w.dur
		w.n.translation = w.a.linear_interpolate(w.b, k)
		var sw = sin(w.t * 11.0) * 0.6 * (1.0 - k * k)
		for part in [["leg_l", sw], ["leg_r", -sw], ["arm_l", -sw * 0.8], ["arm_r", sw * 0.8]]:
			var nd = w.n.get_node_or_null(part[0])
			if nd: nd.rotation.x = part[1]
	for i in range(_walkers.size() - 1, -1, -1):
		if _walkers[i].t >= _walkers[i].dur: _walkers.remove(i)
	var pp = player.global_transform.origin
	for l in lights:
		l.t += dt
		var on = power_on or l.d.get("red", false) or l.d.get("always", false)
		var e = l.base if on else 0.0
		if l.d.get("flicker", false) and on:
			e *= 0.25 + 0.75 * (1.0 if fmod(l.t * 7.0 + sin(l.t * 3.1) * 2.0, 3.0) > 0.5 else 0.15)
		if l.d.get("red", false): e *= 0.55 + 0.45 * sin(l.t * 4.0)
		l.node.light_energy = e
		l.fx.visible = e > 0.1
		if l.cone:
			l.cone.visible = e > 0.05
			if l.cone.visible: l.cone.material_override.set_shader_param("energy", e)
		if l.sparks:
			var on_now = e > l.base * 0.5
			if on_now and not l.was_on and _rng.randf() < 0.35:
				l.sparks.restart(); l.sparks.emitting = true
				Snd.play3d("glitch", self, l.node.global_transform.origin, -16, 2.2, 14)
			l.was_on = on_now
	for e in ents:
		if e.kind == "trig" and not e.done:
			if _cond(e.d) and Vector2(pp.x - e.pos.x, pp.z - e.pos.z).length() < e.d.get("r", 1.6) and not ui.in_cine:
				_done(e); run(e.d.get("ev", []))
		elif e.kind == "plate" and not e.done:
			for cr in get_tree().get_nodes_in_group("pcrate"):
				if (cr.global_transform.origin - e.pos).length() < 1.0:
					_done(e); Snd.play3d("metal", self, e.pos, 0, 0.8)
					if e.d.has("flag"): G.set_flag(e.d.flag)
					run(e.d.get("ev", []))
		elif e.kind == "ghost":
			var vis = (reveal_on or force_reveal) and (pp - e.pos).length() < e.d.get("r", 11.0)
			e.node.visible = vis
			if vis and not e.done:
				_done(e)
				if e.d.has("flag"): G.set_flag(e.d.flag)
				if e.d.has("journal"): G.add_journal(e.d.journal, e.d.get("text", ""), "note")
				G.flags["m_unseen"] = int(G.flags.get("m_unseen", 0)) + 1
				if G.flags.m_unseen >= 10: G.achieve("unseen")
				Snd.play("whisper", -8)
				run(e.d.get("ev", []))

func _cond(d: Dictionary) -> bool:
	if d.has("if") and not G.flag(d["if"]): return false
	if d.has("ifnot") and G.flag(d.ifnot): return false
	return true

func _done(e):
	e.done = true; G.set_flag("u:" + e.uid)

func noise(pos: Vector3, loud: float, kind := "step"):
	if kind == "step": loud *= noise_mult
	if listener and is_instance_valid(listener): listener.hear(pos, loud, kind)

# ---------------------------------------------------------------- interaction
func prompt_for(e) -> String:
	if e == null: return ""
	var d = e.d
	match e.kind:
		"note": return "Read  " + d.title
		"tape": return "Play  " + d.title
		"item": return "" if e.done else "Take  " + str(Story.ITEMS.get(d.id, d.id))
		"door":
			if e.open: return ""
			return "Open door" if not e.locked else ("Enter code" if d.has("code") else "Door (locked)")
		"use":
			if d.has("seq"): return "" if G.flag("solved_" + d.seq) else d.get("prompt", "Throw switch")
			if d.has("cycle"): return "" if G.flag("solved_" + d.group) else d.get("prompt", "Turn")
			return "" if (e.done and d.get("once", true)) else d.get("prompt", "Use")
		"save": return "Emergency log terminal — save"
		"hide": return "Leave locker" if player.hidden else "Hide"
	return ""

func interact(e):
	var d = e.d
	match e.kind:
		"note":
			G.add_journal(d.title, d.text, "note")
			if d.has("flag"): G.set_flag(d.flag)
			ui.read(d.title, d.text)
			if not e.done:
				_done(e)
				if d.has("ev"):
					yield(ui, "closed")
					run(d.ev)
		"tape":
			var txt = ""
			for l in d.lines:
				if l.size() > 1 and typeof(l[1]) == TYPE_STRING and str(l[0]) != str(l[0]).to_lower(): txt += "%s: %s\n\n" % [l[0], l[1]]
			G.add_journal(d.title, txt, "tape")
			if d.has("flag"): G.set_flag(d.flag)
			if G.count("tape_ev") >= 7: G.achieve("all_tapes")
			Snd.play("click", 0)
			var first = not e.done
			_done(e)
			noise(e.pos, 7.0, "voice")
			yield(run(d.lines), "completed")
			if first and d.has("ev"): run(d.ev)
		"item":
			if e.done: return
			_done(e); G.give(d.id, d.get("n", 1)); Snd.play("pickup", -4)
			var it = e.node.get_node_or_null("item")
			if it: it.visible = false
			ui.toast("Taken: " + str(Story.ITEMS.get(d.id, d.id)))
			if d.id == "radio": G.has_radio = true
			if d.has("ev"): run(d.ev)
		"door":
			if e.open: return
			if e.locked:
				if d.has("code") and G.test_mode:
					pass
				elif d.has("code"):
					ui.keypad(d.get("label", "ENTER ACCESS CODE"))
					yield(ui, "closed")
					if ui.keypad_result == "": return
					if ui.keypad_result != str(d.code):
						Snd.play("locked", 0); ui.say("", "ACCESS DENIED.", 1.5); noise(e.pos, 6.0, "door"); return
					Snd.play("beep_hi", -4)
				elif d.has("lock"):
					if not G.has(d.lock):
						Snd.play("locked", 0); noise(e.pos, 5.0, "door")
						ui.say("DANIEL", d.get("msg", "Locked. Needs a key."), 2.2); return
					ui.toast("Used: " + str(Story.ITEMS.get(d.lock, d.lock)))
				elif d.has("needflag"):
					if not G.flag(d.needflag):
						Snd.play("locked", 0); noise(e.pos, 5.0, "door")
						ui.say("DANIEL", d.get("msg", "It won't move. No power to the lock."), 2.4); return
				else:
					Snd.play("locked", 0); ui.say("DANIEL", d.get("msg", "Sealed."), 2.0); return
				_done(e)
			_door_open(e)
			if d.has("ev") and not G.flag("e:" + e.uid):
				G.set_flag("e:" + e.uid); run(d.ev)
		"use":
			if d.has("seq"):
				return _seq(e)
			if d.has("cycle"):
				return _cycle(e)
			if e.done and d.get("once", true): return
			if d.has("code") and not G.test_mode:
				ui.keypad(d.get("label", "ENTER CODE"))
				yield(ui, "closed")
				if ui.keypad_result == "": return
				if ui.keypad_result != str(d.code):
					Snd.play("locked", 0); ui.say("", "ACCESS DENIED.", 1.5); noise(e.pos, 6.0, "door")
					return
				Snd.play("beep_hi", -4)
			if not _cond(d) or (d.has("needflag") and not G.flag(d.needflag)) or (d.has("need") and not G.has(d.need)):
				Snd.play("locked", -4)
				ui.say("DANIEL", d.get("fail", "Not yet."), 2.6); return
			if d.has("need") and d.get("consume", true): G.take(d.need)
			_done(e); Snd.play("click", 2)
			if d.has("flag"): G.set_flag(d.flag)
			run(d.get("ev", []))
		"save":
			checkpoint(e.ch); Snd.play("beep", -6); ui.toast("Progress logged.")
		"hide":
			player.toggle_hide(e)

func _group_total(key: String, g: String) -> int:
	var n = 0
	for x in ents:
		if x.kind == "use" and x.d.get(key, "") == g: n += 1
	return n

func _seq(e):
	# ordered-switch puzzle: steps 1..N must be thrown in order; a mistake resets the group (loudly)
	var d = e.d; var k = "seq_" + d.seq
	var cur = int(G.flags.get(k, 0)); var total = _group_total("seq", d.seq)
	if cur >= total: return
	Snd.play3d("metal", self, e.pos + Vector3(0, 1.2, 0), -2, 1.4)
	if int(d.step) == cur + 1:
		G.flags[k] = cur + 1
		Snd.play("beep", -6, 1.0 + 0.12 * d.step)
		if cur + 1 == total:
			G.set_flag("solved_" + d.seq)
			run(data.groups[d.seq])
	else:
		G.flags[k] = 0
		Snd.play("locked", 0); noise(e.pos, 9.0, "door")
		run(data.get("groups", {}).get(d.seq + "_fail", [["DANIEL", "Wrong order. Everything's reset."]]))

func _cycle(e):
	# rotating-array puzzle: every member of the group must be turned to its target notch
	var d = e.d
	if G.flag("solved_" + d.group): return
	var k = "cyc_" + e.uid
	var v = (int(G.flags.get(k, d.get("init", 0))) + 1) % int(d.cycle)
	G.flags[k] = v
	e.node.rotation.y = e.base_rot + TAU * v / float(d.cycle)
	Snd.play3d("metal", self, e.pos + Vector3(0, 1.4, 0), -4, 1.1); noise(e.pos, 5.0, "door")
	var right = 0; var total = 0
	for x in ents:
		if x.kind == "use" and x.d.get("group", "") == d.group:
			total += 1
			if int(G.flags.get("cyc_" + x.uid, x.d.get("init", 0))) == int(x.d.target): right += 1
	ui.toast("%s — alignment %d of %d" % [d.get("label", "Array"), right, total])
	if right == total:
		G.set_flag("solved_" + d.group)
		run(data.groups[d.group])

func checkpoint(marker: String):
	G.checkpoint = marker
	G.health = player.health; G.save_game()

func ent_key(key: String):
	var ch = key; var i = 0
	if "#" in key:
		ch = key.split("#")[0]; i = int(key.split("#")[1]) - 1
	var l = by_char.get(ch, [])
	return l[i] if i < l.size() else null

func ent_at(ch: String):
	return by_char[ch][0] if by_char.has(ch) and by_char[ch].size() else null

# ---------------------------------------------------------------- power
func _apply_power(instant := false):
	if _outside: return
	env.ambient_light_energy = pal.amb_e * (1.0 if power_on else 0.35)
	if not instant: Snd.play("power_up" if power_on else "power_down", 0)

func set_power(on: bool):
	power_on = on; G.set_flag("power%d" % data.n, on); _apply_power()

# ---------------------------------------------------------------- listener control
func spawn_listener(marker: String, mode := "patrol"):
	if listener and is_instance_valid(listener): listener.queue_free()
	listener = load("res://scripts/listener.gd").new(); add_child(listener)
	listener.setup(self, player, ui, pos_of(marker), mode)

func despawn_listener():
	if listener and is_instance_valid(listener): listener.queue_free()
	listener = null

# ---------------------------------------------------------------- event runner
func run(evs: Array):
	running += 1
	yield(get_tree(), "idle_frame")
	for e in evs:
		if dead or not is_inside_tree(): break
		var r = _exec(e)
		if r is GDScriptFunctionState and r.is_valid(): yield(r, "completed")
	running -= 1

func _exec(e: Array):
	var c = str(e[0])
	if c == "" or c != c.to_lower():
		return ui.say(c, e[1], e[2] if e.size() > 2 else -1.0)
	match c:
		"wait": return ui.wait(e[1])
		"obj": ui.objective(e[1])
		"flag": G.set_flag(e[1], e[2] if e.size() > 2 else true)
		"sfx":
			if e.size() > 4 and e[4] != "": Snd.play3d(e[1], self, pos_of(e[4]) + Vector3(0, 1.4, 0), e[2], e[3])
			else: Snd.play(e[1], e[2] if e.size() > 2 else 0.0, e[3] if e.size() > 3 else 1.0)
		"music": Snd.music(e[1], e[2] if e.size() > 2 else -10.0)
		"loop": Snd.loop(e[1], e[2], e[3] if e.size() > 3 else -10.0, e[4] if e.size() > 4 else 1.0)
		"unloop": Snd.unloop(e[1])
		"lights": set_power(e[1])
		"card": return ui.chapter_card(data.n, data.title, data.get("sub", ""))
		"title": return ui.title_reveal(e[1] if e.size() > 1 else "")
		"fade": return ui.fade(e[1], e[2] if e.size() > 2 else 1.0)
		"cine":
			ui.set_cine(e[1]); player.locked = e[1]
			if not e[1]: _cam_off()
		"cam": return _cam(e)
		"camoff": _cam_off()
		"give":
			G.give(e[1], e[2] if e.size() > 2 else 1)
			if e[1] == "radio": G.has_radio = true
		"take": G.take(e[1])
		"checkpoint": checkpoint(e[1])
		"save": G.save_game()
		"next": main.call_deferred("next_chapter")
		"ending": main.call_deferred("play_ending")
		"credits": main.call_deferred("play_credits")
		"menu": main.call_deferred("show_menu")
		"choice": return _choice(e)
		"if":
			if G.flag(e[1]): return run(e[2])
			elif e.size() > 3: return run(e[3])
		"ifnot":
			if not G.flag(e[1]): return run(e[2])
		"unlock":
			for d in by_char.get(e[1], []):
				d.locked = false; _done(d)
				astar.set_point_disabled(pid(int(d.cell.x), int(d.cell.y)), false)
				if e.size() > 2 and e[2]: _door_open(d)
		"lock":
			for d in by_char.get(e[1], []):
				_door_close(d); d.locked = true; d.d = d.d.duplicate(); d.d["sealed"] = true
				astar.set_point_disabled(pid(int(d.cell.x), int(d.cell.y)), true)
		"listener":
			match e[1]:
				"spawn": spawn_listener(e[2], e[3] if e.size() > 3 else "patrol")
				"despawn": despawn_listener()
				_:
					if listener and is_instance_valid(listener): listener.command(e[1], pos_of(e[2]) if e.size() > 2 else Vector3())
		"hurt": player.hurt(e[1])
		"shake": player.shake = e[1] if e.size() > 1 else 0.5
		"toast": ui.toast(e[1])
		"journal": G.add_journal(e[1], e[2], "note")
		"look": return player.look_at_point(pos_of(e[1]) + Vector3(0, e[2] if e.size() > 2 else 1.5, 0))
		"text": return ui.big_text(e[1], e[2] if e.size() > 2 else 3.0, e[3] if e.size() > 3 else 30)
		"monitor": return ui.monitor(e[1], e[2] if e.size() > 2 else 2.5)
		"tp":
			player.global_transform.origin = pos_of(e[1]) + Vector3(0, 0.1, 0)
			if e.size() > 2: player.rotation_degrees.y = e[2]
		"ach": G.achieve(e[1])
		"radio_on": radio.force(e[1], e[2] if e.size() > 2 else -1.0)
		"reveal": force_reveal = e[1]
		"hide_ent":
			for x in by_char.get(e[1], []):
				if x.node: x.node.visible = false
		"show_ent":
			for x in by_char.get(e[1], []):
				if x.node: x.node.visible = true
		"ext":
			if ext: ext.set_mode(e[1])
		"noise_mult": noise_mult = float(e[1])
		"group": return run(data.groups[e[1]])
		"move":
			# ["move", "k#2", marker, seconds]: an NPC walks/runs to a marker (legs and arms swing)
			var x = ent_key(e[1])
			if x and x.node:
				var to = pos_of(e[2]); var fr = x.node.translation
				var d = to - fr; d.y = 0
				if d.length() > 0.01: x.node.rotation.y = atan2(-d.x, -d.z) + PI
				_walkers.append({"n": x.node, "a": fr, "b": to, "t": 0.0, "dur": float(e[3])})
		"loop3d":
			if _loops3d.has(e[1]) and is_instance_valid(_loops3d[e[1]]): _loops3d[e[1]].queue_free()
			_loops3d[e[1]] = Snd.play3d(e[2], self, pos_of(e[3]) + Vector3(0, 1.4, 0), e[4] if e.size() > 4 else 0.0, 1.0, 26.0)
		"unloop3d":
			if _loops3d.has(e[1]) and is_instance_valid(_loops3d[e[1]]): _loops3d[e[1]].queue_free()
			_loops3d.erase(e[1])
		"close":
			for x in by_char.get(e[1], []): _door_close(x)
		"pulse":
			# emergency state: all normal lights die, red ones keep pulsing
			power_on = false; _apply_power(true); Snd.play("power_down", 2)
	return null

func _choice(e: Array):
	# ["choice", prompt, [[label, [events]], ...]]
	var labels = []
	for o in e[2]: labels.append(o[0])
	var was = G.skip; G.skip = false
	ui.choice(e[1], labels)
	var idx = 0
	if G.test_mode:
		yield(get_tree(), "idle_frame")
		idx = int(G.flags.get("_test_choice", 0)) % labels.size()
		ui._choose(idx)
	else:
		idx = yield(ui, "chosen")
	G.skip = was
	yield(run(e[2][idx][1]), "completed")

func _cam(e: Array):
	# ["cam", from, look, dur, to?, height?, look_height?]
	var hgt = e[5] if e.size() > 5 else 1.6
	var a = pos_of(e[1]) + (Vector3(0, hgt, 0) if not e[1].begins_with("@") else Vector3())
	var look = pos_of(e[2]) + (Vector3(0, e[6] if e.size() > 6 else 1.4, 0) if not e[2].begins_with("@") else Vector3())
	var b = a
	if e.size() > 4 and e[4] != "": b = pos_of(e[4]) + (Vector3(0, hgt, 0) if not e[4].begins_with("@") else Vector3())
	cine_cam.current = true
	cine_cam.fov = 55
	_env_mode(e[1].begins_with("@"))
	_cam_tw.remove_all()
	cine_cam.look_at_from_position(a, look, Vector3.UP)
	if G.skip or e[3] <= 0:
		yield(get_tree(), "idle_frame")
		return
	_cam_from = a; _cam_to = b; _cam_look = look
	_cam_tw.interpolate_method(self, "_cam_step", 0.0, 1.0, e[3], Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	_cam_tw.start()
	yield(ui.wait(e[3]), "completed")

var _cam_from: Vector3
var _cam_to: Vector3
var _cam_look: Vector3
func _cam_step(t: float):
	var p = _cam_from.linear_interpolate(_cam_to, t)
	if (p - _cam_look).length() > 0.1: cine_cam.look_at_from_position(p, _cam_look, Vector3.UP)

func _cam_off():
	_cam_tw.remove_all()
	_env_mode(false)
	if player: player.cam.current = true

# ---------------------------------------------------------------- validation (used by tests)
static func validate(d: Dictionary) -> Array:
	var errs = []
	var chars = {}
	for row in d.map:
		for ch in row: chars[ch] = true
	if not chars.has("S"): errs.append("no start 'S'")
	for ch in chars:
		if ch in ["#", " ", "."]: continue
		if legend_of(d, ch) == null: errs.append("map char '%s' has no legend" % ch)
	for ch in d.leg:
		if not chars.has(ch): errs.append("legend '%s' not on map" % ch)
		var l = d.leg[ch]
		if not l.has("t"):
			errs.append("legend '%s' missing type" % ch)
			continue
		if l.has("ev"): _val_ev(l.ev, chars, errs, ch, d)
		if l.t == "tape": _val_ev(l.lines, chars, errs, ch, d)
		if l.t == "radio" and l.has("lines"): _val_ev(l.lines, chars, errs, ch, d)
	_val_ev(d.get("start_ev", []), chars, errs, "start_ev", d)
	_val_ev(d.get("pre_ev", []), chars, errs, "pre_ev", d)
	_val_ev(d.get("resume_ev", []), chars, errs, "resume_ev", d)
	for g in d.get("groups", {}): _val_ev(d.groups[g], chars, errs, "group " + g, d)
	for s in d.get("ai", []):
		if not chars.has(s.at): errs.append("ai spawn marker '%s' missing" % s.at)
	return errs

static func _val_ev(evs: Array, chars: Dictionary, errs: Array, where: String, d: Dictionary):
	for e in evs:
		if typeof(e) != TYPE_ARRAY or e.size() == 0:
			errs.append("%s: malformed event %s" % [where, str(e)]); continue
		var c = str(e[0])
		if c == "" or c != c.to_lower():
			if e.size() < 2 or typeof(e[1]) != TYPE_STRING: errs.append("%s: bad line %s" % [where, str(e)])
			continue
		if not c in CMDS: errs.append("%s: unknown command '%s'" % [where, c])
		match c:
			"cam":
				for i in [1, 2, 4]:
					if e.size() > i and e[i] != "" and not str(e[i]).begins_with("@") and not chars.has(e[i]): errs.append("%s: cam marker '%s' missing" % [where, e[i]])
			"tp", "look", "checkpoint", "unlock", "lock", "hide_ent", "show_ent", "close":
				if not chars.has(e[1]): errs.append("%s: %s marker '%s' missing" % [where, c, e[1]])
			"move":
				if not chars.has(str(e[1]).split("#")[0]) or not chars.has(e[2]): errs.append("%s: move refs '%s' -> '%s'" % [where, e[1], e[2]])
			"loop3d":
				if not chars.has(e[3]): errs.append("%s: loop3d marker '%s' missing" % [where, e[3]])
				if not e[2] in Snd.NAMES: errs.append("%s: unknown sound '%s'" % [where, e[2]])
			"listener":
				if e.size() > 2 and not chars.has(e[2]): errs.append("%s: listener marker '%s' missing" % [where, e[2]])
			"if":
				_val_ev(e[2], chars, errs, where, d)
				if e.size() > 3: _val_ev(e[3], chars, errs, where, d)
			"ifnot": _val_ev(e[2], chars, errs, where, d)
			"choice":
				for o in e[2]: _val_ev(o[1], chars, errs, where, d)
			"sfx", "music", "loop":
				var nm = e[1] if c != "loop" else e[2]
				if nm != "" and not nm in Snd.NAMES: errs.append("%s: unknown sound '%s'" % [where, nm])
