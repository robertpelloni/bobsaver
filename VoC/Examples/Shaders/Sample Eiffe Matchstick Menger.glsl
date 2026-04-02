#version 420

// original https://www.shadertoy.com/view/Wt3fzH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Matchstick Menger by eiffie
#define time time
#define rez resolution
vec3 mcol=vec3(0.0);
float noyz(vec3 p){p.y-=time*5.;vec3 r=abs(sin(p+sin(p.yzx*2.+sin(p.zxy*3.))));return r.x+r.y+r.z;}
float axi(vec3 p){p=abs(p);return min(max(p.x,p.y),min(max(p.y,p.z),max(p.x,p.z)));}
float box(vec3 p){p=abs(p);return max(abs(p.x),max(abs(p.y),abs(p.z)));}
float smk=0.0;
float DE(vec3 p){
  const float thrd=1./3.;
  float g=max(p.x+p.y+p.z-1.5,0.);
  p+=vec3((0.07+0.007*sin(g*20.0))*sin(g));
  float r=box(p)-1.0,s=thrd,d=axi(p)-s;
  vec3 v=mod(p+1./(54.*s),1./(27.*s))-1./(54.*s);
  float b=max(length(v)-0.01,r-0.01);
  float sm=min(g,max(min(p.x,p.z),max(0.,p.y-1.)));
  sm*=noyz(p*vec3(40.,20.,40.)); 
  r=max(axi(v)-0.005,r);
  p=2.*clamp(p,-s,s)-p;
  s*=thrd;
  d=min(d,axi(p)-s);
  r=max(r,-d-0.005);
  b=max(b,-d-0.02);
  smk+=sm*max(1.-b*10.,0.);
  mcol+=(r<b?vec3(.9,.6,.3):vec3(.9,.3,.1))*max(1.-g,0.);
  d=min(r,b)*(.9-min(g*.2,.2));
  return d;
}
vec3 normal(vec3 p, float d){//from dr2
  vec2 e=vec2(d,-d);vec4 v=vec4(DE(p+e.xxx),DE(p+e.xyy),DE(p+e.yxy),DE(p+e.yyx));
  return normalize(2.*v.yzw+vec3(v.x-v.y-v.z-v.w));
}
vec3 sky(vec3 rd, vec3 L){
  float d=0.4*dot(rd,L)+1.6;
  return vec3(0.6,0.8,1.)*d*max(0.1,rd.y+.2);
}
float rnd;
void randomize(in vec2 p){rnd=fract(float(time)+sin(dot(p,vec2(13.3145,117.7391)))*42317.7654321);}

float ShadAO(in vec3 ro, in vec3 rd){
 float t=0.01*rnd,s=1.0,d,mn=0.01;
 for(int i=0;i<12;i++){
  d=max(DE(ro+rd*t)*1.5,mn);
  s=min(s,d/t+t*0.5);
  t+=d;
 }
 return s;
}
vec3 scene(vec3 ro, vec3 rd){
  float t=DE(ro)*rnd,d,px=1.0/rez.x;
  for(int i=0;i<64;i++){
    t+=d=DE(ro+rd*t);
    if(t>10.0 || d<px*t)break;
  }
  vec3 L=normalize(vec3(ro.x,0.5,ro.z+.4));
  vec3 col=sky(rd,L);
  if(d<px*t*5.0){
    mcol=vec3(0.001);
    vec3 so=ro+rd*t;
    vec3 N=normal(so,d);
    vec3 scol=mcol*0.25;
    float dif=0.5+0.5*dot(N,L);
    float vis=clamp(dot(N,-rd),0.05,1.0);
    float fr=0.2*pow(1.-vis,5.0);
    float shad=ShadAO(so,L);
    col=(scol*dif+fr*sky(reflect(rd,N),L))*shad;
  }
  return col+smk*0.01*vec3(0.9,1.,0.7);
}
mat3 lookat(vec3 fw){fw=normalize(fw);vec3 up=vec3(0,1,0),rt=normalize(cross(up,fw));
  return mat3(rt,cross(fw,rt),fw);
}
void main(void) {
  vec2 uv=vec2(gl_FragCoord.xy-0.5*rez.xy)/rez.x;
  randomize(gl_FragCoord.xy);
  float tim=-3.+time*0.25;
  vec3 ro=vec3(cos(tim),0.5+tim*0.25,sin(tim))*(2.-tim*.25);
  vec3 rd=lookat(-ro)*normalize(vec3(uv,1.0));
  vec4 O=vec4(scene(ro,rd),1.0);
  O*=max(0.,1.-0.3*pow(abs(tim),2.));
  glFragColor=O;
}
