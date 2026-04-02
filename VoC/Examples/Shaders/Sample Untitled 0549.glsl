#version 420

// original https://neort.io/art/bq65nqk3p9f6qoqnlir0

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define saturate(x) max(min(x, 1.0), 0.0)

float random(float x){
  return fract(sin(x * 12.9898) * 43758.5453);
}

float srandom(float x) {
  return 2.0 * random(x) - 1.0;
}

float map(vec3 p) {
  float s = 1.0;
  for (float i = 1.0; i <= 5.0; i += 1.0) { 
    p.x += s * 0.2 * sin(4.0 / s * p.y + 10.0 * srandom(i + 0.19) * time);
    p.y += s * 0.2 * sin(4.0 / s * p.x + 10.0 * srandom(i + 0.32) * time);
    s *= 0.5;
  }
  return length(p) - 3.0;
}

vec3 calcNormal(vec3 p) {
  float d = 0.005;
  return normalize(vec3(
    map(p + vec3(d, 0.0, 0.0)) - map(p - vec3(d, 0.0, 0.0)),
    map(p + vec3(0.0, d, 0.0)) - map(p - vec3(0.0, d, 0.0)),
    map(p + vec3(0.0, 0.0, d)) - map(p - vec3(0.0, 0.0, d))
  ));
}

vec3 raymarch(vec3 ro, vec3 rd) {
  vec3 p = ro;
  for (int i = 0; i < 128; i++) {
    float d = map(p);
    p += d * rd;
    if (d < 0.001) {
      vec3 n = calcNormal(p);
      float dotNV = saturate(dot(n, -rd));
      return vec3(mix(0.0, 0.9, smoothstep(0.3, 1.0, 1.0 - dotNV)));
    }
  }
  return vec3(1.0);
}

void main(void) {
  vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

  vec3 ro = vec3(0.0, 0.0, 6.0);
  vec3 ta = vec3(0.0);
  vec3 z = normalize(ta - ro);
  vec3 up = vec3(0.0, 1.0, 0.0);
  vec3 x = normalize(cross(z, up));
  vec3 y = normalize(cross(x, z));
  vec3 rd = normalize(x * st.x + y * st.y + z * 1.5);

  vec3 c = raymarch(ro, rd);

  glFragColor = vec4(c, 1.0);
}
