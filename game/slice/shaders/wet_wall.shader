shader_type spatial;
// Wet concrete walls: water runs down in streaks (a world-space mask, so it flows across mesh seams) and gathers at
// the foot of the wall. Wet areas darken, turn glossy and lose some normal detail, so the lamps streak across them.
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;
uniform sampler2D albedo_tex : hint_albedo;
uniform sampler2D normal_tex : hint_normal;
uniform sampler2D arm_tex : hint_white;
uniform sampler2D streak_tex : hint_white;
uniform vec4 tint : hint_color = vec4(1.0);
uniform float uv_scale = 0.3;
uniform float streak_scale = 0.32;
uniform float wetness = 1.0;
uniform float foot_height = 0.5;
uniform float normal_scale = 1.0;
uniform float base_wet = 0.24;      // a film of moisture over the whole wall: it catches the reflections
varying vec3 wpos;
varying vec3 wnrm;
void vertex() {
	wpos = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((WORLD_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	vec2 uv = UV * uv_scale;
	vec3 arm = texture(arm_tex, uv).rgb;
	float along = abs(wnrm.x) > abs(wnrm.z) ? wpos.z : wpos.x;
	float st = texture(streak_tex, vec2(along * streak_scale, wpos.y * streak_scale * 0.5)).r;
	float foot = 1.0 - smoothstep(0.0, foot_height, wpos.y);
	float wet = clamp((st * 0.9 + foot * 0.8) * wetness + base_wet, 0.0, 1.0);
	ALBEDO = texture(albedo_tex, uv).rgb * tint.rgb * mix(1.0, 0.5, wet);
	ROUGHNESS = mix(arm.g, 0.06, wet);
	METALLIC = 0.0;
	SPECULAR = mix(0.5, 0.72, wet);
	AO = arm.r;
	AO_LIGHT_AFFECT = 0.25;
	NORMALMAP = mix(texture(normal_tex, uv).rgb, vec3(0.5, 0.5, 1.0), wet * 0.55);
	NORMALMAP_DEPTH = normal_scale;
}
