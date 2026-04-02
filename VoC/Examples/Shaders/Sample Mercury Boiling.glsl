#version 420

// original https://www.shadertoy.com/view/wl23Rw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141592
#define MAX_STEPS 255
#define MAX_DIST 100.
#define EPSILON 1.

mat2 rotate(float a) {
  return mat2(cos(a), -sin(a), sin(a), cos(a));
}

float smin( float a, float b, float k ) {
  // http://www.iquilezles.org/www/articles/smin/smin.htm
  float h = max( k-abs(a-b), 0.0 )/k;
  return min( a, b ) - h*h*h*k*(1.0/6.0);
}

float sphereSDF (vec3 p, float r) {
  return length(p) - r;
}

float displacement(vec3 p, float n) {
  return sin(p.x * n) * sin(p.y * n) * sin(p.z * n);
}

float sceneSDF (vec3 p) {
  float s1 = sphereSDF(p - vec3(-.8 * sin(time) * .2, .3, -.10 * cos(time) * .5), .5 + sin(cos(dot(p, vec3(p.y)) * 1.2 - time * .3) * 8. + time * .2) * .5 + .5);
  float s2 = sphereSDF(p - vec3(-.8 * sin(time) * .2, .5, -.10 * cos(time) * .5) * sin(length(p * sin(time * .01)) * 15. + cos(time)), 1.);

  return smin(s1 * 1.1, s2 * .8 + displacement(p - cos(atan(p.y, p.z) - time * .01) * .5 + .5, 5.), 1.2);
}

vec3 getNormal (vec3 p) {
  float d = sceneSDF(p);
  vec2 e = vec2(.01, 0.);

  return normalize(d - vec3(
    sceneSDF(p - e.xyy),
    sceneSDF(p - e.yxy),
    sceneSDF(p - e.yyx)));
}

float raymarch (vec3 ro, vec3 rd) {
  float depth = 0.;
  for (int i = 0; i < MAX_STEPS; i++) {
    float dist = sceneSDF(ro + rd * depth);
    if (dist < EPSILON) return depth;
    depth += dist;
    if (depth >= MAX_DIST) return 0.;
  }
  return 0.;
}

float getLight (vec3 lightPos, vec3 p) {
  vec3 light = normalize(lightPos - p);
  vec3 normal = getNormal(p);

  float diff = clamp(dot(normal, light), 0., 1.);

  return diff;
}

vec3 getRayDir (vec2 uv, vec3 rayOrigin, vec3 lookat, float zoom) {
  // https://www.youtube.com/watch?v=PBxuVlp7nuM
  vec3 forward = normalize(lookat - rayOrigin);
  vec3 right = normalize(cross(vec3(0., 1., 0.), forward));
  vec3 up = cross(forward, right);
  vec3 center = rayOrigin + forward * zoom;
  vec3 intersection = center + uv.x * right + uv.y * up;
  return normalize(intersection - rayOrigin);
}

void main(void) {
  vec2 uv = (gl_FragCoord.xy / resolution.xy) * 2.0 - 1.0;
  uv.x *= resolution.x / resolution.y;
   
  // camera
  vec3 ro = vec3(-.3, 1., 8.);
  ro.xz *= rotate(time * .02);
  vec3 rd = getRayDir(uv, ro, vec3(-.3), 2.5);

  vec3 color = vec3(0.);
  float d = raymarch(ro, rd);
  vec3 p = ro + rd * d;

  if (d > 0.) {
    vec3 lightPos1 = vec3(4. * sin(time * .5), 4., 6. * cos(time * .5));
    vec3 lightPos2 = vec3(-6., -3. * sin(time * .5), -1. * cos(time * .5));
    float diff = getLight(lightPos1 * d, p);
    color += diff * vec3(.2, .4, .8);
    color += diff * .5;
    diff = getLight(lightPos2 * d, p);
    color += diff * vec3(.8, .4, .2);
    color += diff * .4;
    color -= d * .002;

  } else {
    color += 1. - length(uv * .6);
    color *= 1. - cos(length(uv * (uv.x - uv.y)) * 20. - time);
    color = mix(color, vec3(0.), cos(length(uv) * 120. + time) * .5 + .5) * vec3(.5);
  }

  glFragColor = vec4(color, 1.);
}
