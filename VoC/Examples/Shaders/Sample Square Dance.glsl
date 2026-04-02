#version 420

// original https://www.shadertoy.com/view/3lscWr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.14159

// palette.
const vec3 red = vec3(0.95, 0.3, 0.35);
const vec3 green = vec3(0.3, 0.9, 0.4);
const vec3 blue = vec3(0.2, 0.25, 0.98);
const vec3 orange = vec3(0.9, 0.45, 0.1);
// pattern data.
const float SCALE = 6.0;
// hsb to rgb.
vec3 getRGB(float r, float g, float b){
    vec3 c = vec3(r, g, b);
    vec3 rgb = clamp(abs(mod(c.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
    rgb = rgb * rgb * (3.0 - 2.0 * rgb);
    return c.z * mix(vec3(1.0), rgb, c.y);
}
// backgroundColor.
void setBackgroundColor(in vec2 p, inout vec3 col){
  col = vec3(max(abs(p.x), abs(p.y))) / 1.4;
}
// normal pattern.
void setNormalPattern(in vec2 p, inout vec3 col, float time, vec3 ptnColor){
  // easing.
  float x = fract(time * 2.0);
  time = floor(time * 2.0) * 0.5 + 0.5 * x * x * (3.0 - 2.0 * x);
  p *= SCALE;
  p -= time * vec2(1.0, -1.0);
  vec2 f = fract(p);
  vec2 i = floor(p);
  bool validation1 = mod(i.x, 2.0) == 0.0 && mod(i.y, 2.0) == 0.0;
  bool validation2 = mod(i.x + i.y, 4.0) == 0.0;
  if(!(validation1 && validation2)){ return; }
  float value = 1.0 - 2.0 * max(abs(f.x - 0.5), abs(f.y - 0.5));
  col = mix(ptnColor, vec3(1.0), value);
}
// rotational pattern.
void setRotatePattern(in vec2 p, inout vec3 col, float time, vec3 ptnColor){
  p *= SCALE;
  vec2 q = 0.5 * vec2(p.x - p.y, p.x + p.y);
  vec2 f = fract(q);
  vec2 i = floor(q);
  if(mod(i.x, 2.0) == 1.0 || mod(i.y, 2.0) == 1.0){ return; }
  vec2 c = vec2(0.5);
  // easing.
  float prg = time / 0.5;
  prg = prg * prg * (3.0 - 2.0 * prg);
  // change rotation direction.
  float sgn = (mod(time, 3.0) < 1.5 ? 1.0 : -1.0);
  float multiple = floor(mod(time, 4.0));
  float deg = 0.25 + (0.5 + 0.5 * multiple) * prg * sgn;
  vec2 u1 = vec2(cos(pi * deg), sin(pi * deg));
  vec2 u2 = vec2(cos(pi * (deg - 0.5)), sin(pi * (deg - 0.5)));
  float value = 1.0 - 2.0 * sqrt(2.0) * max(abs(dot(f - c, u1)), abs(dot(f - c, u2)));
  if(value < 0.0){ return; }
  col = mix(ptnColor, vec3(1.0), value);
}
// normal pattern.
void normalPattern(in vec2 p, inout vec3 col, float time){
  setNormalPattern(p, col, time, red);
  setNormalPattern(p.yx * vec2(-1.0, 1.0), col, time, blue);
  setNormalPattern(-p, col, time, green);
  setNormalPattern(p.yx * vec2(1.0, -1.0), col, time, orange);
}
// rotational pattern.
void rotatePattern(in vec2 p, inout vec3 col, float time){
  setRotatePattern(p, col, time, red);
  setRotatePattern(p.yx * vec2(-1.0, 1.0), col, time, blue);
  setRotatePattern(-p, col, time, green);
  setRotatePattern(p.yx * vec2(1.0, -1.0), col, time, orange);
  return;
}
// mainCode.
void main(void) {
  vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
  vec3 col;
  setBackgroundColor(p, col);
  float time = mod(time, 3.0);
  float id = floor(time * 2.0);
  if(id == 0.0){ normalPattern(p, col, time); }
  if(id == 1.0){ rotatePattern(p, col, mod(time, 0.5)); }
  if(id == 2.0){ normalPattern(p, col, time - 0.5); }
  if(id == 3.0){ normalPattern(p, col, time - 0.5); }
  if(id == 4.0){ rotatePattern(p.yx * vec2(1.0, -1.0), col, mod(time, 0.5)); }
  if(id == 5.0){ normalPattern(p, col, time - 1.0); }
  glFragColor = vec4(col, 1.0);
}
