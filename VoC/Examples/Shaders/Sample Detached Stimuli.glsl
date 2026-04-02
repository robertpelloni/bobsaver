#version 420

// original https://www.shadertoy.com/view/fsj3zW

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
  vec4 f = (fract(H0 * seed + R) - .5) * 2.4; f += .4 * sign(f);
  vec4 g = (fract(H1 * seed + R) - .5) * 0.2; g += .1 * sign(g);
  vec4 p = (fract(H2 * seed + R) - .5) * 2.0;
  const float ma = 0.3;

  vec2 a = sin((f.xy * uv + g.xy * t + p.xy) * TAU);
  vec2 b = sin((f.zw * uv + g.zw * t + p.zw + ma * a.yx) * TAU);

  return 0.5 * (b.x + b.y);
}

vec2 wobbly2(vec2 uv, float t, vec2 seed) {
  return (vec2(wobbly(uv, t, seed.x), wobbly(uv, t, seed.y))
        + vec2(wobbly(uv * .5, t, seed.y + 2323.), wobbly(uv * .5, t, seed.x + 1123.))) * .5  ;
}

void main(void) {
  // this is how to get the pixels straight
  vec2 iRes1 = 1. / resolution.xy; 
  vec2 aspect = resolution.xy * iRes1.y;
  vec2 uv = (gl_FragCoord.xy * iRes1 - 0.5) * aspect;
  vec2 st = gl_FragCoord.xy * iRes1;
  uv *= 1.2;

  float t = time * 0.1;
  const float seedA = 1.0;
  const float seedB = 2.0;
  const float seedC = 3.0;
  
  const vec2 seedAB = vec2(seedA, seedB);
  float a0 = .025 * (.1 + .9 * smoothstep(-.4, .4, sin(4. * length(uv) + t * 1.9))); 
  float r0 = a0 * 5., g0 = a0 * 6., b0 = a0 * 7.;
  vec2 uvr = uv, uvg = uv, uvb = uv;
  uvr += r0 * wobbly2(uvr, t, seedAB); uvr += r0 * wobbly2(uvr, t, seedAB);
  uvr += r0 * wobbly2(uvr, t, seedAB); uvr += r0 * wobbly2(uvr, t, seedAB);
  uvr += r0 * wobbly2(uvr, t, seedAB);
  uvg += g0 * wobbly2(uvg, t, seedAB); uvg += g0 * wobbly2(uvg, t, seedAB);
  uvg += g0 * wobbly2(uvg, t, seedAB); uvg += g0 * wobbly2(uvg, t, seedAB);
  uvg += g0 * wobbly2(uvg, t, seedAB);
  uvb += b0 * wobbly2(uvb, t, seedAB); uvb += b0 * wobbly2(uvb, t, seedAB);
  uvb += b0 * wobbly2(uvb, t, seedAB); uvb += b0 * wobbly2(uvb, t, seedAB);
  uvb += b0 * wobbly2(uvb, t, seedAB);

  float strip = distance(uv, (uvr+uvg+uvb)/3.);
  strip = smoothstep(.22,.28, abs(fract(strip * 8.0) - 0.5));
  vec3 col = vec3(
    .5 + .5 * wobbly(uvr, t,  seedC),
    .5 + .5 * wobbly(uvg, t, seedC),
    .5 + .5 * wobbly(uvb, t, seedC)
  ) * strip;

  float cm = (col.x + col.y + col.z) / 3.0;
  col = smoothstep(0.0, 1.0, (col - cm) * 2.0 + cm);

  // Output to screen
  glFragColor = vec4(col, 1.);
}
