#version 420

// original https://neort.io/art/bplng1s3p9fbkbq83na0

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

float random(vec2 x){
  return fract(sin(dot(x,vec2(12.9898, 78.233))) * 43758.5453);
}

void main(void) {
  vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

  st *= vec2(0.5, 1.0);
  st *= rotate(0.25 * PI);

  vec2 p = 10.0 * st;
  vec2 pi = floor(p);
  vec2 pf = abs(2.0 * fract(p) - 1.0);

  vec2 e0 = 1.0 - smoothstep(0.65, 0.75, pf);
  vec2 e1 = 1.0 - smoothstep(0.85, 0.95, pf);

  float c = random(pi + vec2(floor(8.0 * time), 0.0)) < 0.5
    ? e1.x * e1.y - e0.x * e0.y : e1.x * e1.y;

  glFragColor = vec4(vec3(1.0 - c), 1.0);
}
