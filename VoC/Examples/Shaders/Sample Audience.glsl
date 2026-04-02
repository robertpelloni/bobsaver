#version 420

// original https://neort.io/art/bq490343p9fefb927m10

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359

mat2 rotate(float r) {
  float c = cos(r);
  float s = sin(r);
  return mat2(c, s, -s, c);
}

void main(void) {
  vec2 st = (2.0 * gl_FragCoord.xy - resolution) / resolution.y;

  st.y += 1.0;
  vec2 p = 5.0 * st;
  float l = length(p);

  float li = floor(l);
  float lf = fract(l);

  vec3 c = mod(li, 2.0) == 1.0 ? vec3(0.3, 0.01, 0.04) : vec3(0.05, 0.03, 0.1);
  c = mix(c, vec3(0.0), smoothstep(0.95, 1.0, abs(2.0 * lf - 1.0)));

  if (li != 0.0) {
    float a = atan(p.y, p.x) + PI;
    float div = 2.0 * PI / floor(9.5 * li);
    float af = mod(a, div) - 0.5 * div;

    vec2 q = (li + lf) * vec2(cos(af), sin(af));
    float m = length(q - vec2((li + 0.5), 0.0));

    c = mix(
      mix(vec3(0.7, 0.5, 0.1), vec3(0.3, 0.2, 0.05), sin(-3.0 * time + 2.0 * li) * 0.5 + 0.5),
      c,
      step(0.2, m)
    );

    c = mix(c, vec3(0.0), smoothstep(0.18, 0.2, m) * (1.0 - smoothstep(0.2, 0.22, m)));
  }

  glFragColor = vec4(c, 1.0);
}
