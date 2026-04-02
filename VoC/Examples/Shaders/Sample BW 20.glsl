#version 420

// original https://neort.io/art/bpge0k43p9f4nmb8c7o0

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359

void main(void) {
  vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

  float c = 0.0;
  for (float i = 0.0; i <= 7.0; i += 1.0) {
    float t = 0.1 * time - i / 5.0;
    float tf = fract(t);

    float s = mix(0.01, 8.0, tf);
    vec2 o = vec2(-1.5 * sin(PI * tf), 4.0 * sin(PI * tf));
    vec2 p = s * st - o;
    vec2 pf = abs(2.0 * fract(p) - 1.0);
    c = max(c,  pow(1.0 - tf, 2.0) * (1.0 - smoothstep(0.05, 0.1, pf.x) * smoothstep(0.05, 0.1, pf.y)));
  }

  glFragColor = vec4(vec3(c), 1.0);
}
