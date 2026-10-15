/**
 * Voronoi shaped noise
 * u 0.0 -> 1.0, where 0.0 is completely square, and 1.0 is voronoi shaped.
 * v 0.0 -> 1.0, where 0.0 shows sharp lines and 1.0 is a smooth blurred noise.
*/
float voronoi_noise( in vec2 p, float u, float v ){
	// source: https://www.shadertoy.com/view/Xd23Dh
	float k = 1.0+63.0*pow(1.0-v,6.0);

	vec2 i = floor(p);
	vec2 f = fract(p);

	vec2 a = vec2(0.0,0.0);
	for( int y=-2; y<=2; y++ )
	for( int x=-2; x<=2; x++ )
	{
		vec3 hash_inline = vec3( dot(p,vec2(127.1,311.7)), 
				   dot(p,vec2(269.5,183.3)), 
				   dot(p,vec2(419.2,371.9)) );
		hash_inline = fract(sin(hash_inline)*43758.5453);
		vec2  g = vec2( float(x), float(y) );
		vec3  o = hash_inline*vec3(u,u,1.0);
		vec2  d = g - f + o.xy;
		float w = pow( 1.0-smoothstep(0.0,1.414,length(d)), k );
		a += vec2(o.z*w,w);
	}

	return a.x/a.y;
}
float gold_noise(in vec2 xy, in float seed){
	// source: https://stackoverflow.com/a/28095165
	return fract(tan(distance(xy*1.61803398874989484820459, xy)*seed)*xy.x);
}
highp float rand(vec2 co){
	highp float a = 12.9898;
	highp float b = 78.233;
	highp float c = 43758.5453;
	highp float dt= dot(co.xy ,vec2(a,b));
	highp float sn= mod(dt,3.14);
	return fract(sin(sn) * c);
}
