extends Spatial
# The Listener's body for the high-quality path: original rigged model (tools/blender/listener.py) with baked
# skin maps, a translucent dish 'ear' and five animations (idle, walk, run, listen, attack).
var anim: AnimationPlayer
var skel: Skeleton
var meshes := []
var current := ""

func _ready():
	var s = load("res://assets/creature/listener.gltf").instance()
	add_child(s)
	anim = _find(s, "AnimationPlayer"); skel = _find(s, "Skeleton")
	for n in ["walk", "run", "idle", "listen"]:
		if anim and anim.has_animation(n): anim.get_animation(n).loop = true
	_collect(s)
	var skin = SpatialMaterial.new()
	skin.albedo_texture = load("res://assets/creature/listener_albedo.png"); skin.albedo_color = Color(0.58, 0.56, 0.54)
	skin.normal_enabled = true; skin.normal_texture = load("res://assets/creature/listener_normal.png"); skin.normal_scale = 1.3
	var orm = load("res://assets/creature/listener_orm.png")
	skin.roughness_texture = orm; skin.roughness_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_GREEN; skin.roughness = 1.0
	skin.ao_enabled = true; skin.ao_texture = orm; skin.ao_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_RED; skin.ao_light_affect = 0.4
	skin.metallic = 0.0; skin.metallic_specular = 0.6
	skin.clearcoat_enabled = true; skin.clearcoat = 0.3; skin.clearcoat_gloss = 0.75         # wet sheen
	skin.subsurf_scatter_enabled = true; skin.subsurf_scatter_strength = 0.18
	skin.rim_enabled = true; skin.rim = 0.12; skin.rim_tint = 0.4
	var mem = SpatialMaterial.new()
	mem.albedo_texture = load("res://assets/creature/dish_albedo.png"); mem.albedo_color = Color(0.5, 0.36, 0.34)
	var dorm = load("res://assets/creature/dish_orm.png")
	mem.roughness_texture = dorm; mem.roughness_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_GREEN; mem.roughness = 0.9
	mem.ao_enabled = true; mem.ao_texture = dorm; mem.ao_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_RED
	mem.transmission_enabled = true; mem.transmission = Color(0.32, 0.07, 0.05)               # light glows through the membrane
	mem.subsurf_scatter_enabled = true; mem.subsurf_scatter_strength = 0.5
	mem.clearcoat_enabled = true; mem.clearcoat = 0.5; mem.clearcoat_gloss = 0.8
	mem.params_cull_mode = SpatialMaterial.CULL_DISABLED
	for mi in meshes:
		for i in mi.mesh.get_surface_count():
			var m = mi.mesh.surface_get_material(i)
			var nm = m.resource_name if m else ""
			mi.set_surface_material(i, mem if "Membrane" in nm else skin)
	play("idle")

func play(name: String, speed := 1.0, blend := 0.25):
	if anim == null or not anim.has_animation(name): return
	anim.playback_speed = speed
	if name != current:
		anim.play(name, blend); current = name

func _collect(n):
	if n is MeshInstance: meshes.append(n)
	for c in n.get_children(): _collect(c)

func _find(n, cls: String):
	if n.get_class() == cls: return n
	for c in n.get_children():
		var r = _find(c, cls)
		if r: return r
	return null
