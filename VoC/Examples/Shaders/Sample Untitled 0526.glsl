#version 420

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265
#define EPS 1e-4

struct Ray {
  vec3 pos;
  vec3 dir;
};

float distWorldFunc(vec3 p) {
  return length(vec3(
    mod(p.x - fract(time) * 4., 4.0) - 2.0,
    mod(p.y - fract(time) * 4., 4.0) - 2.0,
    mod(p.z - pow(length(p.xy), 1.2) - fract(time) * 20., 20.0) - 10.0
  )) - (abs(sin(time * 5.)) + 1.);
}

float distFunc(vec3 p) {
  float dWorld = distWorldFunc(p);
  return dWorld;
}

vec3 normalFunc(vec3 p) {
  float d = distFunc(p);
  return normalize(vec3(
    distFunc(p + vec3(EPS, 0., 0.)) - d,
    distFunc(p + vec3(0., EPS, 0.)) - d,
    distFunc(p + vec3(0., 0., EPS)) - d
  ));
}

void main() {
  vec2 pos = (gl_FragCoord.xy * 2. - resolution) / max(resolution.x, resolution.y);

  vec3 camPos = vec3(0., 0., -50.);
  vec3 camTop = normalize(vec3(0., 1., 0.));
  vec3 camDir = normalize(vec3(0., 0., 1.));
  vec3 camSid = normalize(cross(camTop, camDir));
  float targetDepath = 1.;

  Ray ray;
  ray.pos = camPos;
  ray.dir = normalize(pos.x * camSid + pos.y * camTop + camDir * targetDepath);

  float d = 0.;

  float t = 0.;
  for(int i = 0; i < 128; i++) {
    d = distFunc(ray.pos);
    if(d < .0001) {
      break;
    }
    t += d;
    ray.pos = camPos + t * ray.dir;
  }

  vec3 L = normalize(vec3(0., 0., -1.));
  vec3 N = normalFunc(ray.pos);
  vec3 LColor = vec3(0., .8, 1.);
  vec3 I = dot(N, L) * LColor;

  if(d < .0001) {
    glFragColor = vec4(max(I, vec3(0., .1, .15)), 1.);
  } else {
    glFragColor = vec4(vec3(0., .1, .15), 1.);
  }
}
