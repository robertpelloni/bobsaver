#version 420

// original https://www.shadertoy.com/view/fsBGzW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 rotate(vec2 v, float a) { return mat2(cos(a), -sin(a), sin(a), cos(a))*v; }
float remap(float v, float a, float b, float c, float d) { return (v - a) / (b - a) * (d - c) + c; }
float divMod(float a, float m) { return remap(mod(a, m), 0.0, m, -1.0, 1.0); }

void main(void)
{
  vec2 uv = gl_FragCoord.xy / resolution.xy;
  uv -= 0.5;
  float f = 0.5*sin(time);
  uv.x = divMod(uv.x, exp(f));
  uv.y = divMod(uv.y, 2.);
  
  for (int i = 0; i < 8; ++i){
    uv = abs(uv) - 0.09;
    uv = rotate(uv, 0.5*time);
    uv = rotate(uv, abs(uv.y)- 0.2);
    uv = rotate(uv, abs(uv.x) + 0.1);
  }
  for (int i = 0; i < 8; ++i) {
    uv = rotate(uv, exp(abs(uv.y))- 0.2);
    uv = rotate(uv, abs(uv.x) + 0.1);
  }
  float r = 0.2*uv.x/uv.y;
  float b = 0.1 / sqrt(uv.x+uv.y);
  glFragColor = vec4(r,0., b, 1.);
}
