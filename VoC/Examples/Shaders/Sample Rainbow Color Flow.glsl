#version 420

// original https://www.shadertoy.com/view/Xcs3zH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define TWO_PI 2. * PI
#define ITERATIONS 30.

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
  float time = time / 32.8;
  vec2 uv = -1. + 2. * gl_FragCoord.xy / resolution.xy;
  uv.x *= resolution.x/resolution.y;
  uv *= 0.08;
  uv /= dot(uv, uv);
  uv *= k_rotate2d(time); 
  glFragColor = vec4(0.);
  
  // so slow :(
  float s = 0.3;
  for (float i = 0.; i < ITERATIONS; i++) {
    uv.x += s*1.5 * cos(0.53 * uv.y);
    uv.y += s*0.84 * cos(0.42 * uv.x + time/.015);
    vec3 color = k_rainbow(i / (ITERATIONS * 25.0), sin(time*0.5+uv.y*0.15)*4., time*0.5);
    glFragColor += k_orb(uv, 2.2, vec2(0, 0), color, 0.7);
  }

   glFragColor.xyz = 1. - abs(1.-log(abs(glFragColor.xyz)));
   glFragColor.xyz = pow(glFragColor.xyz, vec3(0.5));
}
