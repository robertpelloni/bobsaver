#version 420

// original https://www.shadertoy.com/view/tdKXWw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define EPSILON 0.0001
#define R0 1.0
#define ETA 1.07

float x = 0.;
vec2 d;

vec2 rotate(vec2 p, float t) 
{
return p * cos(-t) + vec2(p.y, -p.x) * sin(-t);
}

float m(vec3 v)
{
v.yz = rotate(v.yz, -time * 0.125);
v.zx = rotate(v.zx, time * 0.2);   
    
v.yz=cos((.5*x))*v.yz+sin((.5*x))*vec2(v.z,-v.y);
v.xz=cos((.5*x))*v.xz+sin((.5*x))*vec2(v.z,-v.x);
float m=length(v);
v=abs(normalize(v));
v=mix(mix(v.zxy,v.yzx,step(v.z,v.y)),v,step(v.y,v.x)*step(v.z,v.x));
float f=max(max(dot(v,vec3(.577)),dot(v.xz,vec2(.934,.357))),
max(dot(v.yx,vec2(.526,.851)),dot(v.xz,vec2(.526,.851))));
f=acos(f-.01)/1.57075;
f=smoothstep(.25,0.,f);
return m-2.-f*f*.7;
}

float m(vec3 v,vec3 x)
{
vec3 m=abs(v)-x;
float y=max(m.x,max(m.y,m.z));
return mix(y,length(max(m,0.)),step(0.,y));
}

float t(vec3 v)
{
float f=dot(v-vec3(0.,-5.,0.),vec3(0.,1.,0.));
f=min(f,-length(v)+150.);
f=min(f,length(v-vec3(3.,0.,0.)-1.));
return min(f,m(v-vec3(0.,0.,0.),vec3(1.)));
}

float p(vec3 v)
{
return t(v);
}

vec2 m(vec3 v,vec3 y,vec4 m)
{
vec3 x=m.xyz-v;
float f=dot(x,y),d=dot(x,x);
if(f<0.&&d>m.w) return vec2(0.);
float z=d-f*f;
if(z>m.w) return vec2(0.);
float s=sign(d-m.w);
return vec2(EPSILON*step(z,m.w)*s,f-sqrt(m.w-z)*s);
}

vec2 p(vec3 v,vec3 m,vec4 x)
{
float y=-dot(m,x.xyz), f=(dot(v,x.xyz)-x.w)/y;
return vec2(EPSILON*sign(y)*step(0.,f),f);
}

vec2 m(vec3 v,vec3 y,vec3 m,vec3 x)
{
vec3 f=m-x,d=m+x,s=(f-v)/y,z=(d-v)/y,a=min(s,z),p=max(s,z);
float e=min(p.x,min(p.y,p.z)),E=max(max(a.x,0.),max(a.y,a.z));
vec3 i=step(f,v),w=step(v,d);
float t=step(3.,dot(i,w));
return vec2(EPSILON*(t*-2.+1.)*step(E,e),mix(E,e,t));
}

vec2 p(vec3 v,vec3 f)
{
vec2 s=m(v,f,vec4(0.,-2.,0.,251.203));
vec3 d=v;
if(s.x==0.) return s;
if(s.x>0.) v+=f*s.y;
s.x=sign(m(v));
f*=s.x;
float x=0.,y=0.;
float i=0.;

do
 {
 y=m(v);
 v+=y*f*.5;
 y=abs(y);
 x+=y;
 if(y<x*.001) break;
 i+=1./150.;
 if(i>=1.)break;       
 }
while(i<1.);
    
if(i>=1.) return vec2(0.);
s.x*=y*2.;
s.y=length(d-v);
return s;
}

vec3 t(vec3 v,vec3 y)
{
vec2 f;
vec3 x=vec3(0.,500.,-1.);
f=p(v,y,vec4(0.,1.,0.,-5.));
x=mix(x,vec3(f,0.),abs(sign(f.x))*step(f.y,x.y)*step(0.,f.y));
f=m(v,y,vec4(0.,0.,0.,22500.));
f.x*=-1.;
x=mix(x,vec3(f,1.),abs(sign(f.x))*step(f.y,x.y)*step(0.,f.y));
f=p(v,y);
x=mix(x,vec3(f,2.),abs(sign(f.x))*step(f.y,x.y)*step(0.,f.y));
return x;
}

float p(vec3 v,vec3 x,float f,float y_)
{
float y=y_;
float m=sign(f),d=m*.5+.5;
while(y>0.) 
    {
    d-=(y*f-p(v+f*x*y*m))/exp2(y);
    y-=1.;
    if(y<=0.) break;
    }
return clamp(d,0.,1.);
}

vec4 m(inout vec3 v,vec3 y,vec3 f,out vec3 d,out bvec2 i)
{
vec4 s=vec4(0.);
d=vec3(0.);
i=bvec2(false,false);
v+=y*f.y;
vec3 z=normalize(vec3(0.,35.,0.)+10.*vec3(cos(x*2.),0.,sin(x*2.))-v);
if(f.z==0.)
 {
 i=bvec2(false,false);
 d=vec3(0.,1.,0.);
 s=.5*vec4(1.,1.,1.,1.);
 s*=max(dot(d,z),0.);
 s+=.2;
 s*=p(v,z,.3,1.);
 float e=.25;
 vec2 n=fwidth(v.xz),a=n*e*2.;
 float w=max(a.x,a.y);
 vec2 t=fract(v.xz*e),l=smoothstep(vec2(.5),a+vec2(.5),t)+(1.-smoothstep(vec2(0.),a,t));
 vec4 E=vec4(.8),N=vec4(.1),o=E*.5+N*.5,r=mix(E,N,l.x*l.y+(1.-l.y)*(1.-l.x));
 r=mix(r,o,smoothstep(.125,.75,w));
 s*=r;
 }
else if(f.z==1.)i=bvec2(false,false),d=-normalize(v),
s=.5*vec4(1.,1.,1.,1.),s*=max(dot(d,z),0.),s*=p(v,z,.3,6.);
else if(f.z==2.)
 {i=bvec2(true,true);
 vec2 a=vec2(.1,0.);
 d=normalize(vec3(m(v+a.xyy)-m(v-a.xyy),m(v+a.yxy)-m(v-a.yxy),m(v+a.yyx)-m(v-a.yyx)));
 s=vec4(1.);
 s*=.5*max(dot(d,z),0.);
 s+=2.*pow(max(dot(reflect(z,d),y),0.),16.);
 }
return s;
}

float n(vec3 v,vec3 y)
{
return R0+(1.-R0)*pow(1.-abs(dot(y,v)),4.);
}

void main(void)
{
d = resolution.xy;    
vec3 x=vec3(0.,5.,80.),
f=normalize(vec3(0.,0.,0.)-x),
y=normalize(vec3(0.,1.,0.)),
s=cross(f,y),
i=vec3(0.,0.,0.),
z=normalize(vec3(vec2(d.x/d.y,1.)*(gl_FragCoord.xy/d-.5),16.));
i+=x;

z*=transpose(mat3(s,y,f));

vec3 a=t(i,z);
if(a.x==0.)
 {
 glFragColor=vec4(1.,1.,1.,1.);
 return;
 }
vec3 e;
bvec2 w;
vec4 r=m(i,z,a,e,w),p=mix(exp(-a.y*vec4(2.,.5,.3,1.)),vec4(1.),sign(a.x)*.5+.5);
vec3 E=i,l=z,o=a,b=e;
bvec2 c=w;
float k=1.;    
for(float N=0.;N<3.;++N)
 {
 k*=n(z,e);
 z=reflect(z,e);
 i+=e*a.x;a=t(i,z);
 if(a.x==0.) break;
 r+=m(i,z,a,e,w)*k;
 if(w.x==false)break;    
 }
w=c,e=b,a=o,z=l,i=E;

 k=1.;   
 for(float N=0.;N<6.;++N)
 {
 vec3 A=z;
 p*=1.-n(z,e);
 z=refract(z,e*sign(a.x),mix(ETA,1./ETA,sign(a.x)*.5+.5));
 if(dot(z,z)==0.) z=reflect(A,e),a.x*=-1.;
 i-=e*a.x;
 a=t(i,z);
 if(a.x==0.) break;
 p*=mix(exp(-a.y*1.3*vec4(.1,.3,.5,1.)),vec4(1.),sign(a.x)*.5+.5);
 r+=m(i,z,a,e,w)*p;
 if(w.y==false)break;    
 }
glFragColor = r;
}
