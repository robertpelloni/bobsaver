#version 420

// original https://www.shadertoy.com/view/mtB3DW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// CC0: Multi-level metaballs
//  Continuing yesterday experiments + an old shader

#define TIME        time
#define RESOLUTION  resolution
#define PI          3.141592654
#define TAU         (2.0*PI)
#define ROT(a)      mat2(cos(a), sin(a), -sin(a), cos(a))

// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
const vec4 hsv2rgb_K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
vec3 hsv2rgb(vec3 c) {
  vec3 p = abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www);
  return c.z * mix(hsv2rgb_K.xxx, clamp(p - hsv2rgb_K.xxx, 0.0, 1.0), c.y);
}

// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
//  Macro version of above to enable compile-time constants
#define HSV2RGB(c)  (c.z * mix(hsv2rgb_K.xxx, clamp(abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www) - hsv2rgb_K.xxx, 0.0, 1.0), c.y))

float circle(vec2 p, float r) {
  return length(p) - r;
}

// License: MIT OR CC-BY-NC-4.0, author: mercury, found: https://mercury.sexy/hg_sdf/
vec2 mod2(inout vec2 p, vec2 size) {
  vec2 c = floor((p + size*0.5)/size);
  p = mod(p + size*0.5,size) - size*0.5;
  return c;
}

// License: Unknown, author: Hexler, found: Kodelife example Grid
float hash(vec2 uv) {
  return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

// License: Unknown, author: Unknown, found: don't remember
float tanh_approx(float x) {
  //  Found this somewhere on the interwebs
  //  return tanh(x);
  float x2 = x*x;
  return clamp(x*(27.0 + x2)/(27.0+9.0*x2), -1.0, 1.0);
}

float df(vec2 p, out float n, out float sc) {
  vec2 pp = p;
  
  float sz = 2.0;
  
  float r = 0.0;
  
  for (int i = 0; i < 5; ++i) {
    vec2 nn = mod2(pp, vec2(sz));
    sz /= 3.0;
    float rr = hash(nn+123.4);
    r += rr;
    if (rr < 0.5) break;
  }
  
  float d = circle(pp, 1.25*sz);
  
  n = fract(r);
  sc = sz;
  return d;
}

vec2 toSmith(vec2 p)  {
  // z = (p + 1)/(-p + 1)
  // (x,y) = ((1+x)*(1-x)-y*y,2y)/((1-x)*(1-x) + y*y)
  float d = (1.0 - p.x)*(1.0 - p.x) + p.y*p.y;
  float x = (1.0 + p.x)*(1.0 - p.x) - p.y*p.y;
  float y = 2.0*p.y;
  return vec2(x,y)/d;
}

vec2 fromSmith(vec2 p)  {
  // z = (p - 1)/(p + 1)
  // (x,y) = ((x+1)*(x-1)+y*y,2y)/((x+1)*(x+1) + y*y)
  float d = (p.x + 1.0)*(p.x + 1.0) + p.y*p.y;
  float x = (p.x + 1.0)*(p.x - 1.0) + p.y*p.y;
  float y = 2.0*p.y;
  return vec2(x,y)/d;
}

vec2 transform(vec2 p) {
  p *= 3.0;
  const mat2 rot0 = ROT(1.0);
  const mat2 rot1 = ROT(-2.0);
  vec2 off0 = 4.0*cos(vec2(1.0, sqrt(0.5))*0.23*TIME);
  vec2 off1 = 3.0*cos(vec2(1.0, sqrt(0.5))*0.13*TIME);
  vec2 sp0 = toSmith(p);
  vec2 sp1 = toSmith((p+off0)*rot0);
  vec2 sp2 = toSmith((p-off1)*rot1);
  vec2 pp = fromSmith(sp0+sp1-sp2);
  pp += 0.25*TIME;
  return pp;
}

vec3 effect(vec2 p, vec2 np, vec2 pp) {
  p = transform(p);
  np = transform(np);
  float aa = distance(p, np)*sqrt(2.0); 

  const float r = 25.0;
  float a = 0.05*TAU*TIME/r;
  const float z = 1.0;
  p /= z;
  float n = 0.0;
  float sc = 0.0;
  float d = df(p, n, sc)*z;

  vec3 col = vec3(0.0);
  vec3 hsv = vec3(n-0.25*d/sc, 0.5+0.5*d/sc, 1.0);
  vec3 rgb = hsv2rgb(hsv);
  col = mix(col, rgb, smoothstep(aa, -aa, d));
  
  const vec3 gcol1 = HSV2RGB(vec3(0.55, 0.6667, 3.0)); 
  
  col *= smoothstep(0.25, 0., aa);
  col += gcol1*tanh_approx(0.05*aa);
  col *= smoothstep(1.5, 0.5, length(pp));
  
  col = sqrt(col);
  return col;
}

void main(void) {
  vec2 q = gl_FragCoord.xy/RESOLUTION.xy;
  vec2 p = -1. + 2. * q;
  vec2 pp = p;
  p.x *= RESOLUTION.x/RESOLUTION.y;
  vec2 np = p+1.0/RESOLUTION.y;
  vec3 col = effect(p, np, pp);
  glFragColor = vec4(col, 1.0);
}

