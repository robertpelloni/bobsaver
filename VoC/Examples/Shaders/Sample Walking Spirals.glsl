#version 420

// original https://www.shadertoy.com/view/ddcGDl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// CC0: Walking spirals
//  Once again inspired by twitter stuff: https://twitter.com/junkiyoshi/status/1632340637218672641?s=20

#define TIME        time
#define RESOLUTION  resolution
#define PI          3.141592654
#define TAU         (2.0*PI)
#define ROT(a)      mat2(cos(a), sin(a), -sin(a), cos(a))

// License: MIT OR CC-BY-NC-4.0, author: mercury, found: https://mercury.sexy/hg_sdf/
float mod1(inout float p, float size) {
  float halfsize = size*0.5;
  float c = floor((p + halfsize)/size);
  p = mod(p + halfsize, size) - halfsize;
  return c;
}

float spiralLength(float b, float a) {
  // https://en.wikipedia.org/wiki/Archimedean_spiral
  return 0.5*b*(a*sqrt(1.0+a*a)+log(a+sqrt(1.0+a*a)));
}

void spiralMod(inout vec2 p, float a) {
  vec2 op     = p;
  float b     = a/TAU;
  float  rr   = length(op);
  float  aa   = atan(op.y, op.x);
  rr         -= aa*b;
  float nn    = mod1(rr, a);
  float sa    = aa + TAU*nn;
  float sl    = spiralLength(b, sa);
  p           = vec2(sl, rr);
}

float segmentx(vec2 p, float l, float r) {
  float hl = l*0.5-r;
  
  p.x = abs(p.x);
  
  float d0 = abs(p.y) -r;
  float d1 = length(p - vec2(hl, 0.0))-r;
  return p.x > hl ? d1 : d0;
}

float doubleSpiral(vec2 p, float speed, float toff) {
  float tm = speed*TIME;
  const float PERIOD = 14.0;
  tm += PERIOD*(toff-0.5);
  mod1(tm, PERIOD);
  float a = fract(tm);
  float nt = floor(tm);

  const float lw = 0.01;
  const float off = 0.376;
  p.x -= (nt)*off+lw;
  p.y *= mix(1.0, -1.0, mod(nt, 2.0));
  vec2 sp0 = p;
  vec2 sp1 = p;
  
  sp1.x -= off;
  sp1.y = -sp1.y;
  
  spiralMod(sp0, .05);
  spiralMod(sp1, .05);

  vec2 sp2 = sp1;

  const float l = 8.87;
  sp0.x -= 0.75*l - a*l;
  sp1.x -= 0.75*l - (a-1.0)*l;

  float d0 = segmentx(sp0, 0.5*l, lw);
  float d1 = segmentx(sp1, 0.5*l, lw);
  float d2 = -sp2.x+l;
  
  float d = d0;
  d = min(d, max(-d2, d1));
  
  return d;
}

// License: Unknown, author: Unknown, found: don't remember
float hash(float co) {
  return fract(sin(co*12.9898) * 13758.5453);
}

vec3 effect(vec2 p, vec2 pp) {
  float aa = 2.0/RESOLUTION.y;
  vec3 col = vec3(0.0);

  for (float i = 0.0; i < 7.0; ++i) {
    vec2 sp = p;
    sp *= ROT(TAU*i/3.5);
    float nx = mod1(sp.y, 1.0);
    float h0 = hash(nx+123.2+i);
    float h1 = fract(3677.0*h0);
    float h2 = fract(8677.0*h0);
    float h3 = fract(9677.0*h0);
    float z = mix(0.66, 1.0, h2); 
    sp /= z;
    float dd = doubleSpiral(sp, 0.5*mix(0.1, 0.4, h0*h0), h1)*z;
    vec3 bcol = (1.0+cos(1.5*vec3(2.0, 0.0, -1.0)+TAU*h3));
    col += bcol*smoothstep(aa, -aa, dd);
  }

  col = 1.0-tanh(col.yxz);
  col *= vec3(1.0, 0.95, 0.95);
  col = sqrt(col);
  return col;
}

void main(void) {
  vec2 q = gl_FragCoord.xy/RESOLUTION.xy;;
  vec2 p = -1. + 2. * q;
  vec2 pp = p;
  p.x *= RESOLUTION.x/RESOLUTION.y;
  vec3 col = effect(p, pp);
  
  glFragColor = vec4(col, 1.0);
}

