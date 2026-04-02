#version 420

// original https://www.shadertoy.com/view/WtGfRw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141592
#define orbs 20.

/*

Variant 01 

*/

#define zoom 0.07
#define contrast 0.13
#define orbSize 6.46
#define radius 11.
#define colorShift 10.32
#define sides 1.
#define rotation 1.
#define sinMul 0.
#define cosMul 2.38
#define yMul 0.
#define xMul 0.28
#define xSpeed 0.
#define ySpeed 0.
#define gloop 0.003;
#define yDivide 4.99
#define xDivide 6.27

/*

Variant 02

#define zoom 0.27
#define contrast 0.13
#define orbSize 4.25
#define radius 11.
#define colorShift 10.32
#define sides 1.
#define rotation 1.
#define sinMul 0.
#define cosMul 2.38
#define yMul 0.
#define xMul 0.28
#define xSpeed 0.
#define ySpeed 0.
#define gloop 0.003
#define yDivide 11.
#define xDivide 12.4

*/

/*

Variant 03

#define zoom 0.02
#define contrast 0.13
#define orbSize 11.
#define radius 3.21
#define colorShift 10.32
#define sides 1.
#define rotation 1.
#define sinMul 0.
#define cosMul 5.
#define yMul 0.
#define xMul 0.28
#define xSpeed 0.
#define ySpeed 0.
#define gloop 0.003
#define yDivide 10.99
#define xDivide 12.

*/

vec4 orb(vec2 uv, float s, vec2 p, vec3 color, float c) {
  return pow(vec4(s / length(uv + p) * color, 1.), vec4(c));
}

mat2 rotate(float a) {
  return mat2(cos(a), -sin(a), sin(a), cos(a));
}

void main(void) {
  vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
  uv *= zoom;
  uv /= dot(uv, uv);
  uv *= rotate(rotation * time / 10.);
  for (float i = 0.; i < orbs; i++) {
    uv.x += sinMul * sin(uv.y * yMul + time * xSpeed) + cos(uv.y / yDivide - time);
    uv.y += cosMul * cos(uv.x * xMul - time * ySpeed) - sin(uv.x / xDivide - time);
    float t = i * PI / orbs * 2.;
    float x = radius * tan(t);
    float y = radius * cos(t + time / 10.);
    vec2 position = vec2(x, y);
    vec3 color = cos(.02 * uv.x + .02 * uv.y * vec3(-2, 0, -1) * PI * 2. / 3. + PI * (float(i) / colorShift)) * 0.5 + 0.5;
    glFragColor += .65 - orb(uv, orbSize, position, 1. - color, contrast);
  }
}
