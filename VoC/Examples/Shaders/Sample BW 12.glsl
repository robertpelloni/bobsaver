#version 420

// original https://neort.io/art/bpb8imk3p9f4nmb8av6g

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float random(float x){
  return fract(sin(x * 12.9898) * 43758.5453);
}

float random(vec2 x){
  return fract(sin(dot(x,vec2(12.9898, 78.233))) * 43758.5453);
}

mat2 rotate(float r) {
  float c = cos(r);
  float s = sin(r);
  return mat2(c, s, -s, c);
}

void main(void) {
  vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

  vec2 p = st;
  p *= rotate(0.8);

  p *= vec2(15.0, 30.0);
  p.x -= 40.0 * time;

  vec2 pi;
  pi.x = floor(p.x);
  p.y += 20.0 * random(pi.x);
  pi.y = floor(p.y);
  vec2 pf = fract(p);

  float t = (1.0 - smoothstep(0.3, 0.5, abs(2.0 * pf.x - 1.0)))
    * (1.0 - smoothstep(0.3, 0.4, abs(2.0 * pf.y- 1.0)));

  t *= random(pi) < 0.05 ? 1.0 : 0.0;

  vec2 q = st;
  q *= 10.0;
  vec2 qf = abs(2.0 * fract(q) - 1.0);

  t += 0.1 * (1.0 - smoothstep(0.04, 0.05, qf.x) * smoothstep(0.04, 0.05, qf.y));

  vec3 c = vec3(t);

  glFragColor = vec4(c, 1.0);
}
