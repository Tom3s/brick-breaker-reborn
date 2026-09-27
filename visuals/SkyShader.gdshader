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

// Source - https://stackoverflow.com/a/17897228
// Posted by sam hocevar, modified by community. See post 'Timeline' for change history
// Retrieved 2026-09-27, License - CC BY-SA 4.0

// All components are in the range [0…1], including hue.
vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// Source - https://stackoverflow.com/a/17897228
// Posted by sam hocevar, modified by community. See post 'Timeline' for change history
// Retrieved 2026-09-27, License - CC BY-SA 4.0

// All components are in the range [0…1], including hue.
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

//const mat4 bayerIndex = mat4(
    //vec4(00.0/16.0, 12.0/16.0, 03.0/16.0, 15.0/16.0),
    //vec4(08.0/16.0, 04.0/16.0, 11.0/16.0, 07.0/16.0),
    //vec4(02.0/16.0, 14.0/16.0, 01.0/16.0, 13.0/16.0),
    //vec4(10.0/16.0, 06.0/16.0, 09.0/16.0, 05.0/16.0));
// Matricies only go as high as 4 so the 8x8 matrix is an array accessed via [y + (x * n)] rather than [x][y]
const float BAYER_8x8[64] = {
								0.0, 32.0, 8.0, 40.0, 2.0, 34.0, 10.0, 42.0,
                                48.0, 16.0, 56.0, 24.0, 50.0, 18.0, 58.0, 26.0,
								12.0, 44.0, 4.0, 36.0, 14.0, 46.0, 6.0, 38.0,
								60.0, 28.0, 52.0, 20.0, 62.0, 30.0, 54.0, 22.0,
								3.0, 35.0, 11.0, 43.0, 1.0, 33.0, 9.0, 41.0,
								51.0, 19.0, 59.0, 27.0, 49.0, 17.0, 57.0, 25.0,
								15.0, 47.0, 7.0, 39.0, 13.0, 45.0, 5.0, 37.0,
								63.0, 31.0, 55.0, 23.0, 61.0, 29.0, 53.0, 21.0
                              };
float interleavedGradientNoise(vec2 screen_position) {
    vec3 magic = vec3(0.06711056, 0.00583715, 52.9829189);
    return fract(magic.z * fract(dot(screen_position, magic.xy)));
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
	float sin_xd = sin(TIME * 0.05);
	sin_xd *= sin_xd * sin_xd;
	final_uv.x += (final_uv.y * (2.5 * sin_xd));
	final_uv.y -= moving_offset;
	final_uv.y *= .1;

	COLOR.r = smoothstep(0.35, 0.65, seamless_noise(final_uv, period));
	vec2 green_uv = final_uv;
	green_uv.x += sin(TIME * move_scale) * .1;
	green_uv.y += .8;
	COLOR.g = smoothstep(0.35, 0.65, seamless_noise(green_uv, period));
	vec2 blue_uv = final_uv;
	blue_uv.x -= sin(TIME * move_scale) * .2;
	green_uv.y -= .6;
	COLOR.b = smoothstep(0.35, 0.65, seamless_noise(blue_uv, period));
	//COLOR.rgb = vec3(final_uv.xy, 0.0);
	//COLOR.rgb = vec3(dist_from_edge);

	//	change color tone here
	vec3 hsv = rgb2hsv(COLOR.rgb);
	hsv.y *= .6;
	hsv.z *= remap(hsv.z, 0., 1., .1, .9);
	hsv.x += TIME * .19;

	COLOR.rgb = hsv2rgb(hsv);

	//[y + (x * n)]
	//float bayer_value = BAYER_8x8[(int(FRAGCOORD.x) % 8) + (int(FRAGCOORD.y) % 8) * 8] + 0.0001;
	//bayer_value /= 64.0;
	//icon_mask = step(bayer_value, icon_mask);

	float tunnel_dark = smoothstep(.05, .8, radial_uv.y);
	float dither = interleavedGradientNoise(FRAGCOORD.xy) - 0.5;
	dither = remap(dither, 0., 1., -5., 5.);
    tunnel_dark += dither / 255.0;

	COLOR.rgb *= tunnel_dark;
	//COLOR.rgb = clamp(COLOR.rgb, 0.0, .6);


	//COLOR.rg = radial_uv;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
