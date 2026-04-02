#version 420

// original https://www.shadertoy.com/view/Ws23Ry

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define FOV 2.
#define SHIFT 0.02
#define SPEED 5.
#define MIN_DIST 0.0001
#define MAX_DIST 100.
#define MAX_STEP 100
#define PI 3.14159

vec3 palette(float x) {
  float wave = sin(3. * time) * 0.5 + 0.5;
  wave = 0.;
  vec3 a = vec3(.3, .6, .9);
  vec3 b = vec3(0.5 + 0.5 * wave);
  vec3 c = vec3(.5);
  vec3 d = vec3(.3, .6, .7);

  return a + b * cos(2. * PI * (c + d * x));
}

mat2 rot2d(float a) {
  float c = cos(a);
  float s = sin(a);

  return mat2(c, s, -s, c);
}

float box(vec3 p, vec3 b) {
  vec3 d = abs(p) - b;

  return length(max(d, 0.)) + min(max(d.x, max(d.y, d.z)), 0.);
}

float boxRep(vec3 p, vec3 b, vec3 rep) {
  vec3 q = mod(p, rep) - 0.5 * rep;

  return box(q, b);
}

float map(vec3 p) {
  p.xy *= rot2d(sin(time) * 3. * sin(p.z / 10.));
  float tSize = 1.;
  float d = 500.;
  vec3 b = vec3(.1);
  float dBox1 = boxRep(p - vec3(2, 0, 0), b + 0.025 * sin(3. * time), vec3(.5, .5, 2.3));
  float dBox2 = boxRep(p - vec3(2, -1, 2), b + 0.05 * sin(time), vec3(.5, .25, 2.3));
  d = min(d, dBox1);
  d = min(d, dBox2);

  return d;
}

float RayMarch(vec3 ro, vec3 rd) {
  float d = 0.;

  for (int i = 0; i < MAX_STEP; i++) {
    vec3 p = ro + d * rd;
    float m = map(p);
    d += m;

    if (m < MIN_DIST || m > MAX_DIST) {
      break;
    }
  }

  return d;
}

vec3 GetNormal(vec3 p) {
  vec2 e = vec2(0.01, 0);

  vec3 n = map(p) - vec3(
    map(p - e.xyy),
    map(p - e.yxy),
    map(p - e.yyx)
  );

  return normalize(n);
}

float GetLight(vec3 p) {
  vec3 light = vec3(0, 0, 0. + SPEED * time);
  vec3 toLight = light - p;
  vec3 n = GetNormal(p);
  float dif = dot(n, normalize(toLight));
  float d = RayMarch(p + SHIFT * n, normalize(toLight));

  if (d < length(toLight)) {
    dif *= 0.1;
  }

  return dif;
}
void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / resolution.x, gl_FragCoord.y / resolution.y);
  uv -= 0.5;
  uv /= vec2(resolution.y / resolution.x, 1);
  uv *= FOV;
  vec3 col = vec3(0);

  vec3 ro = vec3(0, 0, SPEED * time);
 ro.xy *= rot2d(time / 3.);
  vec3 rd = normalize(vec3(uv.x, uv.y, 1));
  float d = RayMarch(ro, rd);
  vec3 p = ro + d * rd;
  float dif = GetLight(p);

  col = vec3(dif);
  col = palette(1. - 3. * p.z / MAX_DIST) * dif;

  glFragColor = vec4(col, 1);
}
