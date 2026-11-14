extends Reference
# High-quality first-person models: gloved hands with the flashlight and the HX-7 receiver
# (tools/blender/fp_items.py). build() returns the two rigs plus the materials the player animates.

static func _m(albedo: Color, rough: float, metal := 0.0) -> SpatialMaterial:
	var m = SpatialMaterial.new(); m.albedo_color = albedo; m.roughness = rough; m.metallic = metal
	return m

static func _tex(m: SpatialMaterial, path: String, normal_path := "", scale := 1.0, nscale := 1.0) -> SpatialMaterial:
	if path != "": m.albedo_texture = load(path)
	if normal_path != "":
		m.normal_enabled = true; m.normal_texture = load(normal_path); m.normal_scale = nscale
	m.uv1_scale = Vector3(scale, scale, scale)
	return m

static func materials() -> Dictionary:
	var lens = _m(Color(0.75, 0.82, 0.9, 0.35), 0.05); lens.flags_transparent = true; lens.metallic_specular = 0.9
	lens.emission_enabled = true; lens.emission = Color(1.0, 0.96, 0.85); lens.emission_energy = 0.0
	var lcd = _tex(_m(Color(1, 1, 1), 0.3), "res://assets/fp/lcd.png")
	lcd.emission_enabled = true; lcd.emission_texture = lcd.albedo_texture; lcd.emission_energy = 1.0
	var meter = _tex(_m(Color(1, 1, 1), 0.4), "res://slice/tex/meter.png"); meter.emission_enabled = true; meter.emission_texture = meter.albedo_texture; meter.emission_energy = 0.4
	var glove = _tex(_m(Color(0.055, 0.05, 0.045), 0.5), "", "res://assets/fp/leather_nor.png", 40.0, 0.8)
	glove.clearcoat_enabled = true; glove.clearcoat = 0.25; glove.clearcoat_gloss = 0.5
	return {
		"M_TorchAlu": _m(Color(0.06, 0.062, 0.068), 0.36, 0.85),
		"M_TorchKnurl": _tex(_m(Color(0.06, 0.062, 0.068), 0.42, 0.85), "", "res://assets/fp/knurl_nor.png", 42.0, 1.4),
		"M_KnobKnurl": _tex(_m(Color(0.03, 0.03, 0.03), 0.55), "", "res://assets/fp/knurl_nor.png", 42.0, 1.2),
		"M_RubberDark": _tex(_m(Color(0.04, 0.04, 0.042), 0.7), "", "res://textures/Rubber004/normal.jpg", 30.0, 0.6),
		"M_Chrome": _m(Color(0.85, 0.86, 0.88), 0.07, 1.0),
		"M_LEDEmit": lens,
		"M_Lens": lens,
		"M_Steel": _m(Color(0.6, 0.6, 0.62), 0.3, 1.0),
		"M_Glove": glove,
		"M_Cuff": _tex(_m(Color(0.07, 0.07, 0.08), 0.95), "", "res://textures/Fabric086/normal.jpg", 30.0, 1.0),
		"M_Sleeve": _tex(_m(Color(0.86, 0.34, 0.08), 0.9), "res://textures/Fabric086/albedo.jpg", "res://textures/Fabric086/normal.jpg", 9.0, 1.0),
		"M_Reflective": _m(Color(0.62, 0.64, 0.64), 0.25, 0.6),
		"M_RxRubber": _tex(_m(Color(0.11, 0.125, 0.1), 0.62), "", "res://textures/Rubber004/normal.jpg", 25.0, 0.7),
		"M_RxPlate": _tex(_m(Color(0.7, 0.71, 0.72), 0.38, 1.0), "res://textures/Metal063/albedo.jpg", "", 10.0),
		"M_RxLCD": lcd,
		"M_RxLabel": _tex(_m(Color(1, 1, 1), 0.6), "res://assets/fp/label_hx7.png"),
		"M_RxGrille": _tex(_m(Color(1, 1, 1), 0.7), "res://assets/fp/grille.png", "", 1.0),
		"M_RxMeter": meter,
	}

static func _apply(n: Node, mats: Dictionary):
	if n is MeshInstance:
		n.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF
		for i in n.mesh.get_surface_count():
			var sm = n.mesh.surface_get_material(i)
			if sm and mats.has(sm.resource_name): n.set_surface_material(i, mats[sm.resource_name])
	for c in n.get_children(): _apply(c, mats)

static func build() -> Dictionary:
	var mats = materials()
	var torch = load("res://assets/fp/fp_torch.gltf").instance()
	var radio = load("res://assets/fp/fp_radio.gltf").instance()
	_apply(torch, mats); _apply(radio, mats)
	return {"torch": torch, "radio": radio, "lens": mats.M_Lens, "screen": mats.M_RxLCD}
