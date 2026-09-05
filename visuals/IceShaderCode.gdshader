shader_type spatial;

uniform vec3 from_color : source_color;
uniform vec3 to_color : source_color;

uniform float scale = 10.0;
uniform vec3 noise_scale = vec3(1.0);
uniform vec3 noise_rotation = vec3(1.0);
uniform float jitter = 0.3;
uniform float normal_offset = 0.3;



vec3 hash3(vec3 p) {
    p = vec3(dot(p, vec3(127.1, 311.7, 74.7)),
             dot(p, vec3(269.5, 183.3, 246.1)),
             dot(p, vec3(113.5, 271.9, 124.6)));
    return fract(sin(p) * 43758.5453123);
}

// 3D Voronoi function returning minimum distance to a feature point
float voronoi3D(vec3 x, float randomness, bool cell) {
    vec3 n = floor(x);
    vec3 f = fract(x);

    float min_dist = 1.0;
	vec3 closest_point;

    // Iterate over the 3x3x3 neighboring cells
    for (int k = -1; k <= 1; k++) {
        for (int j = -1; j <= 1; j++) {
            for (int i = -1; i <= 1; i++) {
                vec3 g = vec3(float(i), float(j), float(k));
                vec3 o = hash3(n + g);

                // Animate or jitter the point inside the cell
                o = 0.5 + 0.5 * sin(randomness + 6.2831 * o);

                vec3 r = g + o - f;
                float d = dot(r, r); // Squared Euclidean distance

				if (d < min_dist) {
					min_dist = d;
					closest_point = o;
				}
                min_dist = min(min_dist, d);
            }
        }
    }

	if (cell) {
		return hash3(closest_point).y;
	}
    return sqrt(min_dist);
}

vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
vec4 taylorInvSqrt(vec4 r){return 1.79284291400159 - 0.85373472095314 * r;}

float snoise(vec3 v){
  const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
  const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

// First corner
  vec3 i  = floor(v + dot(v, C.yyy) );
  vec3 x0 =   v - i + dot(i, C.xxx) ;

// Other corners
  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min( g.xyz, l.zxy );
  vec3 i2 = max( g.xyz, l.zxy );

  //  x0 = x0 - 0. + 0.0 * C
  vec3 x1 = x0 - i1 + 1.0 * C.xxx;
  vec3 x2 = x0 - i2 + 2.0 * C.xxx;
  vec3 x3 = x0 - 1. + 3.0 * C.xxx;

// Permutations
  i = mod(i, 289.0 );
  vec4 p = permute( permute( permute(
             i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
           + i.y + vec4(0.0, i1.y, i2.y, 1.0 ))
           + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

// Gradients
// ( N*N points uniformly over a square, mapped onto an octahedron.)
  float n_ = 1.0/7.0; // N=7
  vec3  ns = n_ * D.wyz - D.xzx;

  vec4 j = p - 49.0 * floor(p * ns.z *ns.z);  //  mod(p,N*N)

  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

  vec4 x = x_ *ns.x + ns.yyyy;
  vec4 y = y_ *ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);

  vec4 b0 = vec4( x.xy, y.xy );
  vec4 b1 = vec4( x.zw, y.zw );

  vec4 s0 = floor(b0)*2.0 + 1.0;
  vec4 s1 = floor(b1)*2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));

  vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
  vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

  vec3 p0 = vec3(a0.xy,h.x);
  vec3 p1 = vec3(a0.zw,h.y);
  vec3 p2 = vec3(a1.xy,h.z);
  vec3 p3 = vec3(a1.zw,h.w);

//Normalise gradients
  vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;

// Mix final noise value
  vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1),
                                dot(p2,x2), dot(p3,x3) ) );
}

mat3 lookAt(vec3 eye, vec3 target, vec3 up) {
    vec3 fwd = normalize(target - eye);
    vec3 right = normalize(cross(fwd, up));
    vec3 trueUp = cross(right, fwd);
    return mat3(right, trueUp, fwd);
}

float remap(float v, float inMin, float inMax, float outMin, float outMax) {
  float t = (v - inMin) / (inMax - inMin);
  return outMin + (outMax - outMin) * t;
}

void vertex() {
	// Called for every vertex the material is visible on.
	//UV = COLOR.rg;
	//UV2.x = COLOR.b;
	COLOR.rgb = VERTEX;
}

void fragment() {
	// Called for every pixel the material is visible on.
	float main_sample = voronoi3D(COLOR.rgb * scale, jitter, false);
	float cell_sample = voronoi3D(COLOR.rgb * scale, jitter, true);

	float shaped_sample = sqrt(main_sample);
	shaped_sample = clamp(shaped_sample, 0.5, 1.0);
	//shaped_sample *= shaped_sample;
	shaped_sample = pow(shaped_sample, 3.0);

	vec3 cell_colors = mix(from_color, to_color, cell_sample);

	mat3 noise_rot_mat = lookAt(vec3(0.), noise_rotation, vec3(0., 1., 0.));
	float surface_streaks = snoise(COLOR.rgb * noise_rot_mat * noise_scale);

	//ALBEDO.rgb = cell_colors;
	ALBEDO.rgb = cell_colors * shaped_sample;

	ROUGHNESS = (shaped_sample * surface_streaks);
	//ROUGHNESS = 1.0;
	SPECULAR = 1.0;

	NORMAL += remap(cell_sample, 0., 1., -normal_offset, normal_offset);
	//ALBEDO.rg = UV;
	//ALBEDO.b = 0.0;
	//ALBEDO.rgb = COLOR.rgb;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
