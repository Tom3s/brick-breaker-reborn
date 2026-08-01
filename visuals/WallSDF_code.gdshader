shader_type spatial;

uniform float radius = 2;
uniform vec3[32] balls;

void vertex() {
	vec3 vertex_world_pos = NODE_POSITION_WORLD + VERTEX;
	UV = vertex_world_pos.xy;
	UV2 = vec2(vertex_world_pos.z, 0);
}

void fragment() {
	vec3 pixel_world_pos = vec3(UV, UV2.x);

	ALBEDO = pixel_world_pos;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
