shader_type canvas_item;
// Diagonal highlight sweep for eligible bonus and Joker artwork (D-023).
// The sweep is masked by the artwork's own alpha, so it never draws outside the icon.

// Sweep position: 0 enters at the top-left, 1 leaves at the bottom-right; outside that range nothing shows.
uniform float progress = -1.0;
// Warm cream highlight shared with the die shine.
uniform vec4 tint : source_color = vec4(1.0, 0.97, 0.9, 1.0);

void fragment() {
	float diagonal = (UV.x + UV.y) * 0.5;
	float center = mix(-0.25, 1.25, progress);
	float band = smoothstep(0.2, 0.0, abs(diagonal - center));
	float thin = smoothstep(0.05, 0.0, abs(diagonal - center + 0.24));
	COLOR.rgb = mix(COLOR.rgb, tint.rgb, clamp(band * 0.72 + thin * 0.5, 0.0, 1.0));
}
