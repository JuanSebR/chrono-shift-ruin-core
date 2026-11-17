shader_type canvas_item;

uniform float threshold : hint_range(0.0, 0.2) = 0.032;
uniform float softness : hint_range(0.001, 0.05) = 0.002;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float luma = max(tex.r, max(tex.g, tex.b));
	tex.a *= smoothstep(threshold - softness, threshold + softness, luma);
	COLOR = tex;
}
