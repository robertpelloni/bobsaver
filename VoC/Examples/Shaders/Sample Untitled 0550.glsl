#version 420

// original https://neort.io/art/bq66j043p9f6qoqnljcg

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sdRect(vec2 p, vec2 b) {
  p = abs(p) - b;
  return length(max(p, 0.0)) + min(max(p.x, p.y), 0.0);
}

float random(vec2 x){
  return fract(sin(dot(x,vec2(12.9898, 78.233))) * 43758.5453);
}

float srandom(vec2 x) {
  return 2.0 * random(x) - 1.0;
}

mat2 rotate(float r) {
  float c = cos(r);
  float s = sin(r);
  return mat2(c, s, -s, c);
}

float pipeline(vec2 p, vec2 seed) {
  p = p;
  vec2 pi = floor(p);
  vec2 pf = 2.0 * fract(p) - 1.0;

  bool top = random(pi + vec2(0.0, 0.0)) + 0.3 * srandom(pi + vec2(0.0, 0.0) + seed) < 0.5;
  bool bottom = random(pi + vec2(0.0, 1.0)) + 0.3 * srandom(pi + vec2(0.0, 1.0) + seed) < 0.5;
  bool right = random(pi + vec2(1.0, 0.0) + vec2(1000.0)) + 0.3 * srandom(pi + vec2(1.0, 0.0) + vec2(1000.0) + seed) < 0.5;
  bool left = random(pi + vec2(0.0, 0.0) + vec2(1000.0)) + 0.3 * srandom(pi + vec2(0.0, 0.0) + vec2(1000.0) + seed) < 0.5;

  float d = 1e6;
  float w = 0.15;
  d = min(d, top ? sdRect(pf - vec2(0.0, -0.5), vec2(w, 0.5 + w)) : 1e6);
  d = min(d, bottom ? sdRect(pf - vec2(0.0, 0.5), vec2(w, 0.5 + w)) : 1e6);
  d = min(d, right ? sdRect(pf - vec2(0.5, 0.0), vec2(0.5 + w, w)) : 1e6);
  d = min(d, left ? sdRect(pf - vec2(-0.5, 0.0), vec2(0.5 + w, w)) : 1e6);

  return d;
}

void main(void) {
  vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

  st += 0.1 * time;
  float d1 = pipeline(7.0 * st, vec2(0.14, 0.81));
  float d2 = pipeline(7.0 * st - 0.3, vec2(0.32, 0.47));
  float d3 = pipeline(7.0 * st - 0.6, vec2(0.69, 0.14));

  vec3 c = mix(vec3(0.0), vec3(0.8), smoothstep(0.05, 0.15, min(d1, min(d2, d3))));
  c = mix(vec3(0.0, 0.2, 0.8), c, smoothstep(0.0, 0.05, d1));
  c = mix(vec3(0.7, 0.7, 0.0), c, smoothstep(0.0, 0.05, d2));
  c = mix(vec3(0.7, 0.0, 0.0), c, smoothstep(0.0, 0.05, d3));

  glFragColor = vec4(c, 1.0);
}
