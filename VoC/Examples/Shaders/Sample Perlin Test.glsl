#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wlyfz3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU (6.283185307)

// A single iteration of Bob Jenkins' One-At-A-Time hashing algorithm.
uint hash(uint x) {
    x += ( x << 10u );
    x ^= ( x >>  6u );
    x += ( x <<  3u );
    x ^= ( x >> 11u );
    x += ( x << 15u );
    return x;
}
// fade function defined by ken perlin
vec2 fade(vec2 t) {
  return t * t * t * (t * (t * 6. - 15.) + 10.);
}
// corner vector
vec2 cvec(vec2 uv, float time) {
  uint x = uint(mod(uv.x, 256.));
  uint y = uint(mod(uv.y, 256.));
  float n = TAU * float(hash(x + hash(y))) + time;
  return vec2(cos(n), sin(n));
}
// perlin generator
float perlin(vec2 uv, float offset) {
  vec2 i = floor(uv);
  vec2 f = fract(uv);

  vec2 u = fade(f);

  return
  mix(
    mix(
      dot( cvec(i + vec2(0.0,0.0), offset ), f - vec2(0.0,0.0) ),
      dot( cvec(i + vec2(1.0,0.0), offset ), f - vec2(1.0,0.0) ),
    u.x),
    mix(
      dot( cvec(i + vec2(0.0,1.0), offset ), f - vec2(0.0,1.0) ),
      dot( cvec(i + vec2(1.0,1.0), offset ), f - vec2(1.0,1.0) ),
    u.x),
  u.y);
}
// stripes of color
const vec3[] colors = vec3[](
  vec3(245./255.,  23./255.,  22./255.),
  vec3(248./255., 210./255.,  26./255.),
  vec3( 47./255., 243./255., 224./255.),
  vec3( 96./255., 192./255.,  83./255.),
  vec3(250./255.,  38./255., 160./255.),
  vec3(174./255., 129./255., 255./255.)
);
vec3 stripes(float n) {
  return mix(
    colors[uint(n + 6.0) % 6u],
    colors[uint(n + 7.0) % 6u],
    smoothstep(0.9, 1.0, fract(n))
  );
}
void main(void)
{
  // Normalized pixel coordinates (from 0 to 1)
  float scale = min(resolution.x, resolution.y);
  vec2 uv = (gl_FragCoord.xy - 0.50 * resolution.xy) / scale;

  float value = length(uv) * 5.0;
  value += 2.0  * perlin(uv *  1.2, time / 16.);
  value += 0.2  * perlin(uv *  8.0, time /  8.);
  // Output to screen
  glFragColor = vec4(
    stripes(
      value * 1.5 + (6.0 * fract(time / 12.))
    ), 1.0
  );
}
