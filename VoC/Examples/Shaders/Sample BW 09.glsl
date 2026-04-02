#version 420

// original https://neort.io/art/bp96odc3p9fcqlgn9ij0

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float random(vec2 x) {
  return fract(sin(dot(x,vec2(12.9898, 78.233))) * 43758.5453);
}

float random(vec3 x) {
  return fract(sin(dot(x,vec3(12.9898, 78.233, 39.521))) * 43758.5453);
}

void main(void) {
  vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

  st *= 15.0;

  vec2 pi = floor(st);
  vec2 pf = fract(st);

  float t = 2.0 * time + random(pi);
  float ti = floor(t);
  float tf = fract(t);

  float l = length(2.0 * pf - 1.0);
  float d = smoothstep(0.45, 0.8, l);
  bool con = random(vec3(pi, ti)) < 0.5;
  bool non = random(vec3(pi, ti + 1.0)) < 0.5;
  float v = con ? d : 1.0;
  if (con && !non) {
    v = mix(d, 1.0, smoothstep(0.0, 0.5, tf));
  } else if (!con && non) {
    v = mix(1.0, d, smoothstep(0.0, 0.15, tf));
  }

  vec3 c = vec3(1.0 - v);

  glFragColor = vec4(c, 1.0);
}
