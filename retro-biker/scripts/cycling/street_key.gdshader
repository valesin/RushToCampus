shader_type canvas_item;
render_mode unshaded;
void fragment() {
	// Evaluate the key before vertex tint, so muted stone never leaves a pink seam.
	vec4 source = texture(TEXTURE, UV);
	float key = smoothstep(0.08, 0.30, min(source.r,source.b)-source.g);
	COLOR.a *= 1.0-key;
}
