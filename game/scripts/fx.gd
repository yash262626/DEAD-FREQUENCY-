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

# A shaft of light in dusty air: additive, faded where it meets geometry (scene depth), near the camera and
# along its length, with slowly drifting density so it never looks like a solid cone.
const BEAM_SHADER = """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 col : hint_color = vec4(1.0);
uniform float energy = 0.05;
uniform float length = 3.0;
uniform float soft = 0.45;
varying float t;
varying vec3 wpos;
float h(vec3 p){ return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }
float vnoise(vec3 p){
	vec3 i = floor(p); vec3 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h(i), h(i + vec3(1,0,0)), f.x), mix(h(i + vec3(0,1,0)), h(i + vec3(1,1,0)), f.x), f.y),
	           mix(mix(h(i + vec3(0,0,1)), h(i + vec3(1,0,1)), f.x), mix(h(i + vec3(0,1,1)), h(i + vec3(1,1,1)), f.x), f.y), f.z);
}
void vertex() {
	t = clamp(-VERTEX.y / length, 0.0, 1.0);
	wpos = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).r;
	vec4 ndc = vec4(SCREEN_UV * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
	vec4 vp = INV_PROJECTION_MATRIX * ndc; vp.xyz /= vp.w;
	float fade = clamp((VERTEX.z - vp.z) / soft, 0.0, 1.0);    // distance in front of the scene surface
	float facing = pow(clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 1.4);
	float along = pow(clamp(1.0 - t, 0.0, 1.0), 1.5);
	float near = smoothstep(0.25, 1.6, -VERTEX.z);
	float dust = 0.65 + 0.35 * vnoise(wpos * 1.7 + vec3(0.0, TIME * 0.08, TIME * 0.05));
	ALBEDO = col.rgb * energy * facing * along * fade * near * dust;
}
"""

static func beam(parent: Node, r0: float, r1: float, length: float, col: Color, energy: float) -> MeshInstance:
	# apex ring at the origin, opening along -Y
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg = 24
	for i in seg:
		var a0 = TAU * i / seg; var a1 = TAU * (i + 1) / seg
		var t0 = Vector3(cos(a0) * r0, 0, sin(a0) * r0); var t1 = Vector3(cos(a1) * r0, 0, sin(a1) * r0)
		var b0 = Vector3(cos(a0) * r1, -length, sin(a0) * r1); var b1 = Vector3(cos(a1) * r1, -length, sin(a1) * r1)
		for v in [t0, b1, b0, t0, t1, b1]:
			st.add_normal(Vector3(v.x, 0, v.z).normalized()); st.add_vertex(v)
	var mi = MeshInstance.new(); mi.mesh = st.commit()
	var sm = ShaderMaterial.new(); sm.shader = Shader.new(); sm.shader.code = BEAM_SHADER
	sm.set_shader_param("col", col); sm.set_shader_param("energy", energy); sm.set_shader_param("length", length)
	mi.material_override = sm; mi.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF
	mi.use_in_baked_light = false
	parent.add_child(mi)
	return mi

const GRADE_SHADER = """
shader_type canvas_item;
uniform float grain = 0.022;
uniform float vignette = 0.22;
uniform float ca = 0.0014;
uniform vec3 lift = vec3(0.006, 0.010, 0.014);
uniform vec3 gain = vec3(1.05, 1.0, 0.94);
uniform float contrast = 1.07;
uniform float sat = 0.86;
float h(vec2 p){ return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 uv = SCREEN_UV; vec2 d = uv - 0.5; float r = dot(d, d);
	vec3 c;
	c.r = texture(SCREEN_TEXTURE, uv + d * ca * 2.0).r;
	c.g = texture(SCREEN_TEXTURE, uv).g;
	c.b = texture(SCREEN_TEXTURE, uv - d * ca * 2.0).b;
	float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
	c = mix(vec3(l), c, sat);
	c = (c - 0.5) * contrast + 0.5;
	c = c * mix(vec3(1.0), gain, smoothstep(0.1, 0.8, l)) + lift * (1.0 - smoothstep(0.0, 0.35, l));
	c *= 1.0 - vignette * smoothstep(0.06, 0.55, r);
	c += (h(uv * vec2(1931.0, 1087.0) + fract(TIME * 7.0)) - 0.5) * grain;
	COLOR = vec4(max(c, vec3(0.0)), 1.0);
}
"""

static func grade(parent: Node) -> CanvasLayer:
	var cl = CanvasLayer.new(); cl.layer = 1; parent.add_child(cl)
	var cr = ColorRect.new(); cr.anchor_right = 1.0; cr.anchor_bottom = 1.0; cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sm = ShaderMaterial.new(); sm.shader = Shader.new(); sm.shader.code = GRADE_SHADER; cr.material = sm
	cl.add_child(cr)
	return cl

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
