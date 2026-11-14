extends Reference
# Atmosphere effects built in code: light shafts, dust, sparks, steam, drips, water.

const CONE_SHADER = """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 col : hint_color = vec4(1.0);
uniform float energy = 1.0;
uniform float height = 3.0;
varying float vy;
varying float vdist;
void vertex() {
	vy = VERTEX.y / height + 0.5;          // 0 at the floor end, 1 at the fixture
	vdist = length((MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
}
void fragment() {
	float facing = pow(clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 1.6);
	float grad = pow(clamp(vy, 0.0, 1.0), 1.8);   // clamp: pow() of a tiny negative is NaN (black pixels)
	float near = smoothstep(0.6, 3.5, vdist);
	ALBEDO = col.rgb * energy * 0.07 * facing * grad * near;
}
"""

const WATER_SHADER = """
shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;
uniform sampler2D n1 : hint_normal;
uniform sampler2D n2 : hint_normal;
uniform vec4 deep : hint_color = vec4(0.015, 0.06, 0.06, 1.0);
uniform float scale = 0.18;
void fragment() {
	vec3 wp = (CAMERA_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 uv = wp.xz * scale;
	vec3 a = texture(n1, uv + vec2(TIME * 0.018, TIME * 0.011)).rgb;
	vec3 b = texture(n2, uv * 1.9 - vec2(TIME * 0.013, -TIME * 0.017)).rgb;
	NORMALMAP = mix(a, b, 0.5);
	NORMALMAP_DEPTH = 0.55;
	ALBEDO = deep.rgb;
	ROUGHNESS = 0.04;
	SPECULAR = 0.9;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALPHA = mix(0.78, 0.95, fres);
}
"""

static func cone(parent: Node, pos: Vector3, h: float, col: Color) -> MeshInstance:
	var mi = MeshInstance.new()
	mi.mesh = _open_cone(0.22, 1.7, h, 20)
	var sm = ShaderMaterial.new(); sm.shader = Shader.new(); sm.shader.code = CONE_SHADER
	sm.set_shader_param("col", col); sm.set_shader_param("height", h)
	mi.material_override = sm; mi.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF
	mi.translation = pos - Vector3(0, h / 2.0, 0)
	parent.add_child(mi)
	return mi

static func _open_cone(r_top: float, r_bot: float, h: float, seg: int) -> ArrayMesh:
	# side wall only (no caps), centred on the origin like CylinderMesh
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in seg:
		var a0 = TAU * i / seg; var a1 = TAU * (i + 1) / seg
		var t0 = Vector3(cos(a0) * r_top, h / 2, sin(a0) * r_top); var t1 = Vector3(cos(a1) * r_top, h / 2, sin(a1) * r_top)
		var b0 = Vector3(cos(a0) * r_bot, -h / 2, sin(a0) * r_bot); var b1 = Vector3(cos(a1) * r_bot, -h / 2, sin(a1) * r_bot)
		for v in [t0, b1, b0, t0, t1, b1]:
			st.add_normal(Vector3(v.x, 0, v.z).normalized()); st.add_vertex(v)
	return st.commit()

static func fixture(parent: Node, pos: Vector3, col: Color, mat_housing: Material) -> Spatial:
	# fluorescent fitting: metal housing, diffuser, end caps
	var n = Spatial.new(); n.translation = pos; parent.add_child(n)
	var housing = MeshInstance.new(); var hb = CubeMesh.new(); hb.size = Vector3(1.25, 0.09, 0.32); housing.mesh = hb
	housing.material_override = mat_housing; housing.translation = Vector3(0, 0.0, 0); n.add_child(housing)
	var diff = MeshInstance.new(); var db = CubeMesh.new(); db.size = Vector3(1.12, 0.03, 0.2); diff.mesh = db
	var dm = SpatialMaterial.new(); dm.albedo_color = col; dm.emission_enabled = true; dm.emission = col; dm.emission_energy = 2.2
	diff.material_override = dm; diff.translation = Vector3(0, -0.055, 0); diff.name = "diffuser"; n.add_child(diff)
	for sx in [-0.6, 0.6]:
		var cap = MeshInstance.new(); var cb = CubeMesh.new(); cb.size = Vector3(0.05, 0.1, 0.32); cap.mesh = cb
		cap.material_override = mat_housing; cap.translation = Vector3(sx, -0.02, 0); n.add_child(cap)
	return n

static func dust(parent: Spatial) -> CPUParticles:
	# motes that catch the flashlight beam
	var p = CPUParticles.new(); p.amount = 140; p.lifetime = 9.0; p.preprocess = 9.0
	p.emission_shape = CPUParticles.EMISSION_SHAPE_BOX; p.emission_box_extents = Vector3(4, 1.6, 4)
	p.gravity = Vector3(0, -0.01, 0); p.initial_velocity = 0.04; p.spread = 180; p.local_coords = false
	p.scale_amount = 1.0; p.scale_amount_random = 0.6
	var q = QuadMesh.new(); q.size = Vector2(0.014, 0.014)
	var m = SpatialMaterial.new(); m.albedo_color = Color(0.9, 0.88, 0.8, 0.55); m.flags_transparent = true
	m.params_billboard_mode = SpatialMaterial.BILLBOARD_ENABLED; m.roughness = 1.0
	q.material = m; p.mesh = q
	p.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)
	return p

static func sparks(parent: Node, pos: Vector3) -> CPUParticles:
	var p = CPUParticles.new(); p.amount = 24; p.lifetime = 0.7; p.one_shot = true; p.explosiveness = 0.9; p.emitting = false
	p.direction = Vector3(0, -1, 0); p.spread = 55; p.initial_velocity = 2.4; p.initial_velocity_random = 0.6
	p.gravity = Vector3(0, -9.8, 0); p.local_coords = false
	var q = QuadMesh.new(); q.size = Vector2(0.03, 0.03)
	var m = SpatialMaterial.new(); m.flags_unshaded = true; m.albedo_color = Color(1.0, 0.75, 0.35)
	m.params_billboard_mode = SpatialMaterial.BILLBOARD_ENABLED
	q.material = m; p.mesh = q; p.translation = pos
	p.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)
	return p

static func steam(parent: Node, pos: Vector3) -> CPUParticles:
	var p = CPUParticles.new(); p.amount = 28; p.lifetime = 3.2; p.translation = pos
	p.direction = Vector3(0, 1, 0); p.spread = 18; p.initial_velocity = 0.7; p.gravity = Vector3(0, 0.15, 0)
	p.scale_amount = 1.0; p.scale_amount_random = 0.5; p.local_coords = false
	var curve = Curve.new(); curve.add_point(Vector2(0, 0.3)); curve.add_point(Vector2(1, 1.6)); p.scale_amount_curve = curve
	var q = QuadMesh.new(); q.size = Vector2(0.5, 0.5)
	var m = SpatialMaterial.new(); m.albedo_color = Color(0.75, 0.78, 0.8, 0.07); m.flags_transparent = true
	m.params_billboard_mode = SpatialMaterial.BILLBOARD_ENABLED; m.flags_unshaded = false
	q.material = m; p.mesh = q
	p.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)
	return p

static func drips(parent: Node, pos: Vector3, h: float) -> CPUParticles:
	var p = CPUParticles.new(); p.amount = 6; p.lifetime = h / 4.0 + 0.2; p.translation = pos
	p.emission_shape = CPUParticles.EMISSION_SHAPE_BOX; p.emission_box_extents = Vector3(0.6, 0.0, 0.6)
	p.direction = Vector3(0, -1, 0); p.spread = 0; p.initial_velocity = 0.5; p.gravity = Vector3(0, -9.8, 0); p.local_coords = false
	var q = QuadMesh.new(); q.size = Vector2(0.008, 0.07)
	var m = SpatialMaterial.new(); m.albedo_color = Color(0.7, 0.85, 0.9, 0.6); m.flags_transparent = true
	m.params_billboard_mode = SpatialMaterial.BILLBOARD_FIXED_Y; m.roughness = 0.1
	q.material = m; p.mesh = q
	p.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)
	return p

static func water_material(nt1: Texture, nt2: Texture) -> ShaderMaterial:
	var sm = ShaderMaterial.new(); sm.shader = Shader.new(); sm.shader.code = WATER_SHADER
	sm.set_shader_param("n1", nt1); sm.set_shader_param("n2", nt2)
	return sm
