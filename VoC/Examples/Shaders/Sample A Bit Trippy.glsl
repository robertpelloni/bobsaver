#version 420

// original https://www.shadertoy.com/view/cllGWB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// CC0: A bit trippy...
//  This didn't come out at all as I was intending.

// Comment to remove kaleidoscope effect
#define KALEIDOSCOPE

// Try other numbers like 2.0, 6.0, 10.0
//  Odd numbers don't really work because I am lazy.
#define REP         36.0

#define TIME        time
#define RESOLUTION  resolution
#define PI          3.141592654
#define TAU         (2.0*PI)
#define ROT(a)      mat2(cos(a), sin(a), -sin(a), cos(a))

const float ExpBy = log2(1.2);

// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
const vec4 hsv2rgb_K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
vec3 hsv2rgb(vec3 c) {
  vec3 p = abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www);
  return c.z * mix(hsv2rgb_K.xxx, clamp(p - hsv2rgb_K.xxx, 0.0, 1.0), c.y);
}
// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
//  Macro version of above to enable compile-time constants
#define HSV2RGB(c)  (c.z * mix(hsv2rgb_K.xxx, clamp(abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www) - hsv2rgb_K.xxx, 0.0, 1.0), c.y))

// License: Unknown, author: Unknown, found: don't remember
float hash(vec2 co) {
  return fract(sin(dot(co.xy ,vec2(12.9898,58.233))) * 13758.5453);
}

// License: MIT, author: Inigo Quilez, found: https://www.iquilezles.org/www/articles/smin/smin.htm
float pmin(float a, float b, float k) {
  float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
  return mix(b, a, h) - k*h*(1.0-h);
}

// License: MIT OR CC-BY-NC-4.0, author: mercury, found: https://mercury.sexy/hg_sdf/
float modMirror1(inout float p, float size) {
  float halfsize = size*0.5;
  float c = floor((p + halfsize)/size);
  p = mod(p + halfsize,size) - halfsize;
  p *= mod(c, 2.0)*2.0 - 1.0;
  return c;
}

// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
float pabs(float a, float k) {
  return -pmin(a, -a, k);
}

// License: Unknown, author: Unknown, found: don't remember
float tanh_approx(float x) {
  //  Found this somewhere on the interwebs
  //  return tanh(x);
  float x2 = x*x;
  return clamp(x*(27.0 + x2)/(27.0+9.0*x2), -1.0, 1.0);
}

// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
vec2 toPolar(vec2 p) {
  return vec2(length(p), atan(p.y, p.x));
}

// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
vec2 toRect(vec2 p) {
  return vec2(p.x*cos(p.y), p.x*sin(p.y));
}

// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
float smoothKaleidoscope(inout vec2 p, float sm, float rep) {
  vec2 hp = p;

  vec2 hpp = toPolar(hp);
  float rn = modMirror1(hpp.y, TAU/rep);

  float sa = PI/rep - pabs(PI/rep - abs(hpp.y), sm);
  hpp.y = sign(hpp.y)*(sa);

  hp = toRect(hpp);

  p = hp;

  return rn;
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float box(vec2 p, vec2 b) {
  vec2 d = abs(p)-b;
  return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float forward(float n) {
  return exp2(ExpBy*n);
}

float reverse(float n) {
  return log2(n)/ExpBy;
}

vec2 cell(float n) {
  float n2  = forward(n);
  float pn2 = forward(n-1.0);
  float m   = (n2+pn2)*0.5;
  float w   = (n2-pn2)*0.5;
  return vec2(m, w);
}

vec2 df(vec2 p, float aa) {
  float tm = TIME;
  float m = fract(tm);
  float f = floor(tm);
  float z = forward(m);
  
  vec2 p0 = p;
  p0 /= z;
  vec2 sp0 = sign(p0);
  p0 = abs(p0);

  float l0x = p0.x;
  float n0x = ceil(reverse(l0x));
  vec2 c0x  = cell(n0x); 

  float l0y = p0.y;
  float n0y = ceil(reverse(l0y));
  vec2 c0y  = cell(n0y); 

  float h0 = hash(vec2(n0x, n0y)-vec2(f)+vec2(sp0.x, sp0.y));

  vec2 pp = vec2(p0.x, p0.y);
  vec2 oo = vec2(c0x.x, c0y.x);
  vec2 cc = vec2(c0x.y, c0y.y);
  pp -= oo;
  
  float rr = 0.0033/z;
  float d1 = box(pp, cc-2.0*rr)-rr;
  
  float d = d1;
  d *= z;

  return vec2(d, h0);
}

vec4 effect(vec2 p, float hue) {
  float aa =2.0/RESOLUTION.y;
  vec2 d2 = df(p, aa);

  float fd = min(abs(p.x), abs(p.y));
  vec3 col = vec3(0.0);
  vec3 bcol = hsv2rgb(vec3(fract(hue+0.3*d2.y), 0.85, 1.0));
  return vec4(bcol, smoothstep(aa, -aa, d2.x));
}

void main(void) {
  vec2 q = gl_FragCoord.xy/RESOLUTION.xy;
  vec2 p = -1. + 2. * q;
  vec2 ppp = p;
  p.x *= RESOLUTION.x/RESOLUTION.y;
  float hue = -length(p)+0.1*TIME; 

  vec2 pp = p;
  const float rep = REP;
  const float sm  = 0.05*36.0/REP;
#if defined(KALEIDOSCOPE)
  float nn = smoothKaleidoscope(pp, sm, rep);
#endif  
  pp *= ROT(0.05*TIME-0.5*length(p));
  vec3 col = vec3(0.0);
  vec4 col0 = effect(pp, hue);
  col = mix(col, col0.xyz, col0.w);

  col += hsv2rgb(vec3(hue, 0.66, 4.0))*mix(1.0, 0.0, tanh_approx(2.0*sqrt(length(p))));
  col *= smoothstep(1.5, 0.5, length(ppp));
  col = sqrt(col);
  glFragColor = vec4(col, 1.0);
}
