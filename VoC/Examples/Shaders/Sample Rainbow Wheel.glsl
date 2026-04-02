#version 420

// original https://www.shadertoy.com/view/mtjGWz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// CC0: Rainbow wheel
//  I enjoyed this tweet by @junkiyoshi
//  https://twitter.com/junkiyoshi/status/1611685042199343104?s=20&t=70iv6TwPx0x4qGWJMWqJYg
//  Tried something similar

// Uncomment for variant suggested by morimea in the comments
// #define MORIMEA

#define TIME        time
#define RESOLUTION  resolution
#define PI          3.141592654
#define PI_2        (0.5*PI)
#define TAU         (2.0*PI)
#define ROT(a)      mat2(cos(a), sin(a), -sin(a), cos(a))

const float rep   = 32.0;
const float over  = 4.0;
const float nstep = 1.0/(rep*over);
const float astep = TAU*nstep;
const float pm    = 17.0;

// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
const vec4 hsv2rgb_K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
vec3 hsv2rgb(vec3 c) {
  vec3 p = abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www);
  return c.z * mix(hsv2rgb_K.xxx, clamp(p - hsv2rgb_K.xxx, 0.0, 1.0), c.y);
}
// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
//  Macro version of above to enable compile-time constants
#define HSV2RGB(c)  (c.z * mix(hsv2rgb_K.xxx, clamp(abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www) - hsv2rgb_K.xxx, 0.0, 1.0), c.y))

// License: MIT OR CC-BY-NC-4.0, author: mercury, found: https://mercury.sexy/hg_sdf/
float modPolar(inout vec2 p, float aa) {
  const float angle = 2.0*PI/rep;
  float a = aa + angle/2.;
  float r = length(p);
  float c = floor(a/angle);
  a = mod(a,angle) - angle/2.;
  p = vec2(cos(a), sin(a))*r;
  // For an odd number of repetitions, fix cell index of the cell in -x direction
  // (cell index would be e.g. -5 and 5 in the two halves of the cell):
  if (abs(c) >= (rep/2.0)) c = abs(c);
  return c;
}

// License: Unknown, author: nmz (twitter: @stormoid), found: https://www.shadertoy.com/view/NdfyRM
vec3 sRGB(vec3 t) {
  return mix(1.055*pow(t, vec3(1./2.4)) - 0.055, 12.92*t, step(t, vec3(0.0031308)));
}

// License: Unknown, author: Matt Taylor (https://github.com/64), found: https://64.github.io/tonemapping/
vec3 aces_approx(vec3 v) {
  v = max(v, 0.0);
  v *= 0.6f;
  float a = 2.51f;
  float b = 0.03f;
  float c = 2.43f;
  float d = 0.59f;
  float e = 0.14f;
  return clamp((v*(a*v+b))/(v*(c*v+d)+e), 0.0f, 1.0f);
}

float segmentx(vec2 p, float l, float w) {
  p = abs(p);
  p.x -= l*0.5-w;
  float d0 = length(p)-w;
  float d1 = p.y-w;
  float d = p.x > 0.0 ? d0 : d1;
  return d;
}

vec2 df(vec2 p, float noff, float a, out float n) {
  const float ll  = 0.5;
  const float ss = 0.0015;
  const float bb = ss*4.0;
  n = modPolar(p, a)/rep+noff;
  float m = 16.0*sin(TIME*TAU);
  float anim = sin(TAU*TIME/10.0+pm*noff*TAU);
  p.x -= 0.75+0.25*anim;
  float l = ll*mix(0.5, 1.0, smoothstep(-0.9, 0.9, anim));
  float s = ss;
  float b = bb;
  vec2 p0 = p;
  vec2 p1 = p;
  p1.x = abs(p1.x);
  p1.x -= l*0.5-s;
  float d0 = segmentx(p0, l, s);
  float d1 = length(p1)-b;
  return vec2(d0, d1);
}

vec3 effect0(vec2 p, float aa) {
  float n;
  vec3 col = vec3(0.0);
  const mat2 rr = ROT(TAU/(rep*over));
  vec2 pp = p;
  float a = atan(p.y, p.x);
  for (float i = 0.0; i < over; ++i) {
    float noff = i*nstep;
    float aoff = i*astep;
#if defined(MORIMEA)
    vec2 d = df(p, noff, mod(a-aoff,TAU)*PI/25., n);
#else
    vec2 d = df(p, noff, mod(a-aoff,TAU), n);
#endif

    float g0 = 0.005/max(max(d.x, 0.0), 0.001);
    float g1 = 0.00005/max((d.y*d.y), 0.000001);
    col += hsv2rgb(vec3(0.5*length(p)+n-0.1*TIME, 0.85, g0));
    col += hsv2rgb(vec3(0.5*length(p)+n-0.1*TIME, 0.5, g1));
    p *= rr;
  }
  
  return col;
}

vec3 effect(vec2 p, vec2 pp) {
  float aa = 2.0/RESOLUTION.y;

  vec3 col = effect0(p, aa);
  col *= smoothstep(1.5, 0.5, length(pp));
  return col;
}

void main(void) {
  vec2 q = gl_FragCoord.xy/resolution.xy;
  vec2 p = -1. + 2. * q;
  vec2 pp = p;
  p.x *= RESOLUTION.x/RESOLUTION.y;
  vec3 col = effect(p, pp);
  col = aces_approx(col);
  col = sRGB(col);
  glFragColor = vec4(col, 1.0);
}
