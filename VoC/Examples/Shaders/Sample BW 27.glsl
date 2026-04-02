#version 420

// original https://neort.io/art/bpo5ovc3p9fbkbq854og

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359

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

mat2 rotate(float r) {
  float c = cos(r);
  float s = sin(r);
  return mat2(c, s, -s, c);
}

void main(void) {
  vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

  vec2 p = 5.0 * st;
  vec2 pi = floor(p);
  vec2 pf = 2.0 * fract(p) - 1.0;

  pf *= rotate((pi.x + pi.y) * 0.5 * PI);

  vec2 q = pf;
  q.x = mod(q.x, 0.5) - 0.25;

  float t = 8.0 * time + length(pi);
  float tf = fract(t);

  float l = mix(0.2, 0.8, sin(t) * 0.5 + 0.5);

  float r = 0.1;
  float d = sdCapsule(q + vec2(0.0, (1.0 - (l + r + 0.1))), vec2(r, l));

  float c = smoothstep(0.0, 0.05, d);

  glFragColor = vec4(vec3(c), 1.0);
}
