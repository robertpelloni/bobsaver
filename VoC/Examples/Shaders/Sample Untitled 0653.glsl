#version 420

// original https://www.shadertoy.com/view/NddXWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))

vec2 pmod(vec2 p,float n){
  float a=atan(p.x,p.y)+PI/n;
  float num=2.0*PI/n;
  a=floor(a/num)*num;
  return rot(-a)*p;
}

float c(vec3 p,vec3 s){
  return length(max(abs(p)-s,0.));
}

vec3 trs(vec3 p){
  vec3 pos=p;
  pos.z-=time*3.;
  float k=8.;
  pos=mod(pos,k)-k*.5;

 pos.xy=pmod(pos.xy,6.);
 pos.yz=pmod(pos.yz,5.);

pos.xz=pmod(pos.xz,12.);
  pos=abs(pos)-.15;
  pos.z=abs(pos.z)-.12;
  pos.z=abs(pos.z)-.182;

  return pos;
}

float m1m(vec3 p){
  //rotation/////////////
    // p.xz*=rot(time*0.1);
  // TRS////////////////////////
   p=trs(p);

  p=abs(p);
   vec3 o=p*1.5;
  float s=1.;

  
  for(int i=0;i<5;i++){

    if(p.x<p.y)p.xy=p.yx;
    if(p.x<p.z)p.xz=p.zx;
    if(p.y<p.z)p.yz=p.zy;

    p.xy=pmod(p.xy,3.0*.25);
    p.yz=pmod(p.yz,6.*.8);
  p.xz=pmod(p.xz,4.*.85);

     float r=0.55*clamp(5.38*max(dot(p,p)*3.2,5.01),.1,.98)*9.;

     s*=r;
     p*=r;
     p=abs(p)-o;

     p=abs(p)-0.5;
     p.z=abs(p.z)-0.92;
     p.x=abs(p.x)-0.45;
    p.z-=0.12;
    p.z-=0.8;
    p=abs(p)-0.5;
     p.xz=pmod(p.xz,12.);
     p.xy=pmod(p.xy,6.);

     p=abs(p)-0.15;
     p.y=abs(p.y)-.6;

     p.xy*=rot(0.23);
     p.yz*=rot(0.74);
     p.xz*=rot(0.623);

     p.z-=0.3;
     p.z-=0.1;
     p.z=abs(p.z)-0.5;

    p=abs(p)-0.25;

    if(p.x<p.y)p.xy=p.yx;
    if(p.x<p.z)p.xz=p.zx;
    if(p.y<p.z)p.yz=p.zy;

  }
  p/=s;

p.xz=pmod(p.xz,12.);
p.z=abs(p.z)-.45;
p.z=abs(p.z)-0.12;
p.xy=pmod(p.xy,2.);
p.z=abs(p.z)-0.231;
p.xy=pmod(p.xy,3.);

  float m=c(p,vec3(1.,1.,.3));
  return m;
}

float map(vec3 p){
  
  float m1=m1m(p);
  return m1;
}

vec3 gn(vec3 p){
  vec2 e=vec2(0.001,0.);
  return normalize(vec3(
    map(p+e.xyy)-map(p-e.xyy),
    map(p+e.yxy)-map(p-e.yxy),
    map(p+e.yyx)-map(p-e.yyx)
    ));
}

void main(void)
{
  vec2 st=(gl_FragCoord.xy*2.-resolution.xy)/min(resolution.x,resolution.y);
st*=rot(time);
 float radius=0.1;
   float phi=time*0.2;
   
  // vec3 ro=vec3(0.0,0.0,1.0);
   vec3 ro=vec3(radius*cos(phi),0.0,radius*sin(phi));
   //vec3 rd=normalize(vec3(uv.xy,-3.0));
   vec3 ta=vec3(0.0,0.0,0.0);
   
   vec3 cDir=normalize(ta-ro);
   vec3 side=cross(cDir,vec3(0.0,1.0,0.0));
   vec3 up=cross(cDir,side);
   float fov=0.6;
   
   vec3 rd=normalize(vec3(st.x*side+st.y*up+cDir*fov));

  float d,t,acc=0.;
  for(int i=0;i<128;i++){
    d=map(ro+rd*t);
    // d=min(d,.5);
     d=min(abs(d),.2);
    if(abs(d)<0.001||t>1000.0)break;
    t+=d;
    acc+=exp(-6.*d);
  }

/*
vec3 n=gn(ro+rd*t);
  float acc2=0.0;
t=0.1;
vec3 refro=ro+rd*t;
rd=reflect(rd,n);
ro=refro;

for(int i=0;i<64;i++){
  d=map(ro+rd*t);
 //  d=min(abs(d),.5);
  if(d<0.001||t>1000.0)break;
  t+=d;
  acc2+=exp(-6.*d);
}*/

  vec3 col=vec3(.9,.8,.7)*acc*0.025;//+vec3(1.,0.25,0.5)*acc2*0.025;
 

  glFragColor=vec4(col,1);
}
