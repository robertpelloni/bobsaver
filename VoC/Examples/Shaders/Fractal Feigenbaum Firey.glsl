#version 420

// original https://www.shadertoy.com/view/Mls3Df

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
  float z = fract(0.02 * time);
  int acc = 0;
  float trig = (cos(2. * M_PI * z) + 1.) / 2.;
  float a = mix(1., 3.75, trig) + p.x * mix(3., 0.25, trig);
  
  for (int i = 0; i < ITERS; i++) {
    acc += (z > p.y && z <= p.y + 1. / resolution.y) ? 1 : 0;
    z = a * z * (1.-z);
  }
  float iters = float(ITERS);
  float g = 25. * float(acc) / iters;

  glFragColor = vec4(g, g /3., g / 8.,1.);

}
