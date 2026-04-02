#version 420

// original https://www.shadertoy.com/view/wdVBWd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// https://twitter.com/gam0022/status/1339584625929175042

#define t time
#define r resolution
void main(void)
{

vec2 p=gl_FragCoord.xy/min(r.x,r.y)*8.;
float a=length(p)+t*acos(-1.);
p+=0.2*tan(a)*cos(a);
glFragColor=vec4(0,0.3,0,1)*mod(floor(p.x)+floor(p.y),2.)*(2.+sin(a+3.))+0.1;

}
