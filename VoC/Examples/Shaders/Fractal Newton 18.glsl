#version 420

// original https://www.shadertoy.com/view/tldfWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Newton convergence of x³+sin(time).x²+cos(time).x-1 = 0
//   based on https://www.shadertoy.com/view/4tdczH
//   credit - Paulo Martel 2018

vec2 cdiv(vec2 a, vec2 b){return vec2(a.x*b.x+a.y*b.y,a.y*b.x-a.x*b.y)/(b.x*b.x+b.y*b.y);}
vec2 cmul(vec2 a, vec2 b){return vec2(a.x*b.x-a.y*b.y,a.x*b.y+b.x*a.y);}
vec4 newton(vec2 c)
{
 vec2 x, xn;
 xn = c;
 x = xn - cdiv(cmul(xn,cmul(xn+sin(time),xn)+cos(time))-vec2(1.,0.),3.*cmul(xn,xn+2.*sin(time))+cos(time));
 float i=0.;
 for(;i<15.&&length(x-xn)>1.e-4;i++)
 {
  xn = x;
  x = xn - cdiv(cmul(xn,cmul(xn,xn))-vec2(1.0,0),(3.0*cmul(xn,xn)));
 }
 return vec4(i/15.0,0.5+i*0.05*x.y,0.5+0.25*x.x,1.0);
}    

void main(void)
{
 vec2 uv = (gl_FragCoord.xy-mouse*resolution.xy.xy)/resolution.y ;
 glFragColor = newton(uv);
}
