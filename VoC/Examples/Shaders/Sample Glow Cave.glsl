#version 420

// original https://www.shadertoy.com/view/ssycDc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time time
#define resolution resolution

#define PI 3.14159265
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))

vec2 pmod(vec2 p,float n){
  float a=atan(p.x,p.y)+PI/n;
  float num=2.0*PI/n;
  a=floor(a/num)*num;
  return rot(-a)*p;
}

float Torus(vec3 p,vec2 size)
{
    return length(vec2(length(p.xy)-size.x,p.z))-size.y;
}

float Box(vec3 p,vec3 size)
{
    return length(max(abs(p)-size,0.0));
}

float flower(vec3 p)
{
    p.xy*=rot(time);
    p.xz*=rot(time);
    p.yz*=rot(time);

    vec3 pos=p*1.25;
    float r=floor(time)+pow(fract(time),.1);
    r*=0.75;
    //float r=3.75;
    pos=abs(pos);
    for(int i=0;i<6;i++)
    {
        pos=abs(pos)-0.01;
        if(pos.x<pos.y)pos.xy=pos.yx;
        if(pos.x<pos.z)pos.xz=pos.zx;
        if(pos.y<pos.z)pos.yz=pos.zy;
        pos-=0.01;
        
        pos.xy*=rot(r);
        pos.xz*=rot(r);
        pos.yz*=rot(r);
        pos-=0.01;
        
        //pos.yz*=rot(PI/3.);
    }

    return Box(pos,vec3(0.1,0.1,4.0));
    
}

float c(vec3 p,vec3 s){
  return length(max(abs(p)-s,0.));
}

vec3 trs(vec3 p){
  vec3 pos=p;
  pos.z-=time*6.;
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

float map(vec3 p,out float m1,out float m2){
  
  m1=m1m(p);
  m2=flower(p);
  return min(m1,m2);
}

vec3 gn(vec3 p){
  vec2 e=vec2(0.001,0.);
  float num1=0.0,num2=0.0;
  
  return normalize(vec3(
    map(p+e.xyy,num1,num2)-map(p-e.xyy,num1,num2),
    map(p+e.yxy,num1,num2)-map(p-e.yxy,num1,num2),
    map(p+e.yyx,num1,num2)-map(p-e.yyx,num1,num2)
    ));
}

vec3 hsv2rgb2(vec3 c, float k) {
    return smoothstep(0. + k, 1. - k,
        .5 + .5 * cos((vec3(c.x, c.x, c.x) + vec3(3., 2., 1.) / 3.) * radians(360.)));
}

void main(void)
{
  vec2 st=(gl_FragCoord.xy*2.-resolution.xy)/min(resolution.x,resolution.y);
st*=rot(time*0.5);
 float radius=0.5+(sin(time*0.5)+1.0)*0.5;
   float phi=time;
   
  // vec3 ro=vec3(0.0,0.0,1.0);
   vec3 ro=vec3(radius*cos(phi),radius*sin(phi),1.0);
   //vec3 rd=normalize(vec3(uv.xy,-3.0));
   vec3 ta=vec3(0.0,0.0,0.0);
   
   vec3 cDir=normalize(ta-ro);
   vec3 side=cross(cDir,vec3(0.0,1.0,0.0));
   vec3 up=cross(cDir,side);
   float fov=1.0;
   
   vec3 rd=normalize(vec3(st.x*side+st.y*up+cDir*fov));

  float d,t,acc=0.,pi=0.0,m1=0.0,m2=0.0;
  for(int i=0;i<128;i++){
    d=map(ro+rd*t,m1,m2);
    // d=min(d,.5);
     d=min(abs(d),.2);
     pi=float(i);
    if(abs(d)<0.001||t>1000.0)break;
    t+=d;
    acc+=exp(-6.*d);
  }

vec3 n=gn(ro+rd*t);
  float acc2=0.0;
t=0.1;
vec3 refro=ro+rd*t;
rd=reflect(rd,n);
ro=refro;

float num1=0.0,num2=0.0;
for(int i=0;i<64;i++){
  d=map(ro+rd*t,num1,num2);
 //  d=min(abs(d),.5);
  if(d<0.001||t>1000.0)break;
  t+=d;
  acc2+=exp(-6.*d);
}
  vec3 col=vec3(0.0);

  if(m1<0.001)
  {
      vec3 p=ro+rd*t;
      float flash =1.0- abs(sin(p.z*0.1+time*4.0));
      flash += .15;
      flash = clamp(flash,0.0, 1.0);
      float H = mod(time*0.1, 1.0);
      col=vec3(.9,.8,.7)*10./pi+hsv2rgb2(vec3(H,1.0,1.0),2.2)*acc2*0.015*flash;
  }
  else if(m2<0.001)
  {
      vec3 p=ro+rd*t;
      float flash =1.0- abs(sin(p.z*0.1+time*4.0));
      flash += .15;
      flash = clamp(flash,0.0, 1.0);
      float H = mod(time*0.1, 1.0);
      col=vec3(.9,.8,.7)*5./pi+hsv2rgb2(vec3(H,1.0,1.0),2.2)*acc2*0.2*flash;
  }

  glFragColor=vec4(col,1);
}
