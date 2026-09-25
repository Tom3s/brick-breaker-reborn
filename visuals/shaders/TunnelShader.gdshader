shader_type spatial;
render_mode unshaded;

const vec3 dither_magic_number = vec3(0.06711056f, 0.00583715f, 52.9829189f);

uniform vec3 tunnel_color : source_color;
uniform float speed1 = 1.0;
uniform float speed2 = 1.0;
uniform float freq1 = 1.0;
uniform float freq2 = 1.0;



void vertex() {
	// Called for every vertex the material is visible on.
	COLOR.rgb = VERTEX;
}

float norm(float a) {
	return (a + 1.0) / 2.0;
}

float remap(float v, float inMin, float inMax, float outMin, float outMax) {
  float t = (v - inMin) / (inMax - inMin);
  return outMin + (outMax - outMin) * t;
}

void fragment() {
	// Called for every pixel the material is visible on.
	//ALBEDO.rgb = tunnel_color;
	float wave1 = norm(sin((COLOR.g + (TIME * speed1)) / freq1));
	float wave2 = norm(sin((COLOR.g + (TIME * speed2)) / freq2));
	
	ALBEDO.rgb = tunnel_color;
	ALPHA = remap(wave1 + wave2, 0., 2., 0.1, 1.1);
	
	if (ALPHA < 0.001 || ALPHA < fract(dither_magic_number.z * fract(dot(FRAGCOORD.xy, dither_magic_number.xy)))) {
		discard;
	}
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
