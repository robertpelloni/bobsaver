#version 420

// original https://www.shadertoy.com/view/WljfDz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// License CC0: Buggy pulsating galaxy
// Random coding led to a nice (IMO) pulsating galaxy
    
#define PI          3.141592654
#define TAU         (2.0*PI)
#define TIME        time
#define RESOLUTION  resolution

vec2 toPolar(vec2 p) {
  return vec2(length(p), atan(p.y, p.x));
}

vec2 toRect(vec2 p) {
  return p.x*vec2(cos(p.y), sin(p.y));
}

void rot(inout vec2 p, float a) {
  float c = cos(a);
  float s = sin(a);
  p = vec2(c*p.x + s*p.y, -s*p.x + c*p.y);
}

float noise1(vec2 p, vec2 o) {
  float s = 1.0;

  float a = cos(p.x);
  float b = cos(p.y);

  float c = cos((p.x+o.x)*sqrt(3.5));
  float d = cos((p.y+o.y)*sqrt(1.5));

  return a*b*c*d;
}

float galaxy(vec2 p, float a, float z) {
  vec2 pp = toPolar(p);
  pp.y += pp.x*3.0 + a;
  p = toRect(pp);
  
  p *= z;
  
  return noise1(p, -0.5*vec2(0.123, 0.213)*TIME);
}

float psin(float a) {
  return 0.5 + 0.5*sin(a);
}

float pmin(float a, float b, float k) {
  float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
  return mix( b, a, h ) - k*h*(1.0-h);
}

float pmax(float a, float b, float k) {
  return -pmin(-a, -b, k);
}

float height(vec2 p, float m) {
  float s = 0.0;
  float a = 1.0;
  float f = mix(0.0, 15.0, 1.0);
  float d = 0.0;
  rot(p, 0.075*TIME);
  for (int i = 0; i < 3; ++i) {
    float g = a*galaxy(p, 0.15*float(i) + -TIME*( + 0.1*float(i)), 0.9*f);
    s += g;
    a *= pmax(abs(s), 0.125, 0.25);
    f *= pmax(abs(s), 0.250, 3.);
    d += a;
  }
  
  float h = (0.5 + 0.5*(s/d));
  
  h *= exp(-2.5*dot(p,p));
  h += 0.25*pow(m, 15.0);
  h *= 1.25*m;
  
  return h;
}

vec3 normal(vec2 p, float m) {
  vec2 eps = vec2(4.0/RESOLUTION.y, 0.0);
  
  vec3 n;
  
  n.x = height(p - eps.xy, m) - height(p + eps.xy, m);
  n.y = 2.0*eps.x;
  n.z = height(p - eps.yx, m) - height(p + eps.yx, m);
  
  return normalize(n);
}

vec3 postProcess(vec3 col, vec2 q)  {
  col=pow(clamp(col,0.0,1.0),vec3(0.75)); 
  col=col*0.6+0.4*col*col*(3.0-2.0*col);
  col=mix(col, vec3(dot(col, vec3(0.33))), -0.4);
  col*=0.5+0.5*pow(19.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.7);
  return col;
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main(void) {
  vec2 q = gl_FragCoord.xy/RESOLUTION.xy;
  vec2 p = -1. + 2. * q;
  p.x *= RESOLUTION.x/RESOLUTION.y;
 
  vec2 pp = toPolar(p);
  float an = pp.y;
  float r2 = pp.x*pp.x;
 
  float a = PI*r2-TIME+0.125*sin(20.0*an-TIME);
 
  float m = mix(0.5, 1.0, psin(a))*exp(-0.025*r2);
  float h = height(p, m);
  float th = tanh(h);
  vec3 n = normal(p, m);

  vec3 lp1 = vec3(-2.0, 0.5, 2.0);
  vec3 lp2 = vec3(2.0, 0.5, 2.0);
  float hh = h;
  vec3 ld1 = normalize(lp1 - vec3(p.x, hh, p.y));
  vec3 ld2 = normalize(lp2 - vec3(p.x, hh, p.y));

  float diff1 = max(dot(ld1, n), 0.0);
  float diff2 = max(dot(ld2, n), 0.0);

  vec3 baseCol = hsv2rgb(vec3(psin(0.25*a), mix(0.25, 0.5, psin(1.25*a)), mix(0.5, 1.5, psin(0.25*a))));

  vec3 col = +vec3(0.0);
  col += baseCol*h;
  col -= 0.5*baseCol.zyx*pow(diff1, 10.0);
  col -= 0.25*baseCol.yzx*pow(diff2, 5.0);
  col += sqrt(baseCol)*pow(tanh(2.0*h), 1.0);

  col = postProcess(col, q);
  col = clamp(1.0 - col, 0.0, 1.0);

  glFragColor = vec4(col, 1.0);
}

