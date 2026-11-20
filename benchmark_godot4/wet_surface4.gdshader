shader_type spatial;
// Godot 4 port of game/slice/shaders/wet_surface.shader (same inputs, same look).
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;
uniform sampler2D albedo_tex : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D normal_tex : hint_normal, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D arm_tex : hint_default_white, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D wet_mask : hint_default_white, repeat_enable, filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(0.95, 0.95, 0.95, 1.0);
uniform float uv_scale = 0.38;
uniform float mask_scale = 0.11;
uniform float wetness = 1.0;
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 uv = UV * uv_scale;
	vec3 arm = texture(arm_tex, uv).rgb;
	float wet = clamp(texture(wet_mask, wpos.xz * mask_scale).r * wetness, 0.0, 1.0);
	ALBEDO = texture(albedo_tex, uv).rgb * tint.rgb * mix(1.0, 0.42, wet);
	ROUGHNESS = mix(arm.g, 0.035, wet);
	METALLIC = 0.0;
	SPECULAR = mix(0.5, 0.8, wet);
	AO = arm.r; AO_LIGHT_AFFECT = 0.25;
	NORMAL_MAP = mix(texture(normal_tex, uv).rgb, vec3(0.5, 0.5, 1.0), wet * 0.85);
}
