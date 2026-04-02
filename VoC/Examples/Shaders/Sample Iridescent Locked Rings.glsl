#version 420

// original https://www.shadertoy.com/view/lXcGW8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141592653589793238
#define TAU (2. * PI)
#define EPSILON 0.01

#define SMOOTHINESS .4
#define t time

#define min2(a, b) (a.x < b.x ? a : b)
#define pos(x) (x * .5 + .5)
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))
#define sat(x) clamp(x, 0., 1.)

// IQ's cosine gradient palette
vec3 palette(float x) {
  vec3 a = vec3(.5, .5, 0.), // fire!
       b = a,
       c = vec3(.1, .5, 0.),
       d = vec3(0.);
  return a + b * cos(TAU * (c * x + d));
}

// IQ's SDF functions
float smooth_union(float a, float b, float k) {
  float h = sat(pos((b - a) / k));
  return mix(b, a, h) - k * h * (1. - h);
}

float sdf_torus(vec3 p, vec2 t) {
  vec2 q = vec2(length(p.xz) - t.x, p.y);
  return length(q) - t.y;
}

float rand(float i){
    return fract(sin(dot(vec2(i, i), vec2(32.9898,78.233))) 
                 * 43758.5453);
}

vec2 sdf(vec3 p) {
  vec2 di = vec2(120., -1.);
  vec3 p2 = p;
  
  p.yz *= rot(t);
  p.xy *= rot(t);
  p.xz *= rot(t * PI / 2. + PI / 3.);
  float ring_1 = sdf_torus(p, vec2(1., .15));
  p.yz *= rot(t * PI / 2. + PI / 5.);
  float ring_2 = sdf_torus(p, vec2(1., .15));
  p.xy *= rot(t * PI / 2. - PI / 7.);
  float ring_3 = sdf_torus(p, vec2(1., .15));
  di = min2(di, vec2(smooth_union(ring_1, smooth_union(ring_2, ring_3, SMOOTHINESS), SMOOTHINESS), 1.));
  return di;
}

vec3 glow;
vec2 trace(vec3 ro, vec3 rd) {
  vec3 p = ro;
  vec2 di;
  float td = 0.;
  
  glow = vec3(0.);
  for (int i = 0; i < 128 && td < 120.; i++) {
    di = sdf(p);
    if (di.x < EPSILON)
      return vec2(td, di.y);
    p += di.x * rd;
    glow += pos(normalize(p)) * (1. - sat(di.x/.4)) * .05;
    td = distance(ro, p);
  }
  
  return vec2(-1., -1.);
}

vec3 get_normal(vec3 p) {
  vec2 e = EPSILON * vec2(1., -1.);
  return normalize(
    e.xyy * sdf(p + e.xyy).x +
    e.yxy * sdf(p + e.yxy).x +
    e.yyx * sdf(p + e.yyx).x +
    e.xxx * sdf(p + e.xxx).x
  );
}

vec3 render(vec2 uv) {
  vec3 ro = vec3(0., 0., -3.),
       rd = normalize(vec3(uv, 1.)),
       lo = ro;
  
  vec2 tdi = trace(ro, rd);
  if (tdi.x > 0.) {
    vec3 p = ro + rd * tdi.x;
    vec3 n = get_normal(p);
    
    // Varun Vachar's iridescence effect
    vec3 cd = normalize(ro - p),
         ld = normalize(lo - p),
         reflection = reflect(rd, n),
         perturbation = .05 * sin(p * 10.);
    
    vec3 iridescence = palette(dot(n + perturbation, cd) * 2.);
    float specular = sat(dot(reflection, ld));
    specular *= .1 * pow(pos(sin(specular * 20. - 3.)) + .1, 32.);
    specular += .1 * pow(sat(dot(reflection, ld)) + .3, 8.);
    float shadow = pow(sat(dot(n, vec3(0., 1., 0.)) * .5 + 1.2), 3.);
    
    return iridescence * shadow + specular + glow;
  }
  
  return vec3(0.) + glow;
}

void main(void) {
  vec2 uv = vec2(gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;
  vec3 c = render(uv);
  
  glFragColor = vec4(sat(c), 1.);
}
