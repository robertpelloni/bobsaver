#version 420

// original https://www.shadertoy.com/view/7sSGzW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU 6.283185307179586 // 2 * PI
uniform vec2 u_resolution;
uniform float u_time;
const vec3 gamma = vec3(2.2);
const vec3 igamma = 1.0 / gamma;

const vec4 H0 = vec4(0.5138670813222691, 0.5431834938989584, 0.5741724246765705, 0.6069292917805363);
const vec4 H1 = vec4(0.6415549569952288, 0.678156036327837, 0.7168452282900885, 0.7577416609086309);
const vec4 H2 = vec4(0.8009712585325574, 0.846667129567511, 0.8949699763302439, 0.9460285282856136);
const vec4 R = vec4(0.632006, 0.128123, 0.223201, 0.988116);

float wobbly(vec2 uv, float t, float seed) {
  vec4 f = (fract(H0 * seed + R) - .5) * 4.0 + 1.0;
  vec4 g = (fract(H1 * seed + R) - .5) * 2.0;
  vec4 p = (fract(H2 * seed + R) - .5) * 2.0;
  const float ma = 0.25;

  vec2 a = sin((f.xy * uv + g.xy * t + p.xy) * TAU);
  vec2 b = sin((f.zw * uv + g.zw * t + p.zw + ma * a.yx) * TAU);

  return 0.5 * (b.x + b.y);
}

void main(void) {
  // this is how to get the pixels straight
  vec2 aspect = resolution.xy / resolution.y;
  vec2 uv = (gl_FragCoord.xy / resolution.xy - 0.5) * aspect;
  uv *= 0.6;

  float t = time * 0.1;
  const float seedA = 562.0;
  const float seedB = 845.0;
  const float seedC = 173.0;

  vec2 d = vec2(wobbly(uv, t, seedA), wobbly(uv, t, seedB));
  float L = length(d);
  d /= mix(1.0, L, smoothstep(.45, .4, L));

  vec3 col = vec3(
    .5 + .5 * wobbly(uv + 0.1 * d, t,  seedC),
    .5 + .5 * wobbly(uv + 0.14 * d, t, seedC),
    .5 + .5 * wobbly(uv + 0.18 * d, t, seedC)
  );

  float cm = (col.x + col.y + col.z) / 3.0;

  col = smoothstep(0.0, 1.0, (col - cm) * 2.0 + cm);
  float smokiness = 1.;//(.5 + .5 * sin(t * 0.5)) * 12.0 + 1.0;
  float border = smoothstep(0.015 * smokiness,0.03 * smokiness, abs(L - 0.425));
  col *= border;

  // Output to screen
  glFragColor = vec4(col, 1.0);
}

