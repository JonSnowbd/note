shader_type canvas_item;

uniform float count = 10.0; // = 10.0
uniform float smoothness = 0.2; // = 0.5
uniform float progress = 0.0;

void fragment() {
	float pr = smoothstep(-smoothness, 0.0, UV.x - progress * (1.0 + smoothness));
	float s = step(pr, fract(count * UV.x));
	COLOR = mix(COLOR, vec4(COLOR.r, COLOR.g, COLOR.b, 0.0), s);
}
