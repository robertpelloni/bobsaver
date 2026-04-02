#version 420

// original https://www.shadertoy.com/view/Wl3cR7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// License CC0 - "Circular" Pattern Tiling
//  I wanted to create "circular" tiling, turned out ok
//  mod1  - From: http://mercury.sexy/hg_sdf/
//  star5 - From: https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm

#define PI  3.141592654
#define TAU (2.0*PI)

float mod1(inout float p, float size) {
  float halfsize = size*0.5;
  float c = floor((p + halfsize)/size);
  p = mod(p + halfsize, size) - halfsize;
  return c;
}

vec2 toRect(vec2 p) {
  return p.x*vec2(cos(p.y), sin(p.y));
}

vec2 toPolar(vec2 p) {
  return vec2(length(p), atan(p.y, p.x));
}

// Like many tiling functions modifies the input argument
//  and returns a vector indicating which tile we are in
vec3 modCircularPattern(inout vec2 p) {
  vec2 pp = toPolar(p);

  float nx = floor(pp.x + 0.5);
  pp.x -= nx;
  mod1(pp.x, 1.0);
  pp.x += nx;
  float cy = floor(0.5*nx*TAU)*2.0;
  
  float ny = mod1(pp.y, TAU/cy);
  if(nx > 0.0) {
    p = toRect(pp) - vec2(nx, 0.0);
    return vec3(nx, mod(ny+cy*0.5, cy), cy);
  } else {
    return vec3(0.0, 0.0, 1.0);
  }
}

void rot(inout vec2 p, float a) {
  float c = cos(a);
  float s = sin(a);
  p = vec2(c*p.x+s*p.y, -s*p.x+c*p.y);
}

float star5(vec2 p, float r, float rf) {
  const vec2 k1 = vec2(0.809016994375, -0.587785252292);
  const vec2 k2 = vec2(-k1.x,k1.y);
  p.x = abs(p.x);
  p -= 2.0*max(dot(k1,p),0.0)*k1;
  p -= 2.0*max(dot(k2,p),0.0)*k2;
  p.x = abs(p.x);
  p.y -= r;
  vec2 ba = rf*vec2(-k1.y,k1.x) - vec2(0,1);
  float h = clamp( dot(p,ba)/dot(ba,ba), 0.0, r );
  return length(p-ba*h) * sign(p.y*ba.x-p.x*ba.y);
}

float df(vec2 p) {
  const float lw = 0.033;

  float nx = floor(length(p) + 0.5);
  rot(p, time/sqrt(1.0+nx));

  vec3 n = modCircularPattern(p);

  rot(p, 0.1*TAU*(n.y+n.x));;

  float d = star5(p, 0.5-lw, 0.5);  
  d = abs(d) - lw;

  return d;
}

void main(void) {
  vec2 q = gl_FragCoord.xy / resolution.xy;
  vec2 p = -1.0 + 2.0*q;
  p.x *= resolution.x/resolution.y;

  float aa = 2.0/resolution.y;
  
  float s = 0.25*mix(0.1, 1.0, 0.5+0.5*sin(time*0.5));
  float d = df(p/s)*s;
  
  vec3 col = mix(vec3(1.0), vec3(0.125), tanh(length(0.05*p/s)));
  
  col = mix(col, vec3(0.0), smoothstep(-aa, aa, -d));
  col = pow(col, vec3(1.0/2.2));
  
  glFragColor = vec4(col,1.0);
}
