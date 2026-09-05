shader_type canvas_item;
render_mode unshaded;
void fragment() {
	vec4 source = COLOR;
	float magenta = min(source.r, source.b) - source.g;
	float keyed = smoothstep(0.15, 0.5, magenta);
	COLOR = vec4(source.rgb, source.a * (1.0 - keyed));
}
