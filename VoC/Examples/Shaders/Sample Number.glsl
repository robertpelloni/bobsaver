#version 420

// original https://neort.io/art/bq8rc1c3p9f6qoqnma7g

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359

float random(vec2 x){
  return fract(sin(dot(x,vec2(12.9898, 78.233))) * 43758.5453);
}

float random(vec3 x){
  return fract(sin(dot(x,vec3(12.9898, 78.233, 39.425))) * 43758.5453);
}

mat2 rotate(float r) {
  float c = cos(r);
  float s = sin(r);
  return mat2(c, s, -s, c);
}

float sdRect(vec2 p, vec2 r) {
  p = abs(p) - r;
  return length(max(p, 0.0)) + min(max(p.x, p.y), 0.0);
}

float sdSegment(vec2 p, vec2 s) {
  p = abs(p);
  float d1 = sdRect(p, s);
  float d2 = sdRect((p - vec2(s.x, 0.0)) * rotate(0.25 * PI), vec2(s.y / sqrt(2.0)));
  return min(d1, d2);
}

float sdNumber(vec2 p, int num) {
  vec2 size = vec2(1.0, 0.3);
  vec2 margin = vec2(0.5, 0.5);
  float d = 1e6;
  if (num == 0 || num == 2 || num == 3 || num == 5 || num == 6 || num == 7 || num == 8 || num == 9) { // top
    d = min(d, sdSegment(p - vec2(0.0, 2.0 * (size.x + margin.x)), size));
  }
  if (num == 3 || num == 2 || num == 3 || num == 4 || num == 5 || num == 6 || num == 8 || num == 9) { // center
    d = min(d, sdSegment(p, size));
  }
  if (num == 0 || num == 2 || num == 3 || num == 5 || num == 6 || num == 8 || num == 9) { // bottom
    d = min(d, sdSegment(p - vec2(0.0, -2.0 * (size.x + margin.x)), size)); // bottom
  }
  if (num == 0 || num == 1 || num == 2 || num == 3 || num == 4 || num == 7 || num == 8 || num == 9) { // top right
    d = min(d, sdSegment((p - vec2(size.x + margin.x, size.x + margin.y)) * rotate(0.5 * PI), size));
  }
  if (num == 0 || num == 4 || num == 5 || num == 6 || num == 8 || num == 9) { // top left
    d = min(d, sdSegment((p - vec2(-(size.x + margin.x), size.x + margin.y)) * rotate(0.5 * PI), size));
  }
  if (num == 0 || num == 1 || num == 3 || num == 4 || num == 5 || num == 6 || num == 7 || num == 8 || num == 9) { // bottom right
    d = min(d, sdSegment((p - vec2(size.x + margin.x, -(size.x + margin.y))) * rotate(0.5 * PI), size));
  }
  if (num == 0 || num == 2 || num == 6 || num == 8) {// bottom left
  d = min(d, sdSegment((p - vec2(-(size.x + margin.x), -(size.x + margin.y))) * rotate(0.5 * PI), size)); 
  }
  return d;
}

void main(void) {
  vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

  vec2 p = 120.0 * st;
  vec2 grid = vec2(3.0, 4.5);
  vec2 q = mod(p, 2.0 * grid) - grid;
  vec2 qi = floor(p / (2.0 * grid));

  float t = 5.0 * (time + random(qi));
  float ti = floor(t);

  float d = sdNumber(q, int(10.0 * random(vec3(qi, ti))));

  float s = smoothstep(-0.02, 0.1, d);

  vec3 c = mix(vec3(1.0, 0.35, 0.05), vec3(0.0), s);

  glFragColor = vec4(c, 1.0);
}
