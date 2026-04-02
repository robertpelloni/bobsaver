#version 420

// original https://neort.io/art/bp9qo8k3p9fcqlgn9md0

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rotate(float r) {
  float c = cos(r);
  float s = sin(r);
  return mat2(c, s, -s, c);
}

void main(void) {
  vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

  vec2 p = 10.0 * st;
  vec2 pi = floor(p);
  vec2 pf = 2.0 * fract(p) - 1.0;
  float pt = smoothstep(0.5, 0.9, length(pf));

  vec2 q = pi + 0.5;
  q *= rotate(0.3 * time);
  float qx = 0.15 * q.x + 3.0 * time;
  float qxf = fract(qx);
  float qt = 0.0;
  qt = mix(qt, 1.0, smoothstep(0.0, 0.05, qxf));
  qt = mix(qt, 0.0, smoothstep(0.2, 0.8, qxf));

  vec3 c = vec3(qt * (1.0 - pt));

  glFragColor = vec4(c, 1.0);
}
