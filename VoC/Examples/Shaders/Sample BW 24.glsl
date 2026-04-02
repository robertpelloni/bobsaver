#version 420

// original https://neort.io/art/bpl2t3c3p9fbkbq83hdg

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define linearstep(edge0, edge1, x) min(max((x - edge0) / (edge1 - edge0), 0.0), 1.0)

mat2 rotate(float r) {
  float c = cos(r);
  float s = sin(r);
  return mat2(c, s, -s, c);
}

void main(void) {
  vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

  vec2 p = 5.0 * st;
  vec2 pi = floor(p);
  vec2 pf = 2.0 * fract(p) - 1.0;
  pf *= rotate(PI * 0.5);

  float a = (atan(pf.y, pf.x) + PI) / (2.0 * PI);
  float r = length(pf);

  float t = 0.8 * time + 0.02 * pi.x;
  float tf = fract(t);

  float rc = smoothstep(0.6, 0.65, r) * (1.0 - smoothstep(0.7, 0.75, r));

  float ab = 0.025 + 0.95 * pow(linearstep(0.2, 1.0, tf), 2.0);
  float ae = 0.025 + 0.95 * pow(linearstep(0.0, 0.8, tf), 0.5);

  float ac = smoothstep(ab, ab + 0.02, a) * (1.0 - smoothstep(ae - 0.02, ae, a));

  float c = ac * rc;

  glFragColor = vec4(vec3(c), 1.0);
}
