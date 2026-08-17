shader_type spatial;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float blur_amount = 0.01;

void vertex() {
	// Called for every vertex the material is visible on.
}

float random (vec2 uv) {
    return fract(sin(dot(uv.xy,
        vec2(12.9898,78.233))) * 43758.5453123);
}

void fragment() {
	vec2 random_sample = vec2(0.0);
	random_sample.x = ((random(SCREEN_UV) * 2.0) - 1.0);
	random_sample.y = ((random(SCREEN_UV + 1.0) * 2.0) - 1.0);


	vec2 noised_uv = random_sample * blur_amount + SCREEN_UV;
	ALBEDO = textureLod(screen_texture, noised_uv, 2.0).rgb;
	//ALBEDO.xy = noised_uv;
	//ALBEDO.z = 0.0;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
