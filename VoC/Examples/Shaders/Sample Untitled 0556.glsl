#version 420

// original https://www.shadertoy.com/view/WsByzG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* Code by Sixclones

My boilerplate: https://www.shadertoy.com/view/wdsyzH */

#define E 0.000001
#define QP 0.785398163397448
#define TRP 1.047197551196598
#define HP 1.570796326794897
#define P 3.141592653589793
#define TP 6.283185307179586

#define t time
#define ht 0.5 * t
#define tt 0.1 * t

#define S(a, b, t) smoothstep(a, b, t)

float map(float n, float start1, float stop1, float start2, float stop2) {
  return (n - start1) / (stop1 - start1) * (stop2 - start2) + start2;
}

float map01(float n) {
  return 0.5 * n + 0.5;
}

vec2 rotate2d(vec2 uv, float a) {
  return mat2(cos(a), -sin(a), sin(a), cos(a)) * uv;
}

float circleSDF(vec2 uv) {
  return 2.0 * length(uv);
}

float rectSDF(vec2 uv, vec2 s) {
  return 2.0 * max(abs(uv.x / s.x), abs(uv.y / s.y));
}

float fill(float x, float s, float p) {
  p *= 0.1;
  return 1.0 - S(s - p, s + p, x);
}

void main(void) {
  vec2 FragCoord = gl_FragCoord.xy;
  vec4 uv = vec4(FragCoord.xy / resolution.xy,
    (FragCoord.xy - 0.5 * resolution.xy) / resolution.y);
  vec2 m = mouse*resolution.xy.xy / resolution.xy;

  float n = 8.0;
  vec2 gv = fract(n * uv.xy);
  vec2 id = floor(n * uv.xy);

  vec3 color = vec3(0.0);
  vec3 black = vec3(0.129);
  vec3 white = vec3(0.925);
  vec3 pal1 = vec3(0.95, 0.22, 0.31);
  vec3 pal2 = vec3(0.21, 0.24, 0.63);

  // ANIM
  float speed = 0.75 * t;
  // speed = 2.0 * m.x; // debug
  /** ^ `x`
      |      /\            /\            /\            /\      
      |    /    \        /    \        /    \        /    \    
      |  /        \    /        \    /        \    /        \  
      |/____________\/____________\/____________\/____________\> `time` */
  float timer = fract(mix(speed, -speed, step(1.0, mod(speed, 2.0))));

  // SHAPES
  // angle of the break
  float angle = map(S(0.2, 0.8, fract(speed)), 0.0, 1.0, 3.0 * TP, 0.0) - QP;
  // break between the two shapes
  float breaker = step(0.0, rotate2d(uv.zw, angle).x);
  // mix the shapes and the palettes
  float mixer = S(0.45, 0.55, timer);

  // BACKGROUND
  // rotated uv
  vec2 rv = rotate2d(uv.zw, -HP - QP);
  // switch the bounds to change the direction of the rotation
  vec2 bounds = mix(
    vec2(1.0, E), vec2(E, 1.0),
    step(1.0, mod(speed, 2.0))
  );
  // MIXERS - mix shapes, colors and background based on time
  vec2 mixers = vec2(
    S(0.45, 0.55, timer),
    S(
      S(0.5, 1.0, S(0.45, 0.65, timer)),
      S(0.0, 0.5, S(0.25, 0.9, timer)),
      map(atan(rv.y, rv.x), -P, P, bounds.x, bounds.y)
    )
  );

  /* firstly compute the two sdf, circle and rectangle
  then mix/interpolate them into a shape
  finaly morph two values over time
  */
  // SDF
  float circ = circleSDF(uv.zw);
  float rect = rectSDF(uv.zw, vec2(1.0));
  float shape = mix(circ, rect, mixers.x);
  float shadow = rectSDF(rotate2d(uv.zw, angle), vec2(0.02, 0.25));
  // FIILS
  vec2 p = vec2(
    0.1,
    map(
      S(0.4, 0.6, 2.0 * fract(mix(speed, -speed, step(0.5, mod(speed, 1.0))))),
      0.0, 1.0,
      1.75, 4.5
    )
  ); // precisions
  // compute the fill of the two shapes, the sharp and the blurry7
  vec2 shapefs = vec2(fill(shape, 0.5, p.x), fill(shape, 0.5, p.y));
  // combine the two shapes to get this slashed render
  float shapef = mix(shapefs.x, shapefs.y, breaker); // main effect
  // compute the shadow
  float shadowf = 0.125 * fill(shadow, 1.0, 51.0 * p.y);
  color = mix(
    mix(white, black, mixers.y),
    mix(pal1, pal2, mixers.x) * shapef,
    shapef
  );
  // add more depth with a shadow
  color -= shapef * mix(shadowf, 0.0, breaker);

  glFragColor = vec4(color, 1.0);
}
