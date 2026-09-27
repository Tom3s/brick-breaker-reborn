shader_type canvas_item;

uniform sampler2D sdf_texture : source_color;
uniform float bg_size = 0.3;
uniform vec2 bg_border = vec2(.3, .4);
uniform vec3 icon_color : source_color;
uniform vec3 icon_outline : source_color;
uniform vec3 bg_color : source_color;
uniform vec3 bg_accent : source_color;
uniform float icon_scale = 0.8;
uniform float icon_left = 1.0;

uniform float bob_dist = 0.1;
uniform float bob_speed = 1.3;

const mat4 bayerIndex = mat4(
    vec4(00.0/16.0, 12.0/16.0, 03.0/16.0, 15.0/16.0),
    vec4(08.0/16.0, 04.0/16.0, 11.0/16.0, 07.0/16.0),
    vec4(02.0/16.0, 14.0/16.0, 01.0/16.0, 13.0/16.0),
    vec4(10.0/16.0, 06.0/16.0, 09.0/16.0, 05.0/16.0));





void vertex() {
	// Called for every vertex the material is visible on.
}

float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

vec2 radial(vec2 uv) {
	vec2 centeredUV = uv - 0.5;

	// 1. Radial distance (Radius / Magnitude)
	float radius = length(centeredUV); 
	// or sqrt(dot(centeredUV, centeredUV))

	// 2. Angular direction (Theta / Angle) in radians [-PI to PI]
	float angle = atan(centeredUV.x, centeredUV.y); 
	
	

	// Optional: Remap angle to a 0.0 to 1.0 range for easier operations
	float normalizedAngle = (angle + 3.14159265) / (2.0 * 3.14159265);
    
    // Use radial coordinates (e.g., radius for a circular gradient)
    vec2 color = vec2(radius, normalizedAngle);
    
    return color;
}

void fragment() {
	// Called for every pixel the material is visible on.
	
	float dist = sdBox(UV - .5, vec2(bg_size, bg_size));
	
	float border = min(
		step(bg_border.x, dist),
		step(bg_border.y, 1.0 - dist)
	);
	
	//border = clamp(border, .2, .7);
	vec3 bg_final_color = mix(bg_color, bg_accent, border);
	
	vec2 icon_uv = ((UV - .5) / icon_scale) + .5;
	icon_uv.y += sin(TIME * bob_speed) * bob_dist;
	
	vec3 icon_final = mix(
		icon_outline, icon_color,
		smoothstep(0.49, 0.51, texture(sdf_texture, icon_uv).r)
	);
	
	float icon_mask = step(
		.2, texture(sdf_texture, icon_uv).r
	);
	
	icon_mask *= clamp(step(1.0 - icon_left, 1.0 - radial(UV).g), 0.25, 1.0);
	float bayer_value = bayerIndex[int(FRAGCOORD.x) % 4][int(FRAGCOORD.y) % 4] + 0.0001;
	
	icon_mask = step(bayer_value, icon_mask);
	
	
	//icon_mask = 0.0;
	
	
	//COLOR.rgb = vec3(UV, 0.0);
	//COLOR.rgb = ;
	COLOR.rgb = mix(vec3(bg_final_color), icon_final, icon_mask);
	//COLOR.b = 0.0;
	//COLOR.rg = radial(UV);
	COLOR.a = step(bg_border.y, 1.0 - dist);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
