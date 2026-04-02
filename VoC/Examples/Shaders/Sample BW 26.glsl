#version 420

// original https://neort.io/art/bpn1o3c3p9fbkbq84jp0

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float random(float x){
  return fract(sin(x * 12.9898) * 43758.5453);
}

float sdCircle(vec2 p, float r) {
  return length(p) - r;
}

float sdRect(vec2 p, vec2 b) {
  p = abs(p) - b;
  return length(max(p, 0.0)) + min(max(p.x, p.y), 0.0);
}

float sdCapsule(vec2 p, vec2 c) {
  return min(sdRect(p, c), sdCircle(abs(p) - vec2(0.0, c.y), c.x));
}

void main(void) {
  vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

  vec2 p = 10.0 * st;

  float t = 3.5 * time;
  p.x += t;

  float pxi = floor(p.x);

  vec2 q = p;
  q.x = 2.0 * fract(p.x) - 1.0;

  float h = 0.35 + mix(0.0, 1.0 + 5.0 * random(pxi), smoothstep(1.0, -1.0, pxi - t));
  float d = sdCapsule(q, vec2(0.35, h));

  float c = smoothstep(0.0, 0.05, d);

  glFragColor = vec4(vec3(c), 1.0);
}
