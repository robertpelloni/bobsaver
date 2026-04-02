#version 420

// original https://www.shadertoy.com/view/sdy3Dd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))

float cube(vec3 p,vec3 s){
  return length(max(abs(p)-s,0.));
}

vec2 fmod(vec2 p,float r){
  float a=atan(p.x,p.y)+PI/r;
  float n=(2.*PI)/r;
  a=floor(a/n)*n;
  return rot(a)*p;
}

float m1(vec3 p){
 p.xz*=rot(time);

for(int i=0;i<5;i++){
  p=abs(p)-0.5;
  if(p.x<p.y)p.xy=p.yx;
  if(p.x<p.z)p.xz=p.zx;
  if(p.y<p.z)p.yz=p.zy;

  p.xy=fmod(p.xy,24.0);
 p.x-=abs(p.x)-0.5;
 p.y=abs(p.y)-0.15;

 float t=floor(time*0.25)+pow(fract(time*0.25),.5);
  p.xy*=rot(t+0.123);
  p.yz*=rot(time+0.456);
   p.xz*=rot(time+.789)*1.025;

 p.z-abs(p.z)-0.45;

}

p.yz=fmod(p.yz,12.0);
p.xz=fmod(p.xz,6.0);

  float m=cube(p,vec3(.5,3.,2.));

  return m;
}

float map(vec3 p){

 p.z-=time*20.;

   float t=floor(time*2.0)+pow(fract(time*2.0),.75);
p.xy*=rot(t);

  p.xy=fmod(p.xy,12.0);
float k=10.5;
p=mod(p,k)-k*0.5;

  float m=m1(p);

  return m;
}

vec3 gn(vec3 p){
  vec2 t=vec2(0.001,0.0);
  return normalize(
      vec3(
        map(p+t.xyy)-map(p-t.xyy),
        map(p+t.yxy)-map(p-t.yxy),
        map(p+t.yyx)-map(p-t.yyx)
        )
    );
}

void main(void)
{
    
    vec2 st=(gl_FragCoord.xy*2.0-resolution.xy)/min(resolution.x,resolution.y);

      vec3 ro=vec3(0,0,10.0);
      vec3 rd=vec3(st,-1.0);

      vec3 col=vec3(0,0,0);
      float d,t,acc=0.0;

      for(int i=0;i<64;i++){
        d=map(ro+rd*t);
        if(d<0.001||t>1000.0)break;
        t+=d;
        acc+=exp(-3.0*d);
      }

    vec3 refo=ro+rd*t;
     vec3 n=gn(refo);
    rd=reflect(refo,n);
    ro=refo;
    t=0.1;
    float acc2=0.;

    for(int i=0;i<32;i++){
      d=map(ro+rd*t);
      if(d<0.001||t>1000.0){
        t+=d;
        acc2=exp(-3.0*d);
      }

    }

    col=vec3(1.,0.5,1.)*acc*0.1;
    col+=vec3(0.,.5,1.)*acc2*0.075;
    glFragColor = vec4(col,1.0);
}
