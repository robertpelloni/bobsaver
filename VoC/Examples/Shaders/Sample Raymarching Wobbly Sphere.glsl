#version 420

// original https://www.shadertoy.com/view/wtXBRS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_DIST 100.0
#define MAX_STEPS 255
#define EPSILON 0.0001

float sphereSDF(vec3 point) {
  return length(point) - 1.0 + 0.1*sin(30.0*point.y - time*5.0);
}

vec3 sphereNormal(vec3 point) {
  vec2 e = vec2(EPSILON, 0.0);

  return normalize(
      sphereSDF(point) - vec3(
        sphereSDF(point + e.xyy),
        sphereSDF(point + e.yxy),
        sphereSDF(point + e.yyx)
      )
  );
}

float trace(vec3 ro, vec3 rd) {
  float depth = 0.0;

  for (int i = 0; i < MAX_STEPS; ++i) {
    float dist = sphereSDF(ro + depth * rd);

    if (dist < EPSILON) return depth;

    depth += dist;

    if (depth > MAX_DIST) return MAX_DIST;
  }

  return MAX_DIST;
}

void main(void) {
  vec2 xy = gl_FragCoord.xy - resolution.xy / 2.0;
  vec3 ro = vec3(0.0, 0.0, 5.0);
  vec3 rd = normalize(vec3(xy, -resolution.y / tan(radians(50.0 + 10.0*sin(time)) / 2.0)));

  vec3 light = vec3(sin(time), cos(time), cos(time));

  float dist = trace(ro, rd);

  if (dist < MAX_DIST) {
    vec3 normal = sphereNormal(ro + dist * rd);

    glFragColor = vec4(vec3(dot(normal, light)), 1.0);

    return;
  }

  glFragColor = vec4(vec3(0.0), 1.0);
}
