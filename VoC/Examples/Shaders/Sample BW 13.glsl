#version 420

// original https://neort.io/art/bpbhg3c3p9f4nmb8b10g

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) {
  vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

  vec2 p = st * 0.2;
  float v = 1.0;
  for (int i = 0; i < 6; i++) {
    p = 2.0 * p + vec2(0.13, -0.17)* time;
    vec2 pf = abs(2.0 * fract(p) - 1.0);
    v *= smoothstep(0.02, 0.04, pf.x) * smoothstep(0.02, 0.04, pf.y);
  }
  vec3 c = vec3(v);

  glFragColor = vec4(c, 1.0);
}
