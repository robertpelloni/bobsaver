#version 420

// original https://www.shadertoy.com/view/DddGDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define TWO_PI 2. * PI
#define ITERATIONS 10.

vec4 k_orb(vec2 uv, float size, vec2 position, vec3 color, float contrast) {
  return pow(vec4(size / length(uv + position) * color, 1.), vec4(contrast));
}

vec3 k_rainbow(float progress, float stretch, float offset) {
  return vec3(cos(vec3(-2, 0, -1) * TWO_PI / 3. + TWO_PI * (progress * stretch) + offset) * 0.5 + 0.5);
}

mat2 k_rotate2d(float a) {
  return mat2(cos(a), -sin(a), sin(a), cos(a));
}

void main(void) {
  float time = time / 7.8;
  vec2 uv = -1. + 2. * gl_FragCoord.xy / resolution.xy;
  uv.x *= resolution.x/resolution.y;
  uv *= 0.199;
  uv /= dot(uv, uv);
  uv *= k_rotate2d(time); 
  glFragColor = vec4(0.);
  
  // so slow :(
  for (float i = 0.; i < ITERATIONS; i++) {
    uv.x += 1.5 * cos(0.53 * uv.y);
    uv.y += 0.84 * cos(0.42 * uv.x + time/.15);
    vec3 color = k_rainbow(i / (ITERATIONS * 1.6), 0.825, 0.);
    glFragColor += k_orb(uv,6., vec2(0, 0), color, 1.262);
  }

  glFragColor.xyz = 1. - abs(1.-log(abs(glFragColor.xyz)));
}
