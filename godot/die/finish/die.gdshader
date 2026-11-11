shader_type spatial;
render_mode unshaded;
uniform vec4 body_color : source_color = vec4(0.957,0.525,0.396,1.0);
uniform vec4 ink_color : source_color = vec4(0.188,0.133,0.239,1.0);
uniform vec4 shine_color : source_color = vec4(1.0,0.97,0.90,1.0);
uniform float shine_cursor = -2.2;
uniform float shine_strength = 0.0;
uniform vec4 glints[3];
uniform float crack_progress = 0.0;
uniform float crack_strength = 0.0;
uniform vec4 segments[12];
varying vec3 local_position;
varying vec3 world_normal;
varying vec2 shine_position;
void vertex() {
	local_position = VERTEX;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	shine_position = (mat3(MODELVIEW_MATRIX) * VERTEX).xy / max(length(MODEL_MATRIX[0].xyz),0.0001);
}
float trail(float d) { float r = 1.0-clamp(d/0.85,0.0,1.0); return step(0.0,d)*r*r; }
float axis(vec2 p) { return p.x-0.45*p.y; }
vec3 to_linear(vec3 c) { return mix(c/12.92,pow((c+0.055)/1.055,vec3(2.4)),step(vec3(0.04045),c)); }
vec3 to_srgb(vec3 c) { return mix(c*12.92,1.055*pow(max(c,vec3(0.0)),vec3(1.0/2.4))-0.055,step(vec3(0.0031308),c)); }
void fragment() {
	float ndl = dot(normalize(world_normal),normalize(vec3(-4.0,9.0,5.0)))*0.5+0.5;
	float ramp = ndl < 0.3333 ? 75.0/255.0 : (ndl < 0.6667 ? 175.0/255.0 : 1.0);
	vec3 base = OUTPUT_IS_SRGB ? to_linear(body_color.rgb) : body_color.rgb;
	vec3 ink = OUTPUT_IS_SRGB ? to_linear(ink_color.rgb) : ink_color.rgb;
	vec3 shine = OUTPUT_IS_SRGB ? to_linear(shine_color.rgb) : shine_color.rgb;
	vec3 color = base * (vec3(0.95) + vec3(1.0,0.9216,0.7157)*2.1*ramp)/3.14159265;
	float band = trail(shine_cursor-axis(shine_position));
	float sparks = 0.0;
	for(int i=0;i<3;i++) {
		vec4 g=glints[i]; vec2 p=shine_position-g.xy;
		p=abs(mat2(vec2(cos(g.w),-sin(g.w)),vec2(sin(g.w),cos(g.w)))*p);
		float h=(1.0-smoothstep(0.0,g.z,p.x))*(1.0-smoothstep(0.0,0.035,p.y));
		float v=(1.0-smoothstep(0.0,0.035,p.x))*(1.0-smoothstep(0.0,g.z*1.2,p.y));
		sparks=max(sparks,max(h,v)*trail(shine_cursor-axis(g.xy)));
	}
	color=mix(color,shine,clamp(shine_strength*(band+2.1*sparks),0.0,0.9));
	vec3 face=abs(local_position);
	vec2 uv=face.y>=face.x && face.y>=face.z ? local_position.xz : (face.x>=face.z ? local_position.zy : local_position.xy);
	float coverage=0.0;
	for(int i=0;i<12;i++) {
		float growth=clamp(crack_progress*12.0-float(i),0.0,1.0);
		vec2 a=segments[i].xy; vec2 b=mix(a,segments[i].zw,growth); vec2 ab=b-a;
		float d=length(uv-a-clamp(dot(uv-a,ab)/max(dot(ab,ab),0.00001),0.0,1.0)*ab);
		float pixel=clamp(fwidth(d),0.001,0.035);
		float width=max(0.012,pixel*0.45);
		coverage=max(coverage,(1.0-smoothstep(width,width+pixel,d))*step(0.0001,growth));
	}
	color=mix(color,ink,coverage*crack_strength);
	ALBEDO=OUTPUT_IS_SRGB ? to_srgb(color) : color;
}
