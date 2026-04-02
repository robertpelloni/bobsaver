#version 420

// original https://neort.io/art/bmq52g43p9f7m1g02ggg

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution; 

out vec4 glFragColor;

#define linearstep(edge0, edge1, x) min(max((x - edge0) / (edge1 - edge0), 0.0), 1.0)

float T;

float quadraticInOut(float t) {
  float p = 2.0 * t * t;
  return t < 0.5 ? p : -p + (4.0 * t) - 1.0;
}

float cubicIn(float t) {
  return t * t * t;
}

float cubicOut(float t) {
  float f = t - 1.0;
  return f * f * f + 1.0;
}

float circularOut(float t) {
  return sqrt((2.0 - t) * t);
}

float circularInOut(float t) {
  return t < 0.5
    ? 0.5 * (1.0 - sqrt(1.0 - 4.0 * t * t))
    : 0.5 * (sqrt((3.0 - 2.0 * t) * (2.0 * t - 1.0)) + 1.0);
}

float random(vec2 x){
    return fract(sin(dot(x,vec2(12.9898, 78.233))) * 43758.5453);
}

mat2 rotate(float r) {
  float c = cos(r);
  float s = sin(r);
  return mat2(c, s, -s, c);
}

float sdSphere(vec3 p, float r) {
  return length(p) - r;
}

float sdBox(vec3 p, vec3 b) {
  p = abs(p) - b;
  return length(max(p, 0.0)) + min(max(p.x, max(p.y, p.z)), 0.0);
}

float getScene(vec3 p) {

  float scale = 0.0;
  scale = mix(scale, 1.0, circularInOut(linearstep(0.0, 0.1, T)));
  scale = mix(scale, 0.1, cubicIn(linearstep(0.3, 0.4, T)));
  scale = mix(scale, 1.0, cubicOut(linearstep(0.4, 0.5, T)));
  scale = mix(scale, 0.0, circularInOut(linearstep(0.8, 0.9, T)));
  if (T > 0.9) {
    return 1e3;
  }
  
  float sd = sdSphere(p, 3.0 * scale);
  float bd = sdBox(p, vec3(2.5) * scale);

  float type = 0.0;
  type = mix(type, 1.0, smoothstep(0.3, 0.5, T));
  return mix(sd, bd, smoothstep(0.3, 0.6, type));
}

float FILL_WIDTH = 0.5;
float getFillScene(vec3 p) {
  vec3 c = (floor(p / FILL_WIDTH) + 0.5) * FILL_WIDTH;
  if (getScene(c) < 0.0) {
    float sd = sdSphere(c - p, 0.1 * FILL_WIDTH);
    float bd = sdBox(c - p, vec3(0.1 * FILL_WIDTH));

    float type = 0.0;
    type = mix(type, 1.0, linearstep(0.35, 0.45, T));
    return mix(sd, bd, linearstep(0.45, 0.55, type));
  } 
  return FILL_WIDTH;
}

float REPEAT_TIME = 8.0;
float map(vec3 p) {
  float rotY = 0.0;
  rotY = mix(rotY, 1.5, linearstep(0.4, 1.0, T));
  p.xy *= rotate(0.3 * step(0.4, T));
  p.xz *= rotate(rotY);
  float d1 = getScene(p);
  float d2 = getFillScene(p);
  float t = 0.0;
  t = mix(t, 1.0, smoothstep(0.28, 0.33, T));
  t = mix(t, 0.0, smoothstep(0.78, 0.83, T));
  return mix(d1, d2, t);
}

vec3 calcNormal(vec3 p) {
  float d = 0.001;
  return normalize(vec3(
    map(p + vec3(d, 0.0, 0.0)) - map(p - vec3(d, 0.0, 0.0)),
    map(p + vec3(0.0, d, 0.0)) - map(p - vec3(0.0, d, 0.0)),
    map(p + vec3(0.0, 0.0, d)) - map(p - vec3(0.0, 0.0, d))
  ));
}

vec3 raymarch(vec3 ro, vec3 rd) {
  vec3 p = ro;
  for (int i = 0; i < 64; i++) {
    float d = 0.5 * map(p);
    p += d * rd;
    if (d < 0.01) {
      vec3 n = calcNormal(p);

      float dotNL = dot(n, vec3(0.5, 1.0, 0.3));
      vec3 c = mix(vec3(0.9, 0.9, 0.2), vec3(0.85, 0.2, 0.5), dotNL * 0.5 + 0.5);
      return c;
    }
  }
  return vec3(0.2, 0.7, 0.9);
}

void main(void) {
  T = mod(time, REPEAT_TIME) / REPEAT_TIME;

  vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

  vec3 ro = vec3(0.0, 0.0, 8.0);
  vec3 ta = vec3(0.0);
  vec3 z = normalize(ta - ro);
  vec3 up = vec3(0.0, 1.0, 0.0);
  vec3 x = normalize(cross(z, up));
  vec3 y = normalize(cross(x, z));
  vec3 rd = normalize(x * st.x + y * st.y + z * 1.5);

  vec3 c = raymarch(ro, rd);

  c *= (1.0 + 0.15 * random(st));

  glFragColor = vec4(c, 1.0);
}
