shader_type canvas_item;

uniform float radius = 0.1; // As percent of width/height (0.0 - 0.5 recommended)

void fragment() {
	vec2 px_size = vec2(textureSize(TEXTURE, 0));
	vec2 uv = UV;

	// Convert normalized UV to pixel space
	vec2 uv_px = uv * px_size;
	vec2 r = px_size * radius;

	// Check each corner
	float alpha = 1.0;

	if (uv_px.x < r.x && uv_px.y < r.y)
		alpha *= smoothstep(r.x, r.x - 1.0, distance(uv_px, r));
	else if (uv_px.x > px_size.x - r.x && uv_px.y < r.y)
		alpha *= smoothstep(r.x, r.x - 1.0, distance(uv_px, vec2(px_size.x - r.x, r.y)));
	else if (uv_px.x < r.x && uv_px.y > px_size.y - r.y)
		alpha *= smoothstep(r.x, r.x - 1.0, distance(uv_px, vec2(r.x, px_size.y - r.y)));
	else if (uv_px.x > px_size.x - r.x && uv_px.y > px_size.y - r.y)
		alpha *= smoothstep(r.x, r.x - 1.0, distance(uv_px, vec2(px_size.x - r.x, px_size.y - r.y)));

	if (alpha <= 0.01) discard;

	COLOR = texture(TEXTURE, UV) * alpha;
}
