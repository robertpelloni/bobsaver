#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define N 3

vec4 plasma(vec2 u)
{
  vec2 p = u;
  float t = time * 2.4;
  float r = 0.0;
    float a = atan(p.x,p.y)*4.;
  for ( int i = 0; i < N; i++ )
  {
    float d = 3.14159265 * float(i) * 5.0 / float(N);
    r = length(p) + 0.01;
    a = atan(p.x,p.y)*4.;
    float xx = p.x;
   // p.x += cos(p.y+sin(r*1.3+time) + d + r ) + cos(t*2.+a+r);
   // p.y -= sin(xx +cos(r*2.3+a) - d + r + time*2.) + sin(t-r*2.);
    p.x += cos(p.y+sin(r*1.1+time) + d + r ) + cos(t*2.+r);
    p.y -= sin(xx +cos(r*2.1+a) - d + r + time*2.) + sin(t-r*2.);
  }
  //return vec4(cos(r*0.5), cos(r*1.9), cos(r*2.0), 1.0);
    r/=35.;
    r=1.-r;
    return vec4(r, r*r, 0.7-r, 1.0);
}

void main( void ) 
{
  vec2 uv = (gl_FragCoord.xy - resolution.xy / 2.0) / resolution.yy * 40.0;
  glFragColor = plasma (uv);
}
