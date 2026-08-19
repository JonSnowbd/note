
float bl_gt(float value, float threshold, float if_true, float if_false) {
	return mix(if_false, if_true, step(value, threshold));
}
vec2 bl_gt(float value, float threshold, vec2 if_true, vec2 if_false) {
	return mix(if_false, if_true, step(value, threshold));
}
vec3 bl_gt(float value, float threshold, vec3 if_true, vec3 if_false) {
	return mix(if_false, if_true, step(value, threshold));
}
vec4 bl_gt(float value, float threshold, vec4 if_true, vec4 if_false) {
	return mix(if_false, if_true, step(value, threshold));
}