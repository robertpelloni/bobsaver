#version 420

// original https://neort.io/art/bmnhesc3p9f7m1g024eg

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define linearstep(edge0, edge1, x) min(1.0, max(0.0, (x - edge0) / (edge1 - edge0)))

float random(float x){
    return fract(sin(x * 12.9898) * 43758.5453);
}

vec2 random2(float x) {
    return fract(sin(x * vec2(12.9898, 51.431)) * vec2(43758.5453, 71932.1354));
}

vec2 srandom2(float x) {
  return random2(x) * 2.0 - 1.0;
}

float sdRect(vec2 p, vec2 r) {
  p = abs(p) - r;
  return length(max(p, 0.0)) + min(max(p.x, p.y), 0.0);
}

float sdHoleRect(vec2 p, vec2 outer, vec2 inner) {
  return max(sdRect(p, outer), -sdRect(p, inner));
}

mat2 rotate(float r) {
  float c = cos(r);
  float s = sin(r);
  return mat2(c, s, -s, c);
}

const float REPEAT = 1.0;
float sdMotionRect(vec2 p, float seed) {
  float tOffset = random(seed) * 10.0;
  float t = time + tOffset;
  float repT = mod(t, REPEAT) / REPEAT;
  float idxT = floor(t / REPEAT);
  vec2 offset = srandom2(seed * 1.19 + idxT * 0.34) * 1.0;
  vec2 outer = vec2(0.1) * smoothstep(0.0, 0.3, repT);
  vec2 inner = vec2(0.101) * smoothstep(0.7, 1.0, repT);
  float rot = 1.5 * linearstep(0.7, 1.0, repT);
  return sdHoleRect((p - offset) * rotate(rot), outer, inner);
}

vec3 background(vec2 p) {
  p *= rotate(0.3);
  return mix(vec3(0.98, 0.95, 0.95), vec3(0.85, 0.95, 0.15),
    step(abs(p.y), 0.5) * smoothstep(0.9, 0.91, sin(p.x * 0.3 - time * 2.0)) * smoothstep(-0.5, 0.5, sin(p.y * 80.0)));
}

void main(void) {
  vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

  vec3 c = vec3(0.0);
  float d = 1e6;
  for (float i = 0.0; i < 20.0; i += 1.0) {
    d = min(d, sdMotionRect(st, i));
  }

  c = background(st);
  c = mix(vec3(0.15, 0.45, 0.95), c, smoothstep(0.0, 0.005, d));

  glFragColor = vec4(c, 1.0);
}
