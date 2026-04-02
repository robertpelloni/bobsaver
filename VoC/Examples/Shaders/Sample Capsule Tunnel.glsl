#version 420

// original https://www.shadertoy.com/view/ttyXRw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time .4 * time
#define ZPOS -30. + 20. * time

float PI = acos(-1.);

mat2 rot2d(float a) {
  float c = cos(a), s = sin(a);
  
  return mat2(c, s, -s, c);
}

float sph(vec3 p, float r) {
  return length(p) - r;
}

float tube(vec3 p, vec3 a, vec3 b, float r) {
  vec3 ab = b - a;
  vec3 ap = p - a;
  float t = dot(ab, ap) / dot(ab, ab);
  t = clamp(t, 0., 1.);
  vec3 c = a + ab * t;
  
  return length(p - c) - r;
}

vec3 rep(vec3 p, vec3 r) {
  vec3 q = mod(p, r) - .5 * r;
  
  return q;
}

float at = 0.;
float map(vec3 p) {
  p.xy *= rot2d(sin(3. * time) * sin(p.z / 15.));
  p.xz *= rot2d(sin(.01 * time) * PI);
  p = rep(p, vec3(5, 5, 5));
  float d = 5000.;
  vec3 a1 = vec3(-2, 0, 0);
  vec3 b1 = vec3(2, 0, 0);
  vec3 a2 = vec3(0, -2, 0);
  vec3 b2 = vec3(0, 2, 0);
  vec3 a3 = vec3(0, 0, -3.);
  vec3 b3 = vec3(0, 0, 3.);
  float t = floor(time * .5) + smoothstep(.3, .6, fract(time * .5));
  a1.xy *= rot2d(t);
  b1.xy *= rot2d(t);
  a2.xy *= rot2d(t);
  b2.xy *= rot2d(t);
  d = min(d, tube(p, a1, b1, .5));
  d = min(d, tube(p, a2, b2, .5));
  d = min(d, tube(p, a3, b3, .5));
  
  float t_wave = floor(time) + fract(time);
  float wave = .5 * sin(t_wave) + .5;
  vec3 shift = vec3(.2 * sin(time), 0, 0);
  d = min(d, sph(p + shift, 1.));
  
  at += .1 / (.1 + d);
  
  return d;
}

vec3 glow = vec3(0, 0, 0);
float rm(vec3 ro, vec3 rd) {
  float d = 0.;
  
  for (int i = 0; i < 100; i++) {
    vec3 p = ro + d * rd;
    float ds = map(p);
    
    if (ds < 0.01 || ds > 100.) {
      break;
    }
    
    d += ds * 1.;
    glow += .02 * at * vec3(0, 1., 0.);
  }
  
  return d;
}

vec3 normal(vec3 p) {
  vec2 e = vec2(0.01, 0);
  
  vec3 n = map(p) - vec3(
    map(p - e.xyy),
    map(p - e.yxy),
    map(p - e.yyx)
  );
  
  return normalize(n);
}

float light(vec3 p) {
  vec3 lp = vec3(0, 0, ZPOS);
  vec3 tl = lp - p;
  vec3 tln = normalize(tl);
  vec3 n = normal(p);
  float dif = dot(n, tln);
  float d = rm(p + 2. * n, tln);
  
  if (d < length(tl)) {
    dif *= .1;
  }
  
  return dif;
}

void main(void)
{
    vec2 uv = vec2(gl_FragCoord.xy.x / resolution.x, gl_FragCoord.xy.y / resolution.y);
    uv -= 0.5;
    uv /= vec2(resolution.y / resolution.x, 1);

    vec3 ro = vec3(0, 0, ZPOS);
      vec3 rd = normalize(vec3(uv, 1.));
      float d = rm(ro, rd);
      vec3 p = ro + d * rd;
//      float dif = light(p);
  
//    vec3 col = .2 * dif * glow;
    vec3 col = .2 * glow;
   
    glFragColor = vec4(col,1.0);
}
