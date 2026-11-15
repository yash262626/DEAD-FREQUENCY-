shader_type spatial;
// PBR surface (albedo / normal / AO-roughness-metal) with world-space wetness: pools and streaks darken the
// albedo, flatten the normal and drop roughness so the floor mirrors the lamps (screen-space + probe reflections).
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;
uniform sampler2D albedo_tex : hint_albedo;
uniform sampler2D normal_tex : hint_normal;
uniform sampler2D arm_tex : hint_white;
uniform sampler2D wet_mask : hint_white;
uniform vec4 tint : hint_color = vec4(1.0);
uniform float uv_scale = 0.38;
uniform float mask_scale = 0.11;
uniform float wetness = 1.0;
uniform float normal_scale = 1.0;
varying vec3 wpos;
void vertex() {
	wpos = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 uv = UV * uv_scale;
	vec3 alb = texture(albedo_tex, uv).rgb * tint.rgb;
	vec3 arm = texture(arm_tex, uv).rgb;
	float wet = clamp(texture(wet_mask, wpos.xz * mask_scale).r * wetness, 0.0, 1.0);
	ALBEDO = alb * mix(1.0, 0.42, wet);
	ROUGHNESS = mix(arm.g, 0.035, wet);
	METALLIC = 0.0;
	SPECULAR = mix(0.5, 0.8, wet);
	AO = arm.r;
	AO_LIGHT_AFFECT = 0.25;
	NORMALMAP = mix(texture(normal_tex, uv).rgb, vec3(0.5, 0.5, 1.0), wet * 0.85);
	NORMALMAP_DEPTH = normal_scale;
}
