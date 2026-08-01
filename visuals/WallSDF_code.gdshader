shader_type spatial;
render_mode unshaded;

const int MAX_BALL_COUNT = 32;

uniform float radius = 2;
uniform vec3[MAX_BALL_COUNT] balls;
uniform vec3 field_color : source_color;
uniform float noise_scale = 1.;

void vertex() {
	vec3 vertex_world_pos = NODE_POSITION_WORLD + VERTEX;
	UV = vertex_world_pos.xy;
	UV2 = vec2(vertex_world_pos.z, 0);
}

float sdf_sphere(vec3 location, vec3 pos) {
	return distance(pos, location) - radius;
}

vec2 random(vec2 uv){
    uv = vec2( dot(uv, vec2(127.1,311.7) ),
               dot(uv, vec2(269.5,183.3) ) );
    return -1.0 + 2.0 * fract(sin(uv) * 43758.5453123);
}

float noise(vec2 uv) {
    vec2 uv_index = floor(uv);
    vec2 uv_fract = fract(uv);

    vec2 blur = smoothstep(0.0, 1.0, uv_fract);

    return mix( mix( dot( random(uv_index + vec2(0.0,0.0) ), uv_fract - vec2(0.0,0.0) ),
                     dot( random(uv_index + vec2(1.0,0.0) ), uv_fract - vec2(1.0,0.0) ), blur.x),
                mix( dot( random(uv_index + vec2(0.0,1.0) ), uv_fract - vec2(0.0,1.0) ),
                     dot( random(uv_index + vec2(1.0,1.0) ), uv_fract - vec2(1.0,1.0) ), blur.x), blur.y) + 0.5;
}

float remap(float v, float inMin, float inMax, float outMin, float outMax) {
  float t = (v - inMin) / (inMax - inMin);
  return outMin + (outMax - outMin) * t;
}

void fragment() {
	vec3 pixel_world_pos = vec3(UV, UV2.x);

	float dist = sdf_sphere(pixel_world_pos, balls[0]);

	for (int i = 0; i < MAX_BALL_COUNT; i++) {
		if (any(isinf(balls[i]))) break;
		dist = min(dist, sdf_sphere(pixel_world_pos, balls[i]));
	}

	//ALBEDO = vec3(abs(sin(dist * 10.0)));
	ALBEDO = vec3(
		pow(noise(pixel_world_pos.yz * noise_scale + TIME), 1) *
		pow(noise(pixel_world_pos.yz * noise_scale - TIME), 1)
		);

	ALPHA =
		pow(sin(
			remap(dist, -radius, 0, PI, PI * 1.75)
		), 4)
		* (1. - smoothstep(-radius * 2., radius * 2., dist));

	ALPHA = remap(ALPHA, 0., 1., .05, 1.);

	ALPHA *= remap(ALBEDO.x, 0., 1., .5, .7);
	ALPHA *= smoothstep(128., 64., pixel_world_pos.y);



	ALBEDO *= field_color;

}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
