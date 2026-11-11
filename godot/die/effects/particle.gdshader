shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform vec4 tint : source_color = vec4(1.0);
uniform bool vertex_color = false;
uniform int mask_count = 0;
uniform vec2 mask_polygon[16];
void fragment() {
	// Compatibility renderer equivalent of the prototype's top-face stencil.
	// The owning die projects its upward face; other die instances keep separate masks.
	bool inside = false;
	for(int i=0;i<16;i++) {
		if(i>=mask_count) { break; }
		int j = i==0 ? mask_count-1 : i-1;
		vec2 a=mask_polygon[i]; vec2 b=mask_polygon[j];
		if((a.y>SCREEN_UV.y)!=(b.y>SCREEN_UV.y)) {
			float x=(b.x-a.x)*(SCREEN_UV.y-a.y)/(b.y-a.y)+a.x;
			if(SCREEN_UV.x<x) { inside=!inside; }
		}
	}
	if(inside) { discard; }
	ALBEDO=tint.rgb*(vertex_color ? COLOR.rgb : vec3(1.0));
	ALPHA=tint.a*(vertex_color ? COLOR.a : 1.0);
}
