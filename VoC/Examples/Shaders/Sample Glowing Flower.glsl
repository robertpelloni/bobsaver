#version 420

// original https://www.shadertoy.com/view/wt3fzX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141592
#define orbs 20.

vec2 kale(vec2 uv, vec2 offset, float sides) {
  float angle = atan(uv.y, uv.x);
  angle = ((angle / PI) + 1.0) * 0.5;
  angle = mod(angle, 1.0 / sides) * sides;
  angle = -abs(2.0 * angle - 1.0) + 1.0;
  angle = angle;
  float y = length(uv);
  angle = angle * (y);
  return vec2(angle, y) - offset;
}

vec4 orb(vec2 uv, float size, vec2 position, vec3 color, float contrast) {
  return pow(vec4(size / length(uv + position) * color, 1.), vec4(contrast));
}

mat2 rotate(float angle) {
  return mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
}

void main(void) {
  vec2 uv = 23.09 * (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
  float dist = length(uv);
  uv *= rotate(time / 20.);
  uv = kale(uv, vec2(6.97), 6.);
  uv *= rotate(time / 5.);
  for (float i = 0.; i < orbs; i++) {
    uv.x += 0.57 * sin(0.3 * uv.y + time);
    uv.y -= 0.63 * cos(0.53 * uv.x + time);
    float t = i * PI / orbs * 2.;
    float x = 4.02 * tan(t + time / 10.);
    float y = 4.02 * cos(t - time / 30.);
    vec2 position = vec2(x, y);
    vec3 color = cos(vec3(-2, 0, -1) * PI * 2. / 3. + PI * (float(i) / 5.37)) * 0.5 + 0.5;
    glFragColor += orb(uv, 1.39, position, color, 1.37);
  }
}
