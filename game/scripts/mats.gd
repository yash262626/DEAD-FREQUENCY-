extends Node
# Material library. Level surfaces and props use CC0 PBR texture sets from ambientCG
# (see docs/THIRD_PARTY_NOTICES.md), imported by tools/import_cc0.py into res://textures/<id>/.
# On the Low preset everything falls back to flat colours for speed.

var _tex := {}
var _mats := {}

func enabled() -> bool:
	return int(G.settings.quality) >= 1

func tex(path: String) -> Texture:
	if not _tex.has(path):
		_tex[path] = load(path) if ResourceLoader.exists(path) else null
		if _tex[path] == null: push_warning("missing texture (not imported?): " + path)
	return _tex[path]

func surface(id: String, tint: Color, scale := 0.5, world := true, normal_scale := 1.0) -> SpatialMaterial:
	var key = "%s|%s|%.2f|%s|%.2f" % [id, tint.to_html(), scale, world, normal_scale]
	if _mats.has(key): return _mats[key]
	var base = "res://textures/%s/" % id
	var m = SpatialMaterial.new()
	m.albedo_texture = tex(base + "albedo.jpg"); m.albedo_color = tint
	m.normal_enabled = true; m.normal_texture = tex(base + "normal.jpg"); m.normal_scale = normal_scale
	var orm = tex(base + "orm.jpg")
	m.roughness = 1.0; m.roughness_texture = orm; m.roughness_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_GREEN
	m.metallic = 1.0 if orm else 0.0; m.metallic_texture = orm; m.metallic_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_BLUE
	m.ao_enabled = true; m.ao_texture = orm; m.ao_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_RED; m.ao_light_affect = 0.25
	m.uv1_triplanar = true; m.flags_world_triplanar = world; m.uv1_scale = Vector3(scale, scale, scale)
	m.uv1_triplanar_sharpness = 4.0
	_mats[key] = m
	return m

static func hue_tint(c: Color, bright := 0.85) -> Color:
	# keep the palette's hue, drop its darkness (the texture supplies value and detail)
	var mx = max(c.r, max(c.g, c.b))
	if mx <= 0.001: return Color(bright, bright, bright)
	return Color(c.r / mx * bright, c.g / mx * bright, c.b / mx * bright)

func prop(col: Color, rough: float, metal: float) -> SpatialMaterial:
	# choose a texture set from the flat colour the prop library asked for
	var id = "PaintedPlaster017"; var scale = 1.2; var t = col * 1.25
	if metal >= 0.35:
		id = "Metal063" if (col.r > col.g * 1.35 and col.r < 0.5) else "Metal027"
		t = col * 1.6
	elif abs(col.r - 0.30) < 0.06 and abs(col.g - 0.22) < 0.05 and abs(col.b - 0.15) < 0.05:
		id = "Wood096"; t = Color(0.95, 0.85, 0.75); scale = 1.0
	elif col.r > 0.75 and col.g > 0.72 and col.b > 0.6 and col.r - col.b < 0.2:
		id = "Cardboard002"; t = Color(1.05, 1.05, 1.0); scale = 2.0
	elif rough >= 0.8 and col.r < 0.2 and col.g < 0.2 and col.b < 0.2:
		id = "Rubber004"; t = col * 3.0
	t.a = 1.0
	t = Color(clamp(t.r, 0, 1.6), clamp(t.g, 0, 1.6), clamp(t.b, 0, 1.6))
	return surface(id, t, scale, false, 0.8)
