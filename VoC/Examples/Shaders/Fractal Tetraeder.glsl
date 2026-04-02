#version 420

// original https://www.shadertoy.com/view/DddSWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of "Romanesco 2.0" by elias. https://shadertoy.com/view/Xs3XW2

// Tetraeder_Fractal_Optimized.glsl   2023-03-25

// Fork of "Romanesco 2.0" fractal shader with some code optimizations.
// You can use your mouse to change fractal parameter !

float t = 5e-3;

// 2d rotation matrix
mat2 rotate(float a)   { float c=cos(a),   s=sin(a);  return mat2(c,-s,s,c); }

void main(void)
{
  vec2 mp = 18. + mouse*resolution.xy.xy / resolution.xy * 6.;
  vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
  vec3 b = vec3(.707, .707, 0);
  mat2 rotateTime = rotate (.3*time);
  mat2 rotateMx = rotate (mp.x);
  mat2 rotateMy = rotate (mp.y);
  for (float i = 0.; i < 64.; i++)
  {
    vec3 p = vec3(uv, t - 1.);
    p.xz *= rotateTime;
    for (float i = 0.; i < 20.; i++)
    {
      p.xz *= rotateMx;
      p.xy *= rotateMy;
      p -= min(0., dot(p, b)) * b * 2.; b = b.zxx;
      p -= min(0., dot(p, b)) * b * 2.; b = b.zxz;
      p -= min(0., dot(p, b)) * b * 2.; b = b.xxy;
      p = p * 1.5 - .25;
    }
    t += length(p) / 3325.;
    if (length(p) / 3325. < 5e-3 || t > 2.)
    {
      b = vec3(1); p *= .5;
      glFragColor = vec4(p / length(p) * (t < 2. ? 5. / i : i / 64.), dot(p, b));
      break;
    }
  }
}
