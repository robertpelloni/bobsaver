#version 420

// original https://www.shadertoy.com/view/DtBXDy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 r2d(float a) {
  return mat2(cos(a), -sin(a), sin(a), cos(a));
}

void main(void) {
  float PI = 3.14159;
  vec2 uv = -1. + 2. * gl_FragCoord.xy / resolution.xy;
  glFragColor = vec4(0, 0, 0, 1.);
  uv.x *= resolution.x/resolution.y;
  uv *= .09;
  uv = abs(uv);
  uv /= dot(uv, uv);
  uv *= r2d(1157.12);
  for (float i = 0.; i < 20.; i++) {
    uv.x += 0.65 * cos(0.54 * uv.y - time);
    uv.y += 1.21 * cos(0.28 * uv.x + time);
    float t = i * PI / 21.00 * 2.;
    float x = 95.38 * tan(t - 4332. + time / 9.);
    float y = 25.38 * cos(t - 680.65);
    vec2 pos = vec2(x, y);
    vec3 col = vec3(cos(vec3(-2, 0, -1) * PI * 2. / 3. + (2. * PI) * (1.4) + 3.) * 0.5 + 0.5);
    glFragColor += pow(vec4(27. / length(uv + pos) * col, 1.), vec4(1.59));
    
  }
  glFragColor.xyz = 1. - pow(abs(1. - log(abs(glFragColor.xyz))), vec3(1.59));
}

