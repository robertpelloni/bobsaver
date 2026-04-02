#version 420

// original https://www.shadertoy.com/view/tlsyzr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float pi = 3.14159;
// palette.
const vec3 red = vec3(0.95, 0.3, 0.35);
const vec3 green = vec3(0.3, 0.9, 0.4);
const vec3 blue = vec3(0.2, 0.25, 0.98);
const vec3 gold = vec3(0.85, 0.67, 0.14);
const vec3 white = vec3(1.0);
// diaShape tiling.
vec3 diaTiling(in vec2 p, float scale, vec3 tileColor){
  p.x += time * 0.1;
  p *= scale;
  vec2 q = (mat2(1.0, 1.0, -sqrt(3.0), sqrt(3.0)) / 3.0) * p;
  vec2 i = floor(q);
  vec2 f = fract(q);
  vec2 e1 = vec2(sqrt(3.0) * 0.5, -0.5);
  vec2 e2 = vec2(sqrt(3.0) * 0.5, 0.5);
  vec3 col = tileColor;
  if(mod(i.x * i.y, 2.0) == 0.0){ col = white; }
  return col;
}
void main(void) {
  vec2 p = (gl_FragCoord.xy * 0.5 - resolution.xy) / min(resolution.x, resolution.y);
  float scale = 32.0;
  vec3 col_1 = diaTiling(p, scale, red);
  float t = pi * 2.0 / 3.0;
  vec3 col_2 = diaTiling((p - vec2(0.0, sqrt(3.0) / scale)) * mat2(cos(t), sin(t), -sin(t), cos(t)), scale, blue);
  vec3 col_3 = diaTiling((p - vec2(-1.5, 0.5 * sqrt(3.0)) / scale) * mat2(cos(t), -sin(t), sin(t), cos(t)), scale, green);
  vec3 col = min(col_1, min(col_2, col_3));
    if(col == white){ col = mix(gold, white, (p.y + 1.0) * 0.5); }
  glFragColor = vec4(col, 1.0);
}
