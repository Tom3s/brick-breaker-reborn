shader_type canvas_item;

uniform int cell_amount = 20;
uniform vec2 period = vec2(5., 10.);

uniform float move_scale = 0.2;
uniform vec2 center_offset = vec2(0.1, 0.1);


void vertex() {
	// Called for every vertex the material is visible on.
}

vec2 modulo(vec2 divident, vec2 divisor){
	vec2 positiveDivident = mod(divident, divisor) + divisor;
	return mod(positiveDivident, divisor);
}

vec2 random(vec2 value){
	value = vec2( dot(value, vec2(127.1,311.7) ),
				  dot(value, vec2(269.5,183.3) ) );
	return -1.0 + 2.0 * fract(sin(value) * 43758.5453123);
}

float seamless_noise(vec2 uv, vec2 _period) {
	uv = uv * float(cell_amount);
	vec2 cellsMinimum = floor(uv);
	vec2 cellsMaximum = ceil(uv);
	vec2 uv_fract = fract(uv);

	cellsMinimum = modulo(cellsMinimum, _period);
	cellsMaximum = modulo(cellsMaximum, _period);

	vec2 blur = smoothstep(0.0, 1.0, uv_fract);

	vec2 lowerLeftDirection = random(vec2(cellsMinimum.x, cellsMinimum.y));
	vec2 lowerRightDirection = random(vec2(cellsMaximum.x, cellsMinimum.y));
	vec2 upperLeftDirection = random(vec2(cellsMinimum.x, cellsMaximum.y));
	vec2 upperRightDirection = random(vec2(cellsMaximum.x, cellsMaximum.y));

	vec2 fraction = fract(uv);

	return mix( mix( dot( lowerLeftDirection, fraction - vec2(0, 0) ),
                     dot( lowerRightDirection, fraction - vec2(1, 0) ), blur.x),
                mix( dot( upperLeftDirection, fraction - vec2(0, 1) ),
                     dot( upperRightDirection, fraction - vec2(1, 1) ), blur.x), blur.y) * 0.8 + 0.5;
}

vec2 get_radial_uv(vec2 uv) {
	float angle = atan(uv.y, uv.x);
    float radial_angle = (angle + PI) / (2.0 * PI);
	
	float radius = length(uv) * 2.0; // scaled to 0.0 - 1.0 edge
    // Example: Use radial coordinates to drive a texture or effect
    return vec2(radial_angle, radius);
}

float remap(float value, float in_min, float in_max, float out_min, float out_max) {
    return out_min + (out_max - out_min) * (value - in_min) / (in_max - in_min);
}


void fragment() {
	// 1. Center UVs and fix aspect ratio if necessary
	vec2 square_ratio = 1.0 / (SCREEN_PIXEL_SIZE / min(SCREEN_PIXEL_SIZE.x, SCREEN_PIXEL_SIZE.y));
	//vec2 tunnel_curve = remap()
    vec2 centered_uv = UV - center_offset;
	//vec2 target_center = center_offset + 0.5;
	//vec2 offcenter_uv = UV - target_center;
	vec2 radial_uv = get_radial_uv(centered_uv * square_ratio);
	//vec2 offenter_radial_uv = get_radial_uv(offcenter_uv * square_ratio);
	
	vec2 final_uv = radial_uv;
	float scaled_time = TIME * move_scale;
	float moving_offset = sin(scaled_time) + scaled_time;
	final_uv.y = pow(final_uv.y, 0.2);
	final_uv.y -= moving_offset;
	final_uv.y *= .1;

	COLOR.r = smoothstep(0.45, 0.55, seamless_noise(final_uv, period));
	vec2 green_uv = final_uv;
	green_uv.x += sin(TIME * move_scale) * .1;
	COLOR.g = smoothstep(0.45, 0.55, seamless_noise(green_uv, period));
	vec2 blue_uv = final_uv;
	blue_uv.x -= sin(TIME * move_scale) * .2;
	COLOR.b = smoothstep(0.45, 0.55, seamless_noise(blue_uv, period));
	//COLOR.rgb = vec3(final_uv.xy, 0.0);
	//COLOR.rgb = vec3(dist_from_edge);
	COLOR.rgb *= smoothstep(.05, .8, radial_uv.y);
	COLOR.rgb = clamp(COLOR.rgb, 0.0, .6);
	

	//COLOR.rg = radial_uv;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
