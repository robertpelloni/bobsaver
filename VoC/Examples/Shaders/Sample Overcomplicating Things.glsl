#version 420

// original https://www.shadertoy.com/view/DsXcWn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// CC0: Overcomplicating things
//  I really enjoyed the color explosion and simplicity of kishimisu's
//  https://www.shadertoy.com/view/mtyGWy
//  So I decided to overcomplicate it!
//  It's still pretty colorful

#define TIME        time
#define RESOLUTION  resolution
#define PI          3.141592654
#define TAU         (2.0*PI)
#define ROT(a)      mat2(cos(a), sin(a), -sin(a), cos(a))

vec3 palette( float t ) {
  return (1.0+cos(vec3(0.0, 1.0, 2.0)+TAU*t))*0.5;
}

// License: MIT, author: Inigo Quilez, found: https://www.iquilezles.org/www/articles/smin/smin.htm
float pmin(float a, float b, float k) {
  float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
  return mix(b, a, h) - k*h*(1.0-h);
}

float pmax(float a, float b, float k) {
  return -pmin(-a, -b, k);
}

float pabs(float a, float k) {
  return pmax(a, -a, k);
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

vec2 toPolar(vec2 p) {
  return vec2(length(p), atan(p.y, p.x));
}

vec2 toRect(vec2 p) {
  return vec2(p.x*cos(p.y), p.x*sin(p.y));
}

float modMirror1(inout float p, float size) {
  float halfsize = size*0.5;
  float c = floor((p + halfsize)/size);
  p = mod(p + halfsize,size) - halfsize;
  p *= mod(c, 2.0)*2.0 - 1.0;
  return c;
}

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

// License: Unknown, author: kishimisu, found: https://www.shadertoy.com/view/mtyGWy
vec3 kishimisu(vec3 col, vec2 p) {
  vec2 p0 = p;
  vec3 finalColor = vec3(0.0);
    
  vec2 p1 = p;
  for (float i = 0.0; i < 4.0; i++) {
    p1 = fract(p1 * 2.0+0.0125*TIME) - 0.5;

    float d = length(p1) * exp(-length(p0));

    vec3 cc = palette(length(p0) + i*.4 + TIME*.2);

    d = sin(d*8. + TIME)/8.;
    d = abs(d);

    d = max(d, 0.005);
    d = (0.0125 / d);
    d *= d;

    col += cc * d;
  }

  return col;  
}

vec3 effect(vec2 p, vec2 pp) {
  vec3 col = vec3(0.0);
  mat2 rot = ROT(0.025*TIME); 
  p *= rot;
  vec2 kp = p;
  float r  = RESOLUTION.x/RESOLUTION.y;
  kp.x -= r-0.125;
  float kl = dot(kp, kp);
  float kn = smoothKaleidoscope(kp, 0.05, 50.0);
  kp += 0.5*sin(vec2(1.0, sqrt(0.5))*TIME*0.21);
  kp /= r;
  col = kishimisu(col, kp);
  col = clamp(col, 0.0, 4.0);
  vec3 scol = palette(0.125*TIME);
  col += 0.025*scol*scol/max(length(kl), 0.001);
  col -= .0033*vec3(1.0, 2.0, 3.0).zyx*kl;
  col = aces_approx(col);
  col = max(col, 0.0);
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
