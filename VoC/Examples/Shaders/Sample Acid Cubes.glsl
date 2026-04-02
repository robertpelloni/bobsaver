#version 420

// original https://www.shadertoy.com/view/ttccDX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141592
#define BALLS 20.

mat2 rotate2d(float a) {
  return mat2(cos(a), -sin(a), sin(a), cos(a));
}

void main(void) {
  vec2 uv = gl_FragCoord.xy / resolution.xy;
  uv.x -= .5;
  uv.y -= .5;
  uv.x *= resolution.x / resolution.y;
  uv = abs(uv);
  uv *= 100.;
  float dist = length((uv));
  uv *= rotate2d(time / 7.);
  for (float i = 0.; i < BALLS; i++) {
    uv.y += .5 * (i / 20.) * cos(uv.y / 1000. + time / 4.) + sin(uv.x / 50. - time / 2.);
    uv.x += .5 * (i) * sin(uv.x / 300. + time / 6.) * sin(uv.y / 50. + time / 5.);
    float t = .01 * dist * (i) * PI / BALLS * (5. + 1.);
    vec2 p = 8. * vec2(-1. * cos(t), 1. * sin(t / 6.));
    p /= sin(PI * sin(uv.x / 10.) * cos(uv.y / 11.));
    vec3 col = cos(vec3(0, 1, -1) * PI * 2. / 3. + PI * (time / 5. + float(i) / 5.)) * 0.5 + 0.5;
    glFragColor += vec4(float(i) * .2 / length(uv - p * 0.9) * col, 1.);
  }
  glFragColor.xyz = pow(glFragColor.xyz, vec3(2.));
  glFragColor.w = 1.0;
} 
