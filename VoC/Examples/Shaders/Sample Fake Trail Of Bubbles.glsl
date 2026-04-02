#version 420

// original https://www.shadertoy.com/view/mtc3Wl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// CC0: Fake trail of bubbles
// Was tinkering with bubble trail earlier
// This version uses the distance field and how
// quickly it changes to determine the intensity of the trail
// Very fake but looked decent enough to share.

#define TIME        time
#define RESOLUTION  resolution
#define PI          3.141592654
#define TAU         (2.0*PI)
#define ROT(a)      mat2(cos(a), sin(a), -sin(a), cos(a))

// License: Unknown, author: Unknown, found: don't remember
float hash(vec2 co) {
  return fract(sin(dot(co.xy ,vec2(12.9898,58.233))) * 13758.5453);
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float box(vec2 p, vec2 b) {
  vec2 d = abs(p)-b;
  return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float df(vec2 p, float tm) {
  vec2 p0 = p; 
  p0 += 0.71*sin(vec2(1.0, sqrt(0.5))*0.5*tm);
  p0 *= ROT(-tm*0.5);
  float d = box(p0, vec2(0.25, 0.01));
  return d;
}

vec3 bubbles(vec3 col, vec2 p) {
  float aa = 4.0/RESOLUTION.y;
  for (float i = 1.0; i < 10.0; ++i) {
    float sz = 0.3/(1.0+i);
    vec2 off = vec2(0.123*i);
    vec2 pp = p+off;
    pp /= sz;
    vec2 rp = round(pp);
    vec2 cp = pp;
    cp -= rp;
    const float delta = .01;
    float dp = df(rp*sz-off, TIME-delta);
    float dn = df(rp*sz-off, TIME);
    float dd = (dn-dp)/delta;
    float h0 = hash(rp);
    float h1 = fract(3677.0*h0);
    float h2 = fract(8677.0*h0);
    float r  = sqrt(h0)/3.0;
    r *= tanh(4.0*dd);
    cp -= (0.5-r)*vec2(h1, h2);
    float fo = smoothstep(12.0*sz*r, -0.1, dn);
    float d = (length(cp)-mix(r, 0., fo));
    d = abs(d);
    d *= sz;
    d -= aa*0.75;
    vec3 bcol = vec3(2.0*sqrt(fo))*smoothstep(0.0, -aa, d)*step(0.0, dd)*smoothstep(-0.05, 0.1, dn);
    col += bcol;
  }
  return col;
}

vec3 effect(vec2 p, vec2 pp) {
  float ds = df(p, TIME);
  vec3 col = vec3(0.0);
  col = bubbles(col, p);
  float aa = 4.0/RESOLUTION.y;
  col = mix(col, vec3(1.0, 0.0, 0.25), smoothstep(0.0, -aa, ds));
  col = sqrt(col);
  return col;
}

void main(void) {
  vec2 q = gl_FragCoord.xy/RESOLUTION.xy;
  vec2 p = -1. + 2. * q;
  vec2 pp = p;
  p.x *= RESOLUTION.x/RESOLUTION.y;
  vec3 col = effect(p, pp);
  glFragColor = vec4(col, 1.0);
}
