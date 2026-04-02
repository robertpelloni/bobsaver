#version 420

// original https://www.shadertoy.com/view/7dX3Wj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// from https://gist.github.com/marioecg/b163c5b4f7f5086137defd78dbb34e1f

#define PI 3.1415926538

float map(float value, float inMin, float inMax, float outMin, float outMax) {
  return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);
}

// https://iquilezles.org/www/articles/distgradfunctions2d/distgradfunctions2d.htm
vec3 sdgCircle(in vec2 p, in float r) {
  float d = length(p);

  return vec3( d-r, p/d );
}   

void main(void)
{
float time = time;
  vec2 uv = (gl_FragCoord.xy/resolution.xy) - 0.5;

  vec3 color = vec3(0.0);
  vec3 circle = vec3(1.0);

  float amp = map(cos(time), -1.0, 1.0, 0.15, 0.35);
  float t = time * 1.0;

  const int n = 1;
  for (int i = 0; i <= n; i++) {
    float offset = map(float(i), 0.0, float(n), 0.0, PI * 1.0);

    circle *= sdgCircle(
      uv + vec2(cos(t + offset), sin(t + offset)) * amp, 
      1.0
    );
  }
  
  float goff = map(sin(time), -1.0, 1.0, 0.0, 0.6);
  circle = mix(vec3(1.0, goff, 0.5), vec3(1.0), circle * 1.0);

  glFragColor = vec4(circle, 1.0);
}
