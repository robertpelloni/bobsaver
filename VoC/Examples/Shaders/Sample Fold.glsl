#version 420

// original https://www.shadertoy.com/view/WtscWN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
  vec3 u=vec3(2.*gl_FragCoord.xy-resolution.xy,resolution.y)/1e2;
  for(int i=0;i<9;i++)
  u.x+=fract(u.y+time+cos(u.x)*sin(time*.5))*.2,
  u.xy+=sin(u.y+time*6.)*.1,
  glFragColor=cos(float(u)+vec4(.3,.1,0,0));
}
