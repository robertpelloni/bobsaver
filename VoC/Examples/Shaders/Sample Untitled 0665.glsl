#version 420

// original https://www.shadertoy.com/view/ft3SRN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Reference info
// fractal pyramid - https://www.shadertoy.com/view/tsXBzS

vec3 palette(float d) {
  return mix(vec3(0.2, 0.7, 0.9), vec3(1., 0., 1.), d);
}

vec2 rotate(vec2 p, float a) {
  float c = cos(a);
  float s = sin(a);
  return p * mat2(c, s, -s, c);
}

float map(vec3 p) {
  for(int i = 0; i < 14; ++i) {
    float t = time * 0.2;
    p.xz = rotate(p.xz, t);
    p.xy = rotate(p.xy, t * 1.89);
    p.xz = abs(p.xz);
    p.xz -= .5;
  }
  return dot(sign(p), p) / 5.;
}

vec4 rm(vec3 ro, vec3 rd) { // ray marching
  float t = 0.;
  vec3 col = vec3(0.);
  float d;
  for(float i = 0.; i < 30.; i++) {
    vec3 p = ro + rd * t;
    d = map(p) * .5;
    col += palette(length(p) * .1) / (400. * (d));
    t += d;
  }
  return vec4(col, 1. / (d * 100.));
}

void main(void) {
  vec2 uv = gl_FragCoord.xy / resolution.xy; // Normalized coordinates
  uv -= 0.5; // -1 to 1
  uv.x *= resolution.x / resolution.y; // aspect ratio

  uv *= 10.; // -2 to 2

  vec3 ro = vec3(0., 0., 0.); // Ray origin
  vec3 rd = normalize(vec3(uv, 1.)); // Ray direction
  vec4 c = rm(ro, rd); // Color
  glFragColor = vec4(c.xyz, 1.);
}
