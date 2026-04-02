#version 420

// original https://www.shadertoy.com/view/Ws3XR4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//  FunPipes    by mikael [code]  
//  release party : Xenium 2019

float l(vec3 f)
{
float l=fract(cos(dot(floor(abs(f)),vec3(13,78,35)))*43759.);
if(l<.8)f=f.gbr;
if(l<.4)f=f.gbr;
f=fract(f);
l=length(vec2(length(f.rg),f.b)-.5);
f=f.gbr-vec3(1,1,0);
l=min(l,length(vec2(length(f.rg),f.b)-.5));
f=f.gbr-vec3(-1,1,-1);
return min(l,length(vec2(length(f.rg),f.b)-.5))-.1;
}

float l(vec3 f,vec3 g,float m)
{
float r,b=0.;
for(r=.001;r<=m;r+=b)
 {
 b=l(f+g*r);
 if(b<.001*r)
   break;
 }
return r;
}

void main(void)
{
vec3 g=vec3(0.,0.,time*.5), b=g+vec3(0,0,1), m=normalize(vec3(gl_FragCoord.rg / resolution.y - 1., 1.));
vec2 i=sin(vec2(0,1.571)+time*.1);
m.rg*=mat2(i.g,-i.r,i);    
m.rb*=mat2(i.g,-i.r,i);    
float k=min(l(g,m,6.),6.);
g+=m*k;
vec3 s=normalize(b-g);
float n=length(b-g);
i.r=.001;
i.g=0.;
b=normalize(vec3(l(g+i.rgg),l(g+i.grg),l(g+i.ggr))-l(g));
vec3 a=vec3(0.);
for(float p=0.; p<.5; p+=.1)
 a+=l(g+b*p)/(1.+p);
if(l(g,s,n)>=n)
 a+=dot(b,s)+pow(max(dot(reflect(-s,b),-m),0.),4.);
glFragColor = vec4( mix(a*(b+8.)/20.+l(g,reflect(m,b),2.)/8., vec3(.1,.2,.3), k/6.), 1. );
}
