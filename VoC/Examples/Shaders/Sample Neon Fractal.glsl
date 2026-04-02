#version 420

// original https://www.shadertoy.com/view/wt2czW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define FRACTAL true
#define STEP .5
#define BRIGHTNESS .2

vec4 hue(vec4 color, float shift) {
  const vec4 kRGBToYPrime = vec4(0.299, 0.587, 0.114, 0.0);
  const vec4 kRGBToI = vec4(0.596, -0.275, -0.321, 0.0);
  const vec4 kRGBToQ = vec4(0.212, -0.523, 0.311, 0.0);
  const vec4 kYIQToR = vec4(1.0, 0.956, 0.621, 0.0);
  const vec4 kYIQToG = vec4(1.0, -0.272, -0.647, 0.0);
  const vec4 kYIQToB = vec4(1.0, -1.107, 1.704, 0.0);
  float YPrime = dot(color, kRGBToYPrime);
  float I = dot(color, kRGBToI);
  float Q = dot(color, kRGBToQ);
  float hue = atan(Q, I);
  float chroma = sqrt(I * I + Q * Q);
  hue += shift;
  Q = chroma * sin(hue);
  I = chroma * cos(hue);
  vec4 yIQ = vec4(YPrime, I, Q, 0.0);
  color.r = dot(yIQ, kYIQToR);
  color.g = dot(yIQ, kYIQToG);
  color.b = dot(yIQ, kYIQToB);
  return color;
}

mat2 rotate2d(float a){
  return mat2(cos(a), -sin(a), sin(a), cos(a));
}

void main(void) {
  vec2 p = 2. * gl_FragCoord.xy/resolution.xy - 1.;
  p.x *= resolution.x / resolution.y;
  glFragColor = vec4(0.);
  for (float i = 8.; i < 9.; i++) {
    if (FRACTAL) { p = abs(fract(p) - .5); }
    p *= STEP*i;
    float dist = distance(p, vec2(sin(time/10.)));
    p *= rotate2d(abs(sin(dist)) - time/5.);
    glFragColor.r += cos(p.x * p.y);
    glFragColor.g += cos(p.y * i) + cos(p.y * i);
    glFragColor.b += cos(p.x * i) - cos(p.y / i);
  }
    
  glFragColor = BRIGHTNESS*(hue(1.-2.*log(abs(glFragColor)), time));
}
