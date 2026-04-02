#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3tyBzt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU (6.283185307)

const int[] shuffle = int[](
58, 96, 38, 245, 35, 52, 218, 105, 143, 23, 32, 181, 19, 201, 63, 28, 251, 61, 30, 173, 180, 27, 72, 224, 116, 79, 114, 113, 137, 229, 81, 184, 219, 70, 234, 120, 227, 83, 220, 174, 178, 43, 103, 88, 80, 54, 21, 87, 111, 8, 151, 110, 208, 207, 190, 12, 127, 203, 75, 125, 241, 121, 212, 213, 26, 141, 246, 131, 204, 64, 48, 157, 216, 37, 33, 206, 108, 57, 250, 102, 197, 44, 68, 92, 170, 243, 130, 56, 215, 47, 139, 4, 3, 230, 29, 146, 163, 50, 123, 196, 136, 24, 135, 91, 78, 198, 186, 236, 16, 217, 209, 242, 117, 95, 153, 36, 188, 115, 42, 93, 158, 167, 34, 144, 0, 253, 69, 223, 200, 162, 65, 239, 126, 67, 221, 74, 175, 214, 85, 11, 66, 193, 154, 194, 152, 231, 205, 254, 9, 45, 14, 55, 222, 233, 192, 94, 134, 172, 13, 244, 211, 232, 199, 240, 98, 142, 247, 118, 99, 176, 187, 109, 62, 129, 210, 51, 10, 156, 164, 5, 124, 106, 166, 138, 49, 128, 89, 53, 182, 20, 1, 22, 119, 255, 249, 40, 168, 6, 195, 17, 149, 235, 169, 112, 191, 237, 86, 179, 101, 140, 165, 238, 84, 73, 122, 248, 183, 41, 59, 228, 46, 90, 148, 132, 25, 189, 82, 225, 202, 150, 100, 39, 7, 177, 133, 252, 145, 171, 104, 77, 107, 15, 155, 160, 185, 2, 76, 147, 71, 60, 226, 31, 18, 97, 159, 161
);
// fade function defined by ken perlin
vec2 fade(vec2 t) {
  return t * t * t * (t * (t * 6. - 15.) + 10.);
}
// corner vector
vec2 cvec(vec2 uv, float time) {
  float n = TAU * float(shuffle[int(uv.x) + shuffle[int(uv.y) & 255] & 255]) / 256.0 + time;
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
  int m = int(floor(n) - 6.0 * floor(n / 6.0));
  return mix(
    colors[m % 6],
    colors[(m + 1) % 6],
    smoothstep(0.9, 1.0, fract(n))
  );
}
void main(void)
{
  // Normalized pixel coordinates (from 0 to 1)
  float scale = min(resolution.x, resolution.y);
  vec2 uv = (gl_FragCoord.xy - 0.50 * resolution.xy) / scale;
  
  const float noisiness = 1.5;

  float value = 6.0 * (atan(uv.y, uv.x) / TAU + time / 4.);
  value += 4.0 * length(uv);
  value += noisiness * perlin(uv * 2.0, time / 32.);
  value += noisiness * 0.4 * perlin(uv * 8.0, time / 16.);
  value += noisiness * 0.1 * perlin(uv * 45.0, time /  8.);
  // Output to screen
  glFragColor = vec4(
    stripes(
      value + (6.0 * fract(time / 12.))
    ), 1.0
  );
}
