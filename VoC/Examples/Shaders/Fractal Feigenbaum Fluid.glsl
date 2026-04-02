#version 420

// original https://www.shadertoy.com/view/XtXGWl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ITERS 500
#define M_PI 3.1415926535897932384626433832795

void main(void)
{
  vec2 p = vec2(gl_FragCoord.x / resolution.x,
                gl_FragCoord.y / resolution.y);
  float z = fract(0.005 * time);
  int acc = 0;
  float trig = (cos(6. * M_PI * z) + 1.) / 2.;
  float a = mix(2.5, 3.8, trig) + p.x * mix(1.5, 0.2, trig);
  
  float SC = mix(1., 3., trig);
  float OFF = mix(0., 1., trig);
  for (int i = 0; i < ITERS; i++) {
    float zz = SC * z - OFF;
    acc += (zz > p.y && zz <= p.y + 1. / resolution.y) ? 1 : 0;
    z = a * z * (1.-z);
  }
  float iters = float(ITERS);
  float g = 60. * float(acc) / iters;

  glFragColor = vec4(1. - g, 1. - g /6., 1. - g / 10.,1.);

}
