#version 420

// original https://neort.io/art/bpf4mns3p9f4nmb8bttg

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) {
  vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);
  vec2 p = vec2(8.0, 30.0) * st;
  p.x -= 4.0 * time;
  p.y += 4.0 * sin(0.4 * p.x + 2.0 * time);
  vec2 pi = floor(p);
  p.x += mod(pi.y, 2.0) < 1.0 ? 0.0 : 0.5;
  vec2 pf = abs(2.0 * fract(p) - 1.0);
  float c = (1.0 - smoothstep(0.4, 1.0, pf.x)) * (1.0 - smoothstep(0.0, 0.9, pf.y));
  c = smoothstep(0.5, 0.8, c);
  glFragColor = vec4(vec3(c), 1.0);
}
