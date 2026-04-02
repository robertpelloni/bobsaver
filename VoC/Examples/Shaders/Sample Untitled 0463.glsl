#version 420

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

float m(vec3 p)
{
   p.z += time;
   float i = 0., s = 1., k;
   for (float i = 1.0; i <= 5.0; i++)
      p *= k = 1.5 / dot(p = mod(p - 1., 2.) - 1., p), s *= k;
   return length(p) / s; 
}

void main( void)
{
   vec3 d = vec3(gl_FragCoord.xy/resolution.y - .5, 1)/4., o = vec3(1, 1, 0);
   for (float i = 1.0; i <= 40.0; i++)
      o += m(o) * d;
   glFragColor += (o.z - 2.)/o.z;
}
