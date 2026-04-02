#version 420

// original https://neort.io/art/bp6iles3p9f2ibmm1bt0

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float random(float x) {
  return fract(sin(x * 12.9898) * 43758.5453);
}

float srandom(float x) {
  return 2.0 * random(x) - 1.0;
}

void main(void) {
  vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

  st.y *= 15.0;
  st.x *= 10.0 + 5.0 * srandom(floor(st.y) + 45.41);
  float offset = 10.0 * random(floor(st.y) + 39.19) - 5.0 * srandom(floor(st.y) + 21.34) * time;
  float s = smoothstep(0.9, 1.0, abs(2.0 * fract(st.x + offset)- 1.0));
  float t = smoothstep(0.9, 1.0, abs(2.0 * fract(st.y) - 1.0));
  vec3 c = vec3(1.0 - (1.0 - s) * (1.0 - t));

  glFragColor = vec4(c, 1.0);
}
