#version 420

// original https://www.shadertoy.com/view/3t3BRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141592
#define LINES 12.

mat2 rotate(float a) {
  return mat2(cos(a), -sin(a), sin(a), cos(a));
}

void main(void) {
  vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
  uv /= vec2(1.1 * dot(uv, .01 * uv));
  for (float i = 0.; i < LINES; i++) {
    uv *= rotate(time / 20.);
    float x = 8.79 * sin(.01 * uv.x - time) * uv.y * 2.1;
    float y = length(.1 * log(abs(uv)));
    vec2 p = vec2(x, y);
    vec3 col = cos(vec3(-2, 0, -1) * PI * 2. / 3. + PI * i * time / 10. + i / 70.) * 0.5 + 0.5;
    glFragColor += vec4(21.264 / length(uv - p * 0.9) * col, 2.45);
  }
  glFragColor.xyz = pow((glFragColor.xyz), vec3(2.45));
  glFragColor.w = 1.0;
}
