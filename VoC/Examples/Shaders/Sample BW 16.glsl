#version 420

// original https://neort.io/art/bpdiqpk3p9f4nmb8bgm0

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float random(vec3 x){
  return fract(sin(dot(x,vec3(12.9898, 78.233, 31.84))) * 43758.5453);
}

float smin(float a, float b, float k) {
  return -log2(exp2(-k * a) + exp2(-k * b)) / k;
}

void main(void) {
  vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

  vec2 p = 5.0 * st;
  vec2 pi = floor(p);
  vec2 pf = 2.0 * fract(p) - 1.0;
  float d = 1e6;
  for (float xi = -1.0; xi <= 1.0; xi += 1.0) {
    for (float yi = -1.0; yi <= 1.0; yi += 1.0) {
      vec2 offset = vec2(xi, yi);
      vec2 qi = pi + offset;
      float t = time + (0.5 * sin(0.15 * (-qi.x - qi.y)) + 0.5);
      float ti = floor(t);
      float tf = fract(t);
      float r = 0.1 + 0.95 * mix(random(vec3(qi, ti)),random(vec3(qi, ti + 1.0)) , smoothstep(0.7, 1.0, tf));
      d = smin(d, length(pf - 2.0 * offset) - r, 4.0);
    }
  }

  float c = smoothstep(-0.01, 0.01, d);
  glFragColor = vec4(vec3(c), 1.0);
}
