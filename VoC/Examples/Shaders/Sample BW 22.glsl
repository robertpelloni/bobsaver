#version 420

// original https://neort.io/art/bpj46nk3p9fbkbq831a0

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359

mat2 rotate(float r) {
  float c = cos(r);
  float s = sin(r);
  return mat2(c, s, -s, c);
}

mat2 skewX(float r) {
  float t = tan(r);
  return mat2(1.0, -r, 0.0, 1.0);
}

void main(void) {
  vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

  st *= rotate(0.25);

  vec2 p = vec2(8.0, 3.0) * st;
  vec2 pi = floor(p);
  p.x -= time * (100.0 + 10.0 * pi.y) * 0.05;
  p = vec2(p.x, fract(p.y) * 2.0 - 1.0);
  p *= skewX(-sign(p.y) * PI * 0.8);

  vec2 pf = fract(p);

  float ay = abs(p.y);
  float cx = smoothstep(0.1, 0.4, abs(2.0 * pf.x - 1.0)) * (1.0 - smoothstep(0.8, 0.85, ay));
  float cy = (1.0 - smoothstep(0.8, 0.85, ay)) + smoothstep(0.9, 0.925, ay) * (1.0 - smoothstep(0.925, 0.95, ay));
  float c = cx + (1.0 - cy);

  glFragColor = vec4(vec3(1.0 - c), 1.0);
}
