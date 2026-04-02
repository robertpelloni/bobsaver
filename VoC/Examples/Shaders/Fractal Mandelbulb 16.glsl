#version 420

// original https://www.shadertoy.com/view/XlXcWj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{  
  float T = time/100.0;
  vec2 M = mouse.xy*resolution.xy;
  vec2 R = resolution.xy;

  float k = 0.0;

  for (float i = 0.0; i < 16.0; i++) {
    vec3 p = vec3((2.0 * gl_FragCoord.xy - R.xy) / R.yy, k - 1.);
    
    float a = T * 25.0;
    p.zy *= mat2(cos(a), -sin(a), sin(a), cos(a));
    a /= 2.;
    p.xy *= mat2(cos(a), -sin(a), sin(a), cos(a));
    a /= 2.;
    p.zx *= mat2(cos(a), -sin(a), sin(a), cos(a));

    vec3 z = p;
    float c = 1.0;
           
    for (float i = 0.; i < 9.0; i++) {
      float r = length(z);
        if (r > 6.0) {
          k += log(r) * r / c / 2.0;
          break;
        }

      float a = acos(z.z / r) * (6.0 + 9.0 * M.x / R.x);
      float b = atan(z.y, z.x) * (6.0 + 9.0 * M.y / R.y);

      c = pow(r, 7.0) * 5.0 * c / r + 1.0;
      z = pow(r, 7.0) * vec3(sin(a) * cos(b), -sin(a) * sin(b), -cos(a)) + p;
    }

    glFragColor = vec4(1.0 - i / 16.0 - k + p / 4.0, 1.0);
    
      if (log(length(z)) * length(z) / c < .005) {
       break;
    }
  }
}
