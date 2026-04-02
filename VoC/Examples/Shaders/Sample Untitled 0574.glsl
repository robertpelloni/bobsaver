#version 420

// original https://www.shadertoy.com/view/wlXfWS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// =========
// CONSTANTS
// =========

#define QP 0.785398163397448
#define TRP 1.047197551196598
#define HP 1.570796326794897
#define P 3.141592653589793
#define TP 6.283185307179586

#define t time
#define ht 0.5 * t
#define tt 0.1 * t

#define EPS 0.001
#define STEPS 64.0
#define DIST 0.01

#define S(a, b, t) smoothstep(a, b, t)

// ========
// UTILS FN
// ========

/* map a value `n` from a range `start1` -> `stop1` to a range `start2` -> `stop2` */
float map(float n, float start1, float stop1, float start2, float stop2) {
  return (n - start1) / (stop1 - start1) * (stop2 - start2) + start2;
}

/* map a value `n` from the range -1.0 -> 1.0 to a range `start2` -> `stop2`
  to be used with cos/sin
  e.g.: `map01(sin(x), 0.0, 1.0)` */
float map01(float n, float start2, float stop2) {
  return (0.5 * n + 0.5) * (stop2 - start2) + start2;
}

// classical 2d rotation
vec2 rotate2d(vec2 uv, float a) {
  return mat2(cos(a), -sin(a), sin(a), cos(a)) * uv;
}

// =====
// SCENE
// =====

/* SDF of a torus from Inigo Quilez
  https://iquilezles.org/www/articles/distfunctions/distfunctions.htm
*/
float torusSDF(vec3 p, vec2 t) {
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

/* scene definition
  mainly defining a torus and deform radius and thickness of it */
float sceneSDF(vec3 p) {
  vec3 _p = p; // save value of `p` before rotating it
  
  // some rotations
  p.xy = rotate2d(p.xy, t);
  float angle = P * S(0.25, 0.75, abs(2.0 * fract(t / P) - 1.0));
  p.yz = rotate2d(p.yz, angle - QP);
  
  // combine cos/sin and `p` to deform the radius
  float r = map01(sin(t
    + 2.0 * (_p.x + _p.z)
    + HP * cos(-t + p.y)
    ), 1.25, 1.5); // radius
  
  // switch between `p.x` and `p.y` to deform thickness
  float mixer = S(0.125, 0.875, abs(2.0 * fract(t / TP) - 1.0));
  // combine cos/sin and `p` to deform the thickness
  float t = map01(cos(-t
    + 2.5 * mix(_p.x, _p.y, mixer)
    + P * sin(-t
      + 2.0 * _p.z
      + TP * sin(t + 0.25 * (_p.x + _p.y + _p.z))
    )), 0.55, 0.65); // thickness
  
  float torus = torusSDF(p, vec2(r, t));
  
  return torus;
}

// ======
// RENDER
// ======

/* compute normales by an estimation of them, offseting the scene computation
  more details reading here:
  http://jamie-wong.com/2016/07/15/ray-marching-signed-distance-functions/#surface-normals-and-lighting */
vec3 computeNormal(vec3 p) {
  float center = sceneSDF(p);
  vec3 offset = vec3(0.0, EPS, 0.0);

  return normalize(vec3(
    center - sceneSDF(p + offset.yxx),
    center - sceneSDF(p + offset.xyx),
    center - sceneSDF(p + offset.xxy)
  ));
}

// =====
// MAIN
// =====

void main(void) {
  vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;

  vec3 color = vec3(0.07, 0.05, 0.08);

  vec3 rd = normalize((vec3(uv, 1.0)));
  vec3 ro = vec3(0.0, 0.0, -5.0);

  // raymarching loop
  float f = 10.0 / STEPS;
  for (float i = 0.0; i < STEPS; i++) {
    vec3 pos = ro + f * rd;
    float scene = sceneSDF(pos);
    if (scene < DIST) {
      // use normales as color and switch the channels, instead of classical `.rgb` use `.brg` for a fresher render
      color = 0.5 * computeNormal(pos).brg + 0.5;
      break;
    }
    f += scene;
  }

  glFragColor = vec4(color, 1.0);
}
