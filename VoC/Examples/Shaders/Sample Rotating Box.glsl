#version 420

// original https://www.shadertoy.com/view/cly3RR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// CC0: Rotating box
//  Saw a tweet by @XorDev where he showed the neat trick of time-sin(time)
//  Tried it, tinkered with it and published it
//  https://twitter.com/XorDev/status/1654553771001749504

#define TIME        time
#define RESOLUTION  resolution
#define PI          3.141592654
#define TAU         (2.0*PI)
#define ROT(a)      mat2(cos(a), sin(a), -sin(a), cos(a))

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float box(vec2 p, vec2 b) {
  vec2 d = abs(p)-b;
  return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

void main(void) {
  const float per = 4.0;
  vec2 q = gl_FragCoord.xy/RESOLUTION.xy;
  vec2 p = -1. + 2. * q;
  float aa = 4.0/RESOLUTION.y;
  p.x *= RESOLUTION.x/RESOLUTION.y;
  vec2 p0 = p;
  float a0 = TAU*TIME/per;
  p0 *= ROT(a0-sin(a0));
  vec3 col = vec3(1.0);
  float d0 = box(p0, vec2(0.25));
  float a1 = a0 - TAU*d0/20.0;
  vec2 p1 = p;
  p1 *= ROT(a1-sin(a1));
  float d1 = box(p1, vec2(0.5));
  col = mix(col, vec3(0.0), smoothstep(0.0, -aa, d0));
  float m = TAU*10.0;
  col = mix(col, vec3(0.0), smoothstep(0.0, -aa*m, sin(m*d1-TAU*TIME/per)));
  col = sqrt(col);
  
  glFragColor = vec4(col, 1.0);
}

