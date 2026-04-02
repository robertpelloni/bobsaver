#version 420

// original https://www.shadertoy.com/view/WtfXzM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float mindc=1e7;

vec3 cam(vec3 o,vec3 t,vec2 uv)
{
 vec3 wup=vec3(0.0,1.0,0.0);
 vec3 cf=normalize(t-o);
 vec3 cr=cross(wup,cf);
 vec3 cu=cross(cf,cr);
 vec3 c=o+cf*1.0;
 vec3 i=c+cr*uv.x+cu*uv.y;
 return normalize(i-o);
}

mat2 rot(float a)
{
 return mat2(cos(a),-sin(a),sin(a),cos(a));
}

float box(vec3 p,vec3 o,vec3 s)
{
 p-=o;
 vec3 d=abs(p)-s;
 return length(max(d,0.0))+
  min(max(d.x,max(d.y,d.z)),0.0);
}

float cylinder(vec3 p,vec3 o,vec3 c)
{
  p-=o;
  return length(p.xz-c.xy)-c.z;
}

float block(vec3 p)
{
 float d=1e7;
 
 float b1=box(p,vec3(0,0,0),vec3(0.5));
 d=min(d,b1);
 
 float b5=box(p,vec3(0,0,0),vec3(0.1,2.0,0.1));
 d=min(d,b5);
 
 float b6=box(p,vec3(0,0,0),vec3(2.06,0.1,0.1));
 d=min(d,b6);
 
 return d;
}

float pp(vec3 p)
{
 float d=1e7;
 
 //p.xz=mod(p.xz+7.0,14.0)-7.0;
 p.xz=mod(p.xz+10.0,20.0)-10.0;
 p.y=clamp(p.y,-10.0,10.0);
 p.y=mod(p.y+2.0,4.0)-2.0;
 
 p.z-=4.0;
 for(int i=0;i<7;i++)
 {
  d=min(d,block(p));
  p.x-=2.0;
  p.xz*=rot(6.28/7.0);
  p.x-=2.0;
 }
 return d;
}

float energy(vec3 p)
{
 p.y+=time*20.0;
 //p.xz=mod(p.xz+7.0,14.0)-7.0;
 p.xz=mod(p.xz+10.0,20.0)-10.0;

  float r=p.y*0.5;
  //mat2 m=mat2(cos(r),-sin(r),sin(r),cos(r));
  //p.xz*=m;
  p.x+=sin(r);
  p.z+=cos(r);

 float d=cylinder(p,
                  vec3(0.0,
                       0.0,
                       0.0),
                  vec3(0.1,0.1,0.15));
 mindc=min(mindc,d);
  return d;
}

float scene(vec3 p)
{
 float d=pp(p);
 d=min(d,energy(p));
 return d;
}

vec3 norm(vec3 p)
{
 vec2 e=vec2(0.001,0.0);
 float d=scene(p);
 return normalize(
  vec3(
   d-scene(p-e.xyy),
   d-scene(p-e.yxy),
   d-scene(p-e.yyx)
   ));
}

vec3 pixelColor(vec2 uv)
{
 vec3 o=vec3(sin(time*0.2)*5.0,sin(time*0.7)*7.0,cos(time*0.4)*40.0);
 //o=vec3(20,2,-20);
 vec3 t=vec3(0.0,0.0,0.0);
 vec3 rd=cam(o,t,uv);
 vec3 p;
 float d=0.0;
 float sd=0.0;
 int k=0;
 for(int i=0;i<128;i++)
 {
  k=i;
  p=o+rd*d;
  sd=scene(p);
  if(sd<0.01 || d>30.0)
  {
   break;
  }
  d+=sd;
 }
 if(d>30.0)d=30.0;
 //vec3 n=norm(p);
 float f=1.0-exp(-d*0.007);
 float g=exp(-mindc*0.6);
 if(sd<0.01)
 {
  float cd=energy(p);
  if(cd>0.01)
  {
   cd=exp(-cd*0.5);
   return mix(vec3(cd)*vec3(0.69,0.76,0.87)+vec3(1,1,1)*g,vec3(0),f);
  }
  return vec3(1,1,1);
 }
 //return vec3(0);
 return mix(vec3(1,1,1)*g,vec3(0),f);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.x;

    // Output to screen
    glFragColor = vec4(pixelColor(uv),1.0);
}
