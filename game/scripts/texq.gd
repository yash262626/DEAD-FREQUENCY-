extends Reference
# Texture quality. "Half" swaps every texture of 1024 px or more in a scene for a copy built from its own mip chain
# minus the top level: exactly half the resolution and a quarter of the video memory, with no decoding or
# re-compression (the GPU-compressed blocks are reused as they are). Applied when a level or the Listener loads.
# (Godot 3.5's VisualServer.texture_set_shrink_all_x2_on_set_data crashes on compressed textures, so it is not used.)

static func apply(root: Node):
	if int(G.settings.get("textures", 1)) != 0: return
	_walk(root, {})

static func _walk(n: Node, cache: Dictionary):
	if n is GeometryInstance:
		if n.material_override: _mat(n.material_override, cache)
		if n is MeshInstance and n.mesh:
			for i in n.mesh.get_surface_count():
				if n.get_surface_material(i): _mat(n.get_surface_material(i), cache)
				if n.mesh.surface_get_material(i): _mat(n.mesh.surface_get_material(i), cache)
	for c in n.get_children(): _walk(c, cache)

static func _mat(m: Material, cache: Dictionary):
	if cache.has(m): return
	cache[m] = true
	if m is SpatialMaterial:
		for i in SpatialMaterial.TEXTURE_MAX:
			var t = m.get_texture(i)
			if t: m.set_texture(i, half(t, cache))
	elif m is ShaderMaterial and m.shader:
		for p in VisualServer.shader_get_param_list(m.shader.get_rid()):
			var t = m.get_shader_param(p.name)
			if t is Texture: m.set_shader_param(p.name, half(t, cache))
	if m.next_pass: _mat(m.next_pass, cache)

static func half(t: Texture, cache := {}) -> Texture:
	if cache.has(t): return cache[t]
	var out = t
	if t is StreamTexture and t.get_width() >= 1024 and t.get_height() >= 64:
		var img = t.get_data()
		if img and img.has_mipmaps():
			var d = img.get_data(); var off = img.get_mipmap_offset(1)
			var im2 = Image.new()
			im2.create_from_data(img.get_width() / 2, img.get_height() / 2, true, img.get_format(), d.subarray(off, d.size() - 1))
			out = ImageTexture.new(); out.create_from_image(im2, t.flags)
	cache[t] = out; cache[out] = out
	return out
