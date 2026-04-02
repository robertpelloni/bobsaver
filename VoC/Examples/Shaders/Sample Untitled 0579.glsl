#version 420

// original https://neort.io/art/btvbp3c3p9f7gige5fvg

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.1415926;
const float TAU = PI * 2.0;

mat2 rot(float d) {
  return mat2(cos(d), sin(d), -sin(d), cos(d));
}

vec2 pmod(vec2 p, float n) {
  float np = TAU/n;
  float r = atan(p.y, p.x)-0.5*np;
  r = mod(r, np)-0.5*np;
  return length(p)*vec2(cos(r),sin(r));
}

void main() {
  vec2 uv = gl_FragCoord.xy / resolution.xy;
  vec2 uv2 = uv;
  uv = (uv - 0.5) * 2.0;
  uv.y *= resolution.y / resolution.x;
  vec2 p = uv;

  for(int i=0; i<4; i++) {
    p = pmod(p, 10.0);
    p.x -= 0.4;
    p *= rot(time*0.3);
  }

  float l = length(p);

  float wave = sin((atan(p.y, p.x) + PI) / TAU * PI * 40.0);

  float r = length(p * 20.0) - time * 3.0 + l + wave;
  float g = length(p * 22.0) - time * 4.0 + l + wave;
  float b = length(p * 24.0) - time * 5.0 + l + wave;

  vec3 col = vec3(0.1 / abs(sin(r)), 0.1 / abs(sin(g)), 0.1 / abs(sin(b)));

  vec3 destColor = vec3(col);

  glFragColor = vec4(destColor, 1.0);
}
