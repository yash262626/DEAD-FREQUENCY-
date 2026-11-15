extends Spatial
# The Listener's body for the high-quality path — version 3 (tools/blender/listener_v2.py): original sculpted
# creature with 4K baked pale, veined skin maps, a translucent trumpet-shaped membrane 'ear', keratin claws, a 78-bone rig, three LODs
# (switched by camera distance; Godot 3 has no automatic LOD) and seven animations:
# idle, listen, walk, run, search, crawl, attack.
var anim: AnimationPlayer
var skel: Skeleton
var lods := []          # [LOD0, LOD1, LOD2] MeshInstances
var membrane: MeshInstance
var current := ""
var lod_level := -1
const LOD_DIST = [7.0, 16.0]

func _ready():
	var s = load("res://assets/creature2/listener2.gltf").instance()
	s.scale = Vector3(1.1, 1.1, 1.1)          # about 2.5 m to the top of the membrane
	add_child(s)
	anim = _find(s, "AnimationPlayer"); skel = _find(s, "Skeleton")
	for n in ["walk", "run", "idle", "listen", "search", "crawl"]:
		if anim and anim.has_animation(n): anim.get_animation(n).loop = true
	var meshes = []
	_collect(s, meshes)
	for i in 3:
		for mi in meshes:
			if mi.name.find("LOD%d" % i) >= 0: lods.append(mi)
	for mi in meshes:
		if mi.name.find("Membrane") >= 0: membrane = mi
	var skin = SpatialMaterial.new()
	skin.albedo_texture = load("res://assets/creature2/skin_albedo.jpg"); skin.albedo_color = Color(0.93, 0.9, 0.88)   # pale, corpse-white
	skin.normal_enabled = true; skin.normal_texture = load("res://assets/creature2/skin_nor.png"); skin.normal_scale = 1.5
	var orm = load("res://assets/creature2/skin_orm.jpg")
	skin.roughness_texture = orm; skin.roughness_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_GREEN; skin.roughness = 1.0
	skin.ao_enabled = true; skin.ao_texture = orm; skin.ao_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_RED; skin.ao_light_affect = 0.5
	skin.metallic_specular = 0.55
	skin.clearcoat_enabled = true; skin.clearcoat = 0.7; skin.clearcoat_gloss = 0.9           # wet, mucous sheen
	skin.subsurf_scatter_enabled = true; skin.subsurf_scatter_strength = 0.45                 # translucent: light bleeds through thin tissue
	skin.transmission_enabled = true; skin.transmission = Color(0.2, 0.05, 0.04)
	var claw = SpatialMaterial.new()
	claw.albedo_texture = load("res://assets/creature2/claws_albedo.jpg")
	var corm = load("res://assets/creature2/claws_orm.jpg")
	claw.roughness_texture = corm; claw.roughness_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_GREEN; claw.roughness = 1.0
	claw.ao_enabled = true; claw.ao_texture = corm; claw.ao_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_RED
	claw.metallic_specular = 0.7; claw.clearcoat_enabled = true; claw.clearcoat = 0.4
	var mem = SpatialMaterial.new()
	mem.albedo_texture = load("res://assets/creature2/membrane_albedo.jpg"); mem.albedo_color = Color(0.86, 0.78, 0.76)
	var morm = load("res://assets/creature2/membrane_orm.jpg")
	mem.roughness_texture = morm; mem.roughness_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_GREEN; mem.roughness = 1.0
	mem.ao_enabled = true; mem.ao_texture = morm; mem.ao_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_RED
	mem.transmission_enabled = true; mem.transmission = Color(0.26, 0.06, 0.045)            # the torch glows through the membrane
	mem.subsurf_scatter_enabled = true; mem.subsurf_scatter_strength = 0.45
	mem.clearcoat_enabled = true; mem.clearcoat = 0.8; mem.clearcoat_gloss = 0.92
	mem.params_cull_mode = SpatialMaterial.CULL_DISABLED
	for mi in meshes:
		for i in mi.mesh.get_surface_count():
			var m = mi.mesh.surface_get_material(i)
			var nm = m.resource_name if m else ""
			var use = skin
			if "Claw" in nm: use = claw
			elif "Membrane" in nm or "Cartilage" in nm: use = mem
			mi.set_surface_material(i, use)
	load("res://scripts/texq.gd").apply(self)            # texture quality (Half: the 4K skin maps load at 2K)
	_set_lod(0)
	play("idle")

func _process(_dt):
	var cam = get_viewport().get_camera()
	if cam == null or lods.size() < 3: return
	var d = cam.global_transform.origin.distance_to(global_transform.origin)
	_set_lod(0 if d < LOD_DIST[0] else (1 if d < LOD_DIST[1] else 2))

func _set_lod(l: int):
	if l == lod_level or lods.size() < 3: return
	lod_level = l
	for i in 3: lods[i].visible = i == l

func play(name: String, speed := 1.0, blend := 0.25):
	if anim == null or not anim.has_animation(name): return
	anim.playback_speed = speed
	if name != current:
		anim.play(name, blend); current = name

func _collect(n, out: Array):
	if n is MeshInstance: out.append(n)
	for c in n.get_children(): _collect(c, out)

func _find(n, cls: String):
	if n.get_class() == cls: return n
	for c in n.get_children():
		var r = _find(c, cls)
		if r: return r
	return null
