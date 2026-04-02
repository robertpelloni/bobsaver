#version 420

// original https://www.shadertoy.com/view/wtyfW1

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
  uv *= 116.;
  float dist = length((uv));
  for (float i = 0.; i < BALLS; i++) {
    uv.y += .5 * (i / 4.) * cos(uv.y /444. + time / 0.1) + sin(uv.x / 30. - time / 0.4);
    uv.x += .5 * (i) * sin(uv.x / 100. + time / 1.) * sin(uv.y / 50. + time / 4.);
    float t = 0.008 * dist * (i) * PI / BALLS * (5. + 1.);
    vec2 p = 3. * vec2(-1. * cos(t), 1. * sin(t /6.));
    p /= sin(PI * sin(uv.x / 15.) * cos(uv.y / 0.1));
    vec3 col = cos(vec3(6, 6, -1) * PI * 2. / 3. + PI * (time / 5. + float(i) / 5.)) * 0.5 + 0.5;
    glFragColor += vec4(float(i) * .3 / length(uv - p * 8.3) * col, 0.1);
  }
  glFragColor.xyz = pow(glFragColor.xyz, vec3(1.5));
  glFragColor.w = 6.0;
} 
