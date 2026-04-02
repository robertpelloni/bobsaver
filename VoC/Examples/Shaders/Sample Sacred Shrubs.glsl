#version 420

// original https://www.shadertoy.com/view/tdB3zV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 cPos = vec3(0.0, 0.0, -10.0);
const vec3 cDir = vec3(0.0, 0.0, 1.0);
const vec3 cUp = vec3(0.0, 1.0, 0.0);
const float depth = 1.0;
const vec3 lPos = vec3(10.0, 10.0, -10.0);
const float ambientColor = 0.5;

vec3 rotate(vec3 p, float angle, vec3 axis) {
  vec3 a = normalize(axis);
  float s = sin(angle);
  float c = cos(angle);
  float r = 1.0 - c;
  mat3 m =
      mat3(a.x * a.x * r + c, a.y * a.x * r + a.z * s, a.z * a.x * r - a.y * s,
           a.x * a.y * r - a.z * s, a.y * a.y * r + c, a.z * a.y * r + a.x * s,
           a.x * a.z * r + a.y * s, a.y * a.z * r - a.x * s, a.z * a.z * r + c);
  return m * p;
}

float fractalDistFunc(vec3 p) {
  p = rotate(p, 0.3 - 0.015 * time, vec3(0.0, 0.0, 1.0));
  float r = 1.9;
  p.y = mod(p.y, 6.0) - 3.0;
  p.xz = mod(p.xz, 3.0) - 1.5;
  for (float i = 0.0; i < 8.0; i++) {
    p = abs(p) - vec3(1.1 * mix(2.0, 0.6,
                                smoothstep(abs(mod(time * 10.0, 100.0) - 50.0),
                                           0.0, 1.0)),
                      0.5, 2.7);
    float s = clamp(length(p), 0.17, 0.91);
    p = p / s;
    p -= vec3(0.5, 1.8, 0.2) * exp(-i);
    r /= s;
  }
  return length(p / r);
}

float distFunc(vec3 p) { return fractalDistFunc(p); }

vec3 getNormal(vec3 p) {
  float d = 0.001;
  return normalize(
      vec3(distFunc(p + vec3(d, 0.0, 0.0)) - distFunc(p + vec3(-d, 0.0, 0.0)),
           distFunc(p + vec3(0.0, d, 0.0)) - distFunc(p + vec3(0.0, -d, 0.0)),
           distFunc(p + vec3(0.0, 0.0, d)) - distFunc(p + vec3(0.0, 0.0, -d))));
}

vec3 rayMarching(vec3 color, vec2 p) {
  cPos.z += time / 3.0;
  vec3 cSide = cross(cDir, cUp);
  vec3 ray = normalize(cSide * p.x + cUp * p.y + cDir * depth);
  vec3 rPos = cPos;
  float rLen = 0.0;
  for (float i = 0.0; i < 100.0; i++) {
    float distance = distFunc(rPos);
    if (abs(distance) < 0.01) {
      vec3 normal = getNormal(rPos);
      vec3 halfLE = normalize(lPos + rPos);
      float specular = pow(clamp(dot(normal, halfLE), 0.0, 0.1), 20.0);
      float diffuse = clamp(dot(normal, lPos), 0.0, 1.0) + 0.2;
      color = (vec3(0.8 * sin(rPos.z + time / 50.0 - 5.0),
                    0.2 * cos(rPos.y + time / 70.0 - 2.0),
                    0.3 * cos(rPos.z * time / 80.0)) *
                   diffuse +
               specular + ambientColor);
      break;
    }
    rLen += distance * 1.2;
    rPos = cPos + rLen * ray;
  }
  return color;
}

void main(void) {
  vec2 p =
      (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
  vec3 color = rayMarching(vec3(0.8), p);
  glFragColor = vec4(color, 1.0);
}
