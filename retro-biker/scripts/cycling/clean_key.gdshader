shader_type canvas_item;
render_mode unshaded;
varying vec4 vertex_tint;
void vertex() {
	vertex_tint = COLOR;
}
vec4 keyed_color(vec4 sample_color) {
	float key_distance = distance(sample_color.rgb, vec3(1.0, 0.0, 1.0));
	sample_color.a *= smoothstep(0.12, 0.32, key_distance);
	return vec4(sample_color.rgb * sample_color.a, sample_color.a);
}
void fragment() {
	// Key before filtering: magenta must never bleed into small illustrations.
	// Narrow colour distance also preserves the pink jacket and purple backpack.
	ivec2 size = textureSize(TEXTURE, 0);
	vec2 position = UV * vec2(size) - vec2(0.5);
	ivec2 base = ivec2(floor(position));
	vec2 fraction = fract(position);
	vec4 a = keyed_color(texelFetch(TEXTURE,clamp(base,ivec2(0),size-ivec2(1)),0));
	vec4 b = keyed_color(texelFetch(TEXTURE,clamp(base+ivec2(1,0),ivec2(0),size-ivec2(1)),0));
	vec4 c = keyed_color(texelFetch(TEXTURE,clamp(base+ivec2(0,1),ivec2(0),size-ivec2(1)),0));
	vec4 d = keyed_color(texelFetch(TEXTURE,clamp(base+ivec2(1,1),ivec2(0),size-ivec2(1)),0));
	vec4 upper = mix(a,b,fraction.x);
	vec4 lower = mix(c,d,fraction.x);
	vec4 result = mix(upper,lower,fraction.y);
	COLOR = vec4(result.rgb / max(result.a,0.0001),result.a) * vertex_tint;
}
