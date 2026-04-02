#version 420

// original https://neort.io/art/bqasrnc3p9f6qoqnn7k0

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float random(vec3 x){
  return fract(sin(dot(x,vec3(12.9898, 78.233, 39.425))) * 43758.5453);
}

float valuenoise(vec3 x) {
  vec3 i = floor(x);
  vec3 f = fract(x);

  vec3 u = f * f * (3.0 - 2.0 * f);

  return mix(
    mix(
      mix(random(i + vec3(0.0, 0.0, 0.0)), random(i + vec3(1.0, 0.0, 0.0)), u.x),
      mix(random(i + vec3(0.0, 1.0, 0.0)), random(i + vec3(1.0, 1.0, 0.0)), u.x),
      u.y
    ),
    mix(
      mix(random(i + vec3(0.0, 0.0, 1.0)), random(i + vec3(1.0, 0.0, 1.0)), u.x),
      mix(random(i + vec3(0.0, 1.0, 1.0)), random(i + vec3(1.0, 1.0, 1.0)), u.x),
      u.y
    ),
    u.z);
}

float fbm(vec3 x) {
  float n = 0.0;
  float a = 0.5;
  for (int i = 0; i < 5; i++) {
    n += a * valuenoise(x);
    a *= 0.5;
    x *= 2.0;
  }
  return n;
}

void main(void) {
  vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

  vec2 p = 8.0 * st;
  float l = length(p);

  float v = smoothstep(0.9, 1.0, l);
  vec2 np = normalize(st);
  float s = mix(0.01, 0.8, fbm(vec3(20.0 * np, 0.8 * time)));
  v *= min(1.0, exp(-s * (l - 1.0)));

  glFragColor = vec4(vec3(v), 1.0);
}
