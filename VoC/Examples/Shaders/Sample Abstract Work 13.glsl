#version 420

// original https://neort.io/art/bn0lvlc3p9f7m1g03fog

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rotate(float r) {
  float c = cos(r);
  float s = sin(r);
  return mat2(c, s, -s, c);
}

float random(float x){
  return fract(sin(x * 12.9898) * 43758.5453);
}

float srandom(float x) {
  return 2.0 * random(x) - 1.0;
}

float random(vec2 x){
  return fract(sin(dot(x,vec2(12.9898, 78.233))) * 43758.5453);
}

float srandom(vec2 x) {
  return 2.0 * random(x) - 1.0;
}

float sdSphere(vec2 p, float r) {
  return length(p) - r;
}

float getShape(vec2 p, float seed) {
  p += 1.2 * vec2(srandom(seed + 0.143), srandom(seed + 0.431));
  for (float i = 1.0; i < 5.0; i += 1.0) {
    p.x += 0.23 * srandom(i + seed + 1.42) * sin(3.25 * p.y + 1.45 * srandom(i + seed + 0.23) * time + random(i + seed));
    p.y += 0.19 * srandom(i + seed + 1.58) * sin(2.48 * p.x + 1.19 * srandom(i + seed + 0.91)* time + random(i + seed));
    p *= rotate(4.5 * srandom(i + seed + 1.29));
  }
  return exp(-1.5 * max(0.0, sdSphere(p, 0.4 + 0.2 * random(seed))));
}

void main(void) {
  vec2 p = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

  vec3 c = vec3(0.13, 0.86, 0.86);
  c = mix(c, vec3(0.96, 0.43, 0.62), getShape(p, 1.13));
  c = mix(c, vec3(0.95, 0.95, 0.45), getShape(p, 1.43));
  c = mix(c, vec3(0.51, 0.24, 0.85), getShape(p, 1.90));
  c = mix(c, vec3(0.84, 0.43, 0.12), getShape(p, 2.39));

  c *= 1.0 + 0.02 * srandom(p);

  glFragColor = vec4(c, 1.0);
}
