shader_type canvas_item;

uniform ivec2 size = ivec2(10, 10); // = ivec2(10, 10)
uniform float smoothness = 0.5; // = 0.5
uniform float progress;
 
float rand (vec2 co) {
  return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
	float r = rand(floor(vec2(size) * UV));
	float m = smoothstep(0.0, -smoothness, r - (progress * (1.0 + smoothness)));
	COLOR =  mix(COLOR, vec4(COLOR.r, COLOR.g, COLOR.b, 0.0), m);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
