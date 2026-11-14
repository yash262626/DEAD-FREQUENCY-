extends Reference
# Procedural prop library. Everything is built from primitives so the project
# ships with zero imported art; see docs/11_ASSET_LIST.md for the replacement plan.

static func mat(col: Color, emis := 0.0, rough := 0.7, metal := 0.0) -> SpatialMaterial:
	var m = SpatialMaterial.new()
	m.albedo_color = col; m.roughness = rough; m.metallic = metal
	if emis > 0.0:
		m.emission_enabled = true; m.emission = col; m.emission_energy = emis
	if col.a < 1.0:
		m.flags_transparent = true
	return m

static func box(parent: Node, size: Vector3, pos: Vector3, col: Color, emis := 0.0, solid := false, metal := 0.0) -> MeshInstance:
	var mi = MeshInstance.new(); var bm = CubeMesh.new(); bm.size = size
	mi.mesh = bm; mi.material_override = mat(col, emis, 0.6 if metal > 0 else 0.8, metal); mi.translation = pos
	parent.add_child(mi)
	if solid:
		var sb = StaticBody.new(); var cs = CollisionShape.new(); var sh = BoxShape.new()
		sh.extents = size / 2; cs.shape = sh; sb.add_child(cs); sb.translation = pos; parent.add_child(sb)
	return mi

static func cyl(parent: Node, r: float, h: float, pos: Vector3, col: Color, emis := 0.0, solid := false, rot := Vector3()) -> MeshInstance:
	var mi = MeshInstance.new(); var cm = CylinderMesh.new(); cm.top_radius = r; cm.bottom_radius = r; cm.height = h
	cm.radial_segments = 16; cm.rings = 1
	mi.mesh = cm; mi.material_override = mat(col, emis, 0.5, 0.6 if col.a >= 1.0 else 0.0); mi.translation = pos; mi.rotation_degrees = rot
	parent.add_child(mi)
	if solid:
		var sb = StaticBody.new(); var cs = CollisionShape.new(); var sh = CylinderShape.new()
		sh.radius = r; sh.height = h; cs.shape = sh; sb.add_child(cs); sb.translation = pos; sb.rotation_degrees = rot; parent.add_child(sb)
	return mi

const STEEL = Color(0.32, 0.34, 0.35)
const DARK = Color(0.1, 0.11, 0.12)
const RUST = Color(0.35, 0.2, 0.13)
const PAPER = Color(0.85, 0.82, 0.72)
const WOOD = Color(0.3, 0.22, 0.15)

# props that should be pushed against the nearest wall
const WALL_PROPS = ["locker", "shelf", "console", "switch", "terminal", "rack", "cabinet", "breaker", "board", "bed", "desk", "vent", "ladder", "valve"]

static func make(type: String, tint := Color(1, 1, 1)) -> Spatial:
	var n = Spatial.new()
	match type:
		"desk":
			box(n, Vector3(1.5, 0.06, 0.7), Vector3(0, 0.75, 0), WOOD, 0, false)
			box(n, Vector3(1.5, 0.75, 0.7), Vector3(0, 0.375, 0), Color(0.2, 0.2, 0.2, 0.0), 0, true).visible = false
			for sx in [-0.7, 0.7]: box(n, Vector3(0.06, 0.75, 0.64), Vector3(sx, 0.375, 0), STEEL, 0, false, 0.5)
			box(n, Vector3(0.45, 0.34, 0.4), Vector3(-0.35, 0.96, -0.08), Color(0.6, 0.58, 0.5))
			box(n, Vector3(0.36, 0.25, 0.02), Vector3(-0.35, 0.97, 0.125), Color(0.1, 0.3, 0.2), 0.5)
			box(n, Vector3(0.3, 0.02, 0.22), Vector3(0.3, 0.79, 0.1), PAPER)
		"table":
			box(n, Vector3(1.4, 0.06, 0.9), Vector3(0, 0.75, 0), STEEL, 0, false, 0.6)
			box(n, Vector3(1.3, 0.75, 0.8), Vector3(0, 0.375, 0), DARK, 0, true).visible = false
			for sx in [-0.6, 0.6]:
				for sz in [-0.38, 0.38]: box(n, Vector3(0.05, 0.75, 0.05), Vector3(sx, 0.375, sz), STEEL, 0, false, 0.6)
		"chair":
			box(n, Vector3(0.45, 0.06, 0.45), Vector3(0, 0.45, 0), DARK)
			box(n, Vector3(0.45, 0.5, 0.05), Vector3(0, 0.75, -0.2), DARK)
			cyl(n, 0.03, 0.45, Vector3(0, 0.22, 0), STEEL)
			n.rotation_degrees.y = 25
		"locker":
			box(n, Vector3(0.9, 2.0, 0.6), Vector3(0, 1.0, 0), Color(0.22, 0.3, 0.32) * tint, 0, true, 0.4)
			box(n, Vector3(0.02, 1.9, 0.02), Vector3(0, 1.0, 0.31), DARK)
			for i in 4: box(n, Vector3(0.3, 0.015, 0.02), Vector3(-0.22, 1.5 + i * 0.07, 0.31), DARK)
			for i in 4: box(n, Vector3(0.3, 0.015, 0.02), Vector3(0.22, 1.5 + i * 0.07, 0.31), DARK)
		"shelf":
			box(n, Vector3(1.6, 2.0, 0.45), Vector3(0, 1.0, 0), Color(0, 0, 0, 0), 0, true).visible = false
			for i in 5: box(n, Vector3(1.6, 0.04, 0.45), Vector3(0, 0.05 + i * 0.48, 0), STEEL, 0, false, 0.5)
			for sx in [-0.78, 0.78]: box(n, Vector3(0.04, 2.0, 0.45), Vector3(sx, 1.0, 0), STEEL, 0, false, 0.5)
			var rng = RandomNumberGenerator.new(); rng.seed = hash(type) + 7
			for i in 9:
				var w = rng.randf_range(0.12, 0.4)
				box(n, Vector3(w, rng.randf_range(0.15, 0.36), 0.3), Vector3(rng.randf_range(-0.6, 0.6), 0.22 + (i % 4) * 0.48, 0),
					[PAPER, RUST, Color(0.2, 0.25, 0.35), Color(0.4, 0.4, 0.38)][i % 4] * 0.8)
		"crate":
			box(n, Vector3(0.9, 0.9, 0.9), Vector3(0, 0.45, 0), WOOD * tint, 0, true)
			box(n, Vector3(0.92, 0.08, 0.92), Vector3(0, 0.45, 0), WOOD * 0.6)
		"barrel":
			cyl(n, 0.32, 0.95, Vector3(0, 0.475, 0), Color(0.2, 0.3, 0.42) * tint, 0, true)
			cyl(n, 0.335, 0.04, Vector3(0, 0.7, 0), DARK); cyl(n, 0.335, 0.04, Vector3(0, 0.25, 0), DARK)
		"console":
			box(n, Vector3(1.6, 0.9, 0.7), Vector3(0, 0.45, 0), Color(0.25, 0.27, 0.27), 0, true, 0.4)
			var top = box(n, Vector3(1.6, 0.5, 0.1), Vector3(0, 1.1, -0.22), Color(0.2, 0.22, 0.22), 0, false, 0.4)
			top.rotation_degrees.x = -18
			var scr = box(n, Vector3(0.6, 0.34, 0.02), Vector3(-0.4, 1.12, -0.15), Color(0.15, 0.6, 0.3) * tint, 1.2)
			scr.rotation_degrees.x = -18; scr.name = "screen"
			for i in 10:
				box(n, Vector3(0.05, 0.03, 0.05), Vector3(0.1 + (i % 5) * 0.13, 0.92, 0.05 + (i / 5) * 0.14),
					[Color(0.8, 0.2, 0.1), Color(0.8, 0.7, 0.2), Color(0.2, 0.7, 0.3)][i % 3], 0.6)
		"monitor":
			box(n, Vector3(0.9, 0.9, 0.9), Vector3(0, 0.45, 0), STEEL, 0, true, 0.5)
			box(n, Vector3(0.7, 0.55, 0.6), Vector3(0, 1.2, 0), Color(0.55, 0.53, 0.46))
			box(n, Vector3(0.56, 0.42, 0.02), Vector3(0, 1.22, 0.3), Color(0.2, 0.9, 0.4) * tint, 1.5).name = "screen"
		"terminal":
			box(n, Vector3(0.7, 1.3, 0.4), Vector3(0, 0.65, 0), Color(0.28, 0.27, 0.22), 0, true, 0.3)
			box(n, Vector3(0.5, 0.36, 0.02), Vector3(0, 1.0, 0.2), Color(0.9, 0.6, 0.15), 1.4).name = "screen"
			box(n, Vector3(0.5, 0.05, 0.2), Vector3(0, 0.68, 0.28), DARK)
		"bed":
			box(n, Vector3(1.0, 0.4, 2.0), Vector3(0, 0.2, 0), STEEL, 0, true, 0.4)
			box(n, Vector3(0.95, 0.14, 1.95), Vector3(0, 0.47, 0), Color(0.5, 0.5, 0.46) * tint)
			box(n, Vector3(0.6, 0.1, 0.35), Vector3(0, 0.58, -0.75), Color(0.7, 0.7, 0.66))
		"gurney":
			box(n, Vector3(0.75, 0.08, 1.9), Vector3(0, 0.8, 0), Color(0.55, 0.57, 0.56), 0, false, 0.3)
			box(n, Vector3(0.7, 0.8, 1.8), Vector3(0, 0.4, 0), DARK, 0, true).visible = false
			for sx in [-0.32, 0.32]:
				for sz in [-0.85, 0.85]: cyl(n, 0.02, 0.8, Vector3(sx, 0.4, sz), STEEL)
			box(n, Vector3(0.7, 0.06, 1.2), Vector3(0, 0.87, 0.2), Color(0.6, 0.62, 0.58))
		"rack":
			box(n, Vector3(0.8, 2.1, 0.8), Vector3(0, 1.05, 0), Color(0.12, 0.13, 0.14), 0, true, 0.5)
			for i in 12:
				box(n, Vector3(0.6, 0.015, 0.02), Vector3(0, 0.3 + i * 0.14, 0.41), STEEL)
				if i % 2 == 0:
					box(n, Vector3(0.03, 0.03, 0.02), Vector3(-0.25 + (i % 5) * 0.1, 0.36 + i * 0.14, 0.41),
						Color(0.2, 0.9, 0.3) if i % 4 == 0 else Color(0.9, 0.5, 0.1), 2.0)
		"tank":
			cyl(n, 0.55, 0.3, Vector3(0, 0.15, 0), STEEL, 0, true)
			cyl(n, 0.5, 2.0, Vector3(0, 1.3, 0), Color(0.3, 0.7, 0.6, 0.25) * tint, 0, true)
			cyl(n, 0.55, 0.25, Vector3(0, 2.4, 0), STEEL)
			cyl(n, 0.12, 1.5, Vector3(0, 1.2, 0), Color(0.1, 0.4, 0.35), 0.3)
		"generator":
			box(n, Vector3(1.6, 1.2, 1.0), Vector3(0, 0.6, 0), Color(0.45, 0.33, 0.1), 0, true, 0.4)
			cyl(n, 0.3, 1.2, Vector3(0, 1.35, 0), STEEL, 0, false, Vector3(0, 0, 90))
			box(n, Vector3(0.3, 0.2, 0.02), Vector3(0.4, 0.9, 0.51), Color(0.8, 0.2, 0.1), 0.8).name = "screen"
			cyl(n, 0.06, 1.0, Vector3(-0.6, 1.7, 0), DARK)
		"cabinet":
			box(n, Vector3(0.9, 1.4, 0.5), Vector3(0, 0.7, 0), Color(0.4, 0.41, 0.38) * tint, 0, true, 0.3)
			for i in 3: box(n, Vector3(0.8, 0.02, 0.02), Vector3(0, 0.35 + i * 0.42, 0.26), DARK)
			for i in 3: box(n, Vector3(0.14, 0.03, 0.03), Vector3(0, 0.5 + i * 0.42, 0.27), STEEL, 0, false, 0.8)
		"crib":
			box(n, Vector3(0.7, 0.1, 1.2), Vector3(0, 0.45, 0), Color(0.75, 0.73, 0.68), 0, true)
			for i in 7:
				for sx in [-0.35, 0.35]: box(n, Vector3(0.03, 0.5, 0.03), Vector3(sx, 0.75, -0.55 + i * 0.18), Color(0.75, 0.73, 0.68))
			for sx in [-0.35, 0.35]: box(n, Vector3(0.04, 0.04, 1.2), Vector3(sx, 1.0, 0), Color(0.75, 0.73, 0.68))
			box(n, Vector3(0.6, 0.06, 1.1), Vector3(0, 0.53, 0), Color(0.55, 0.62, 0.7))
		"pillar":
			box(n, Vector3(0.7, 3.2, 0.7), Vector3(0, 1.6, 0), Color(0.3, 0.3, 0.29), 0, true)
		"switch", "breaker":
			box(n, Vector3(0.5, 0.7, 0.16), Vector3(0, 1.25, 0), Color(0.3, 0.31, 0.3), 0, true, 0.5)
			box(n, Vector3(0.08, 0.26, 0.08), Vector3(0, 1.25, 0.1), Color(0.75, 0.15, 0.1), 0.3)
			box(n, Vector3(0.06, 0.06, 0.02), Vector3(0.15, 1.5, 0.09), Color(0.9, 0.6, 0.1), 1.5).name = "screen"
		"recorder":
			box(n, Vector3(0.8, 0.9, 0.6), Vector3(0, 0.45, 0), STEEL, 0, true, 0.4)
			box(n, Vector3(0.5, 0.12, 0.36), Vector3(0, 0.96, 0), Color(0.16, 0.16, 0.15))
			for sx in [-0.12, 0.12]: cyl(n, 0.08, 0.02, Vector3(sx, 1.03, 0), Color(0.5, 0.42, 0.3))
			box(n, Vector3(0.04, 0.02, 0.04), Vector3(0.2, 1.03, 0.13), Color(0.9, 0.15, 0.1), 1.6)
		"stand":
			box(n, Vector3(0.6, 0.85, 0.5), Vector3(0, 0.425, 0), Color(0.3, 0.3, 0.28), 0, true, 0.3)
		"paper":
			box(n, Vector3(0.24, 0.01, 0.32), Vector3(0, 0.865, 0), PAPER, 0.25).rotation_degrees.y = 14
		"board":
			box(n, Vector3(1.4, 0.9, 0.04), Vector3(0, 1.5, 0), Color(0.3, 0.24, 0.16))
			for i in 6: box(n, Vector3(0.2, 0.26, 0.01), Vector3(-0.5 + (i % 3) * 0.5, 1.3 + (i / 3) * 0.4, 0.03), PAPER * (0.8 + 0.07 * i))
		"vent":
			box(n, Vector3(0.8, 0.5, 0.06), Vector3(0, 0.4, 0), DARK)
			for i in 5: box(n, Vector3(0.74, 0.02, 0.02), Vector3(0, 0.22 + i * 0.09, 0.04), STEEL, 0, false, 0.6)
		"pipes":
			for i in 3: cyl(n, 0.09 + 0.03 * i, 3.0, Vector3(-0.5 + i * 0.45, 1.5, 0), [RUST, STEEL, Color(0.2, 0.3, 0.25)][i], 0, i == 1)
			cyl(n, 0.12, 0.05, Vector3(-0.05, 1.2, 0.1), Color(0.7, 0.15, 0.1), 0, false, Vector3(90, 0, 0))
		"turbine":
			cyl(n, 1.1, 1.6, Vector3(0, 0.8, 0), Color(0.3, 0.33, 0.3), 0, true)
			cyl(n, 0.7, 0.9, Vector3(0, 2.0, 0), Color(0.4, 0.3, 0.12))
			cyl(n, 0.15, 3.0, Vector3(0, 1.5, 0), STEEL)
		"dish":
			cyl(n, 0.08, 1.6, Vector3(0, 0.8, 0), STEEL, 0, true)
			var d = cyl(n, 0.8, 0.08, Vector3(0, 1.75, 0.1), Color(0.6, 0.6, 0.58)); d.rotation_degrees.x = 60
			cyl(n, 0.02, 0.6, Vector3(0, 1.95, 0.4), DARK, 0, false, Vector3(60, 0, 0))
		"tram":
			box(n, Vector3(1.9, 0.3, 5.0), Vector3(0, 0.35, 0), DARK, 0, true, 0.5)
			box(n, Vector3(1.9, 0.1, 5.0), Vector3(0, 2.5, 0), Color(0.5, 0.42, 0.15), 0, false, 0.3)
			for sz in [-2.4, 2.4]: box(n, Vector3(1.9, 2.1, 0.1), Vector3(0, 1.5, sz), Color(0.5, 0.42, 0.15), 0, true, 0.3)
			for sz in [-1.6, 0, 1.6]: box(n, Vector3(0.08, 2.1, 0.5), Vector3(-0.91, 1.5, sz), Color(0.5, 0.42, 0.15), 0, false, 0.3)
			box(n, Vector3(0.1, 0.9, 5.0), Vector3(-0.9, 0.95, 0), Color(0.5, 0.42, 0.15), 0, true, 0.3)
			box(n, Vector3(1.2, 0.06, 0.3), Vector3(0, 2.4, 0), Color(1, 0.9, 0.7), 1.2)
		"aperture":
			# "The Door": a ring of signal emitters around a shielded shutter
			var ring = MeshInstance.new(); var tm = CylinderMesh.new(); tm.top_radius = 2.6; tm.bottom_radius = 2.6; tm.height = 0.5; tm.radial_segments = 32
			ring.mesh = tm; ring.material_override = mat(Color(0.18, 0.19, 0.2), 0, 0.4, 0.8); ring.rotation_degrees.x = 90; ring.translation = Vector3(0, 2.8, 0); n.add_child(ring)
			var core = cyl(n, 2.2, 0.56, Vector3(0, 2.8, 0), Color(0.02, 0.02, 0.03), 0, false, Vector3(90, 0, 0)); core.name = "core"
			for i in 12:
				var a = TAU * i / 12.0
				box(n, Vector3(0.18, 0.18, 0.7), Vector3(cos(a) * 2.6, 2.8 + sin(a) * 2.6, 0), Color(0.9, 0.3, 0.15), 0.9).name = "em%d" % i
			box(n, Vector3(6.0, 0.4, 1.2), Vector3(0, 0.2, 0), STEEL, 0, true, 0.6)
			box(n, Vector3(5.6, 5.4, 0.3), Vector3(0, 2.8, -0.2), Color(0, 0, 0, 0), 0, true).visible = false
		"figure":
			figure(n, Color(0.75, 0.76, 0.74) * tint, 1.0)
		"shade":
			figure(n, Color(0.5, 0.8, 0.9, 0.35), 1.0, 0.8)
		"glass":
			box(n, Vector3(1.9, 2.4, 0.06), Vector3(0, 1.2, 0), Color(0.6, 0.75, 0.8, 0.45), 0, true)
			box(n, Vector3(2.0, 0.08, 0.12), Vector3(0, 2.44, 0), STEEL); box(n, Vector3(2.0, 0.08, 0.12), Vector3(0, 0.04, 0), STEEL)
		"debris":
			var rng2 = RandomNumberGenerator.new(); rng2.randomize()
			for i in 5:
				var b = box(n, Vector3(rng2.randf_range(0.1, 0.45), rng2.randf_range(0.04, 0.2), rng2.randf_range(0.1, 0.4)),
					Vector3(rng2.randf_range(-0.6, 0.6), 0.06, rng2.randf_range(-0.6, 0.6)), [PAPER, RUST, STEEL, DARK][i % 4])
				b.rotation_degrees.y = rng2.randf_range(0, 180)
		"coat":
			box(n, Vector3(0.6, 0.06, 1.3), Vector3(0, 0.04, 0), Color(0.8, 0.8, 0.76)).rotation_degrees.y = 30
			box(n, Vector3(0.3, 0.05, 0.5), Vector3(0.3, 0.05, 0.4), Color(0.75, 0.75, 0.7)).rotation_degrees.y = -20
		"ladder":
			for sx in [-0.25, 0.25]: box(n, Vector3(0.06, 3.2, 0.06), Vector3(sx, 1.6, 0), STEEL, 0, false, 0.6)
			for i in 10: box(n, Vector3(0.5, 0.04, 0.04), Vector3(0, 0.25 + i * 0.3, 0), STEEL, 0, false, 0.6)
			box(n, Vector3(0.7, 0.3, 0.7), Vector3(0, 0.15, 0.2), Color(0, 0, 0, 0), 0, true).visible = false
		"valve":
			cyl(n, 0.1, 0.5, Vector3(0, 1.2, 0.1), STEEL, 0, true, Vector3(90, 0, 0))
			var wheel = cyl(n, 0.32, 0.05, Vector3(0, 1.2, 0.36), Color(0.6, 0.12, 0.08), 0, false, Vector3(90, 0, 0))
			for i in 3: box(n, Vector3(0.62, 0.04, 0.04), Vector3(0, 1.2, 0.37), Color(0.6, 0.12, 0.08)).rotation_degrees.z = i * 60
			cyl(n, 0.12, 3.0, Vector3(0, 1.5, -0.1), RUST)
			box(n, Vector3(0.05, 0.3, 0.05), Vector3(0, 1.52, 0.4), Color(0.95, 0.9, 0.7), 0.8)
		"lamp":
			cyl(n, 0.03, 1.5, Vector3(0, 0.75, 0), STEEL)
			box(n, Vector3(0.3, 0.2, 0.3), Vector3(0, 1.6, 0), Color(1.0, 0.9, 0.6), 2.0)
		_:
			box(n, Vector3(0.5, 0.5, 0.5), Vector3(0, 0.25, 0), Color(1, 0, 1))
	return n

static func figure(n: Spatial, col: Color, s := 1.0, emis := 0.0):
	# simple articulated humanoid; limbs are named so scripts can animate them
	var legc = Color(0.15, 0.16, 0.2, col.a)
	for sx in [-0.11, 0.11]:
		var leg = Spatial.new(); leg.name = "leg_l" if sx < 0 else "leg_r"; leg.translation = Vector3(sx, 0.9 * s, 0); n.add_child(leg)
		box(leg, Vector3(0.15, 0.9 * s, 0.16), Vector3(0, -0.45 * s, 0), legc, emis)
		var arm = Spatial.new(); arm.name = "arm_l" if sx < 0 else "arm_r"; arm.translation = Vector3(sx * 2.4, 1.45 * s, 0); n.add_child(arm)
		box(arm, Vector3(0.1, 0.68 * s, 0.11), Vector3(0, -0.32 * s, 0), col, emis)
	box(n, Vector3(0.42, 0.62 * s, 0.24), Vector3(0, 1.2 * s, 0), col, emis)
	box(n, Vector3(0.46, 0.5 * s, 0.26), Vector3(0, 0.82 * s, 0), col, emis)   # coat skirt
	var head = MeshInstance.new(); var sm = SphereMesh.new(); sm.radius = 0.12; sm.height = 0.27
	head.mesh = sm; head.material_override = mat(Color(0.72, 0.6, 0.52, col.a), emis); head.translation = Vector3(0, 1.67 * s, 0); head.name = "head"
	n.add_child(head)

static func listener_body() -> Spatial:
	# The Listener: too tall, too thin, and where a face should be - a shallow black dish that turns toward sound.
	var n = Spatial.new()
	var c = Color(0.015, 0.015, 0.02)
	var m = mat(c, 0, 1.0, 0.0)
	for sx in [-0.13, 0.13]:
		var leg = Spatial.new(); leg.name = "leg_l" if sx < 0 else "leg_r"; leg.translation = Vector3(sx, 1.35, 0); n.add_child(leg)
		box(leg, Vector3(0.1, 0.72, 0.1), Vector3(0, -0.36, 0.05), c).material_override = m
		box(leg, Vector3(0.08, 0.7, 0.08), Vector3(0, -1.0, -0.02), c).material_override = m
		var arm = Spatial.new(); arm.name = "arm_l" if sx < 0 else "arm_r"; arm.translation = Vector3(sx * 2.3, 2.2, 0); n.add_child(arm)
		box(arm, Vector3(0.07, 0.85, 0.07), Vector3(0, -0.42, 0), c).material_override = m
		box(arm, Vector3(0.055, 0.95, 0.055), Vector3(0, -1.3, 0.08), c).material_override = m
		for f in 3: box(arm, Vector3(0.015, 0.3, 0.015), Vector3(-0.03 + f * 0.03, -1.9, 0.1), c).material_override = m
	box(n, Vector3(0.38, 0.5, 0.2), Vector3(0, 2.05, 0), c).material_override = m
	box(n, Vector3(0.26, 0.5, 0.16), Vector3(0, 1.6, 0.02), c).material_override = m
	for i in 5: box(n, Vector3(0.34 - i * 0.02, 0.02, 0.22), Vector3(0, 1.85 + i * 0.09, 0), Color(0.05, 0.05, 0.06)).material_override = m
	var neck = Spatial.new(); neck.name = "neck"; neck.translation = Vector3(0, 2.35, 0); n.add_child(neck)
	box(neck, Vector3(0.07, 0.3, 0.07), Vector3(0, 0.12, 0), c).material_override = m
	var dish = MeshInstance.new(); var dm = CylinderMesh.new(); dm.top_radius = 0.23; dm.bottom_radius = 0.1; dm.height = 0.12; dm.radial_segments = 20
	dish.mesh = dm; dish.material_override = m; dish.rotation_degrees.x = 90; dish.translation = Vector3(0, 0.36, 0.05); neck.add_child(dish)
	var pit = MeshInstance.new(); var pm = CylinderMesh.new(); pm.top_radius = 0.19; pm.bottom_radius = 0.19; pm.height = 0.01; pm.radial_segments = 20
	pit.mesh = pm; pit.name = "pit"; pit.rotation_degrees.x = 90; pit.translation = Vector3(0, 0.36, 0.115)
	pit.material_override = mat(Color(0.5, 0.05, 0.03), 0.0); neck.add_child(pit)
	return n
