shader_type spatial;
render_mode unshaded;

// Fixed toy-like lighting matches the die without depending on scene lights.
uniform vec4 tint : source_color = vec4(0.737, 0.588, 0.514, 1.0);
varying vec3 world_normal;
void vertex() {
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
vec3 to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}
vec3 to_srgb(vec3 c) {
	return mix(c * 12.92, 1.055 * pow(max(c, vec3(0.0)), vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), c));
}
void fragment() {
	float light = dot(normalize(world_normal), normalize(vec3(-4.0, 9.0, 5.0))) * 0.5 + 0.5;
	float ramp = light < 0.3333 ? 75.0 / 255.0 : (light < 0.6667 ? 175.0 / 255.0 : 1.0);
	vec3 base = OUTPUT_IS_SRGB ? to_linear(tint.rgb) : tint.rgb;
	vec3 shaded = base * (vec3(0.95) + vec3(1.0, 0.9216, 0.7157) * 2.1 * ramp) / 3.14159265;
	ALBEDO = OUTPUT_IS_SRGB ? to_srgb(shaded) : shaded;
}
