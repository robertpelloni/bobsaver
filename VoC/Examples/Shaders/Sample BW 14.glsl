#version 420

// original https://neort.io/art/bpbta8c3p9f4nmb8b48g

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float random(vec2 x){
  return fract(sin(dot(x,vec2(12.9898, 78.233))) * 43758.5453);
}

#define ITERATIONS 6.0

void main(void) {
  vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

  vec2 p = 0.1 * st;

  float t = 0.0;
  for (float i = 0.0; i <= ITERATIONS; i += 1.0) {
    p *= 2.0;
    p.y -= 0.02 * i * time;
    vec2 pi = floor(p);
    if (random(pi) < 0.15) {
      vec2 offset = 0.5 * sin(vec2(random(pi + vec2(12.31, 9.43)), random(pi + vec2(4.21, 5.62))) * time);
      t += 1.0 - smoothstep(0.4 - 0.4 * abs(i - 0.5 * ITERATIONS), 0.5, length(2.0 * fract(p) - 1.0 - offset));
    }
  }

  vec3 c = vec3(t);

  glFragColor = vec4(c, 1.0);
}
