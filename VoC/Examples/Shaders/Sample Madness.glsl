#version 420

// original https://neort.io/art/bq64ous3p9f6qoqnli50

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define saturate(x) max(min(x, 1.0), 0.0)

float random(vec3 v) { 
  return fract(sin(dot(v, vec3(12.9898, 78.233, 19.8321))) * 43758.5453);
}

vec3 random3(vec3 v) {
  return vec3(random(v), random(v + 1000.0), random(v + 2000.0));
}

float perlinNoise(vec3 v) {
  vec3 i = floor(v);
  vec3 f = fract(v);

  vec3 v000 = f;
  vec3 v100 = f - vec3(1.0, 0.0, 0.0);
  vec3 v010 = f - vec3(0.0, 1.0, 0.0);
  vec3 v110 = f - vec3(1.0, 1.0, 0.0);
  vec3 v001 = f - vec3(0.0, 0.0, 1.0);
  vec3 v101 = f - vec3(1.0, 0.0, 1.0);
  vec3 v011 = f - vec3(0.0, 1.0, 1.0);
  vec3 v111 = f - vec3(1.0, 1.0, 1.0);

  vec3 i000 = i;
  vec3 i100 = i + vec3(1.0, 0.0, 0.0);
  vec3 i010 = i + vec3(0.0, 1.0, 0.0);
  vec3 i110 = i + vec3(1.0, 1.0, 0.0);
  vec3 i001 = i + vec3(0.0, 0.0, 1.0);
  vec3 i101 = i + vec3(1.0, 0.0, 1.0);
  vec3 i011 = i + vec3(0.0, 1.0, 1.0);
  vec3 i111 = i + vec3(1.0, 1.0, 1.0);

  vec3 g000 = normalize(random3(i000) * 2.0 - 1.0);
  vec3 g100 = normalize(random3(i100) * 2.0 - 1.0);
  vec3 g010 = normalize(random3(i010) * 2.0 - 1.0);
  vec3 g110 = normalize(random3(i110) * 2.0 - 1.0);
  vec3 g001 = normalize(random3(i001) * 2.0 - 1.0);
  vec3 g101 = normalize(random3(i101) * 2.0 - 1.0);
  vec3 g011 = normalize(random3(i011) * 2.0 - 1.0);
  vec3 g111 = normalize(random3(i111) * 2.0 - 1.0);

  float d000 = dot(v000, g000);
  float d100 = dot(v100, g100);
  float d010 = dot(v010, g010);
  float d110 = dot(v110, g110);
  float d001 = dot(v001, g001);
  float d101 = dot(v101, g101);
  float d011 = dot(v011, g011);
  float d111 = dot(v111, g111);

    vec3 u = smoothstep(0.0, 1.0, f);
  return mix(
    mix(
      mix(d000, d100, u.x),
      mix(d010, d110, u.x),
      u.y
    ),
    mix(
      mix(d001, d101, u.x),
      mix(d011, d111, u.x),
      u.y
    ),
    u.z
  );
}

void main(void) {
  vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

  st.y *= 1.0 + 0.8 * perlinNoise(vec3(st.x * 10.0, time, time));
  st.x *= 1.0 + 0.8 * perlinNoise(vec3(st.y * 20.0, 0.2 * time, 0.0));

  float n = saturate(perlinNoise(vec3(st * 3.0, 5.0 * time)) * 0.5 + 0.5);
  n = saturate(perlinNoise(vec3(n * 20.0, time * 0.13, time * 0.25)) * 0.5 + 0.5);

  vec3 c = mix(vec3(0.06, 0.92, 0.58), vec3(0.98, 0.08, 0.72), n);

  glFragColor = vec4(c, 1.0);
}
