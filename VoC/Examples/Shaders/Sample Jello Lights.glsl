#version 420

// original https://www.shadertoy.com/view/tttfR2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141592
#define ORBS 20.

void main(void) {
  vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
  uv *= 279.27;
  for (float i = 0.; i < ORBS; i++) {
    uv.y -= i / 1000. * (uv.x); 
    uv.x += i / 0.05 * sin(uv.x / 9.32 + time) * 0.21 * cos(uv.y / 16.92 + time / 3.) * 0.21;
    float t = 5.1 * i * PI / float(ORBS) * (2. + 1.) + time / 10.;
    float x = -1. * tan(t);
    float y = sin(t / 3.5795); 
    vec2 p = (115. * vec2(x, y)) / sin(PI * sin(uv.x / 14.28 + time / 10.));
    vec3 col = cos(vec3(0, 1, -1) * PI * 2. / 3. + PI * (5. + i / 5.)) * 0.5 + 0.5;
    glFragColor += vec4(i / 40. * 55.94 / length(uv - p * 0.9) * col, 3.57);
  }
  glFragColor.xyz = pow(glFragColor.xyz, vec3(3.57));
  glFragColor.w = 1.0;
}
