shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled;
// Quiet wallpaper behind the table: a glow that deepens toward the edges, with an optional
// low-contrast drifting motif. Everything is computed in screen space, so the wall ignores
// camera framing and shake.

// Tone behind the table.
uniform vec4 center_color : source_color = vec4(0.953, 0.937, 0.91, 1.0);
// Tone toward the window edges.
uniform vec4 edge_color : source_color = vec4(0.902, 0.875, 0.835, 1.0);
// Marks drawn darker than the wall.
uniform vec4 mark_color : source_color = vec4(0.847, 0.812, 0.761, 1.0);
// Marks drawn lighter than the wall.
uniform vec4 light_color : source_color = vec4(0.984, 0.973, 0.949, 1.0);
// 0 plain, 1 sparkles and pips, 2 dots, 3 stripes, 4 diamonds. Matches RoundBackdrop.Motif.
uniform int motif = 1;
// Pattern cells across the window height.
uniform float density : hint_range(4.0, 20.0) = 8.5;
// Overall pattern opacity; zero leaves only the glow.
uniform float pattern_strength : hint_range(0.0, 1.0) = 0.55;
// Presentation clock in seconds, frozen by the owner under reduced motion.
uniform float clock = 0.0;

void fragment() {
	// Aspect-correct coordinates centered on the window, one unit per window height.
	vec2 uv = (FRAGCOORD.xy - 0.5 * VIEWPORT_SIZE) / VIEWPORT_SIZE.y;
	float distance_from_center = length(uv * vec2(0.72, 1.0));
	vec3 color = mix(center_color.rgb, edge_color.rgb, smoothstep(0.12, 0.8, distance_from_center));

	// Tilted grid of cells, drifting slowly along its own diagonal.
	float tilt = 0.32;
	mat2 turn = mat2(vec2(cos(tilt), sin(tilt)), vec2(-sin(tilt), cos(tilt)));
	vec2 grid = turn * uv * density + vec2(clock * 0.045, clock * -0.03);
	vec2 cell = floor(grid);
	vec2 local = fract(grid) - 0.5;
	vec2 reach = abs(local);
	float alternate = mod(cell.x + cell.y, 2.0);
	// Each cell breathes on its own phase so the wall never pulses in unison.
	float breath = 0.5 + 0.5 * sin(clock * 0.9 + cell.x * 1.7 + cell.y * 2.9);
	float edge = fwidth(grid.x) * 1.5;
	float light = 0.0;
	float mark = 0.0;

	if (motif == 1) {
		// Four-point sparkle (an astroid, like the table inlays) alternating with diamond pips.
		float sparkle_limit = pow(mix(0.2, 0.27, breath), 0.62);
		float sparkle_field = pow(reach.x, 0.62) + pow(reach.y, 0.62);
		light = smoothstep(sparkle_limit + edge, sparkle_limit - edge, sparkle_field) * alternate * 0.75;
		float pip_radius = mix(0.085, 0.105, 1.0 - breath);
		mark = smoothstep(pip_radius + edge, pip_radius - edge, reach.x + reach.y) * (1.0 - alternate);
	} else if (motif == 2) {
		// Polka dots, alternating lighter and darker than the wall.
		float radius = mix(0.14, 0.18, breath);
		float dot_shape = smoothstep(radius + edge, radius - edge, length(local));
		light = dot_shape * alternate * 0.75;
		mark = dot_shape * (1.0 - alternate);
	} else if (motif == 3) {
		// Broad diagonal stripes.
		float band = abs(fract(grid.x * 0.5) - 0.5) * 2.0;
		mark = smoothstep(0.5 + edge, 0.5 - edge, band) * 0.6;
	} else if (motif == 4) {
		// Harlequin diamonds: a checkerboard turned onto its corners, with a thin seam.
		vec2 turned = vec2(grid.x + grid.y, grid.x - grid.y) * 0.5;
		vec2 turned_cell = floor(turned);
		vec2 inset = 0.5 - abs(fract(turned) - 0.5);
		float seam = smoothstep(0.0, edge * 1.5, min(inset.x, inset.y));
		mark = mod(turned_cell.x + turned_cell.y, 2.0) * seam * 0.6;
	}

	// The pattern fades out behind the table so the play area stays calm.
	float presence = pattern_strength * smoothstep(0.1, 0.62, distance_from_center);
	color = mix(color, light_color.rgb, light * presence);
	color = mix(color, mark_color.rgb, mark * presence);
	ALBEDO = color;
}
