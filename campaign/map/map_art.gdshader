shader_type canvas_item;

// 1.0 shows full color; 0.0 shows black and white.
uniform float saturation : hint_range(0.0, 1.0) = 1.0;
uniform float brightness : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 color = texture(TEXTURE, UV) * COLOR;
	float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(vec3(gray), color.rgb, saturation) * brightness, color.a);
}
