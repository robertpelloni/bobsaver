#version 420

// original https://www.shadertoy.com/view/XlBBWG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Matthew Arcus, 2018
// Wythoff construction for dual snub quadrille tessellation

vec2 perp(vec2 r) {
  return vec2(-r.y,r.x);
}

vec3 getcol(int i) {
  if (i == 0) return vec3(1,0,0);
  if (i == 1) return vec3(0,1,0);
  if (i == 2) return vec3(0,0,1);
  if (i == 3) return vec3(1,1,0);
  return vec3(1,1,1);
}

// segment function by FabriceNeyret2
float segment(vec2 p, vec2 a, vec2 b) {
  vec2 pa = p - a;
  vec2 ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  float d = length(pa - ba * h);
  return d;
}

int imod(int n, int m) {
    return n - n/m*m;
}
void main(void) {
  float scale = 2.5;
  float lwidth = 0.025;
  // Half the width of the AA line edge
  float aawidth = 1.5*scale/resolution.y;
  vec2 q,p = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
  //if (mouse*resolution.xy.x > 5.0) {
  //  q = (mouse*resolution.xy.xy-25.0)/(resolution.xy-50.0);
  //  q = clamp(q,0.0,1.0);
  //} else {
    // Just bouncing around
    q = mod(0.3*time*vec2(1,1.618),2.0);
    q = min(q,2.0-q);
  //}
  p *= scale;
  p = mod(p,2.0)-1.0; // Fold down to ±1 square
  int parity = int((p.y < 0.0) != (p.x < 0.0)); // Reflection?
  int col = 1+2*int(p.x < 0.0) + parity; // Quadrant
  p = abs(p);
  if (parity != 0) p.xy = p.yx;
  // Lines from triangle vertices to Wythoff point
  float d = 1e8;
  d = min(d,segment(p,vec2(0,0),q));
  d = min(d,segment(p,vec2(1,0),q));
  d = min(d,segment(p,vec2(1,1),q));
  d = min(d,segment(p,vec2(-q.y,q.x),vec2(q.y,-q.x)));
  d = min(d,segment(p,vec2(-q.y,q.x),vec2(q.y,2.0-q.x)));
  d = min(d,segment(p,vec2(2.0-q.y,q.x),vec2(q.y,2.0-q.x)));
  // Color - what side of the lines are we?
  float a = dot(p-q,perp(vec2(0,0)-q));
  float b = dot(p-q,perp(vec2(1,0)-q));
  float c = dot(p-q,perp(vec2(1,1)-q));
  if (a > 0.0 && b < 0.0) col++;
  if (c < 0.0 && b > 0.0) col--;
  // How to write non-portable code: take the modulus of a negative number
  vec3 ccol = getcol(imod(col,4));
  ccol = mix(ccol,vec3(1),0.3);
  ccol = mix(vec3(0.1),ccol,smoothstep(lwidth-aawidth,lwidth+aawidth,d));
  glFragColor = vec4(sqrt(ccol),1.0);
}
