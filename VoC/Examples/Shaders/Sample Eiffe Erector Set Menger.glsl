#version 420

// original https://www.shadertoy.com/view/tldfWN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//erector set menger by eiffie
#define time time
#define rez resolution
vec3 mcol=vec3(0.0);
const float c1=0.0125,c2=0.007;
float axi(vec3 p){p=abs(p);p=max(p,p.yzx);return min(p.x,min(p.y,p.z));}
float box(vec3 p){p=abs(p);return max(abs(p.x),max(abs(p.y),abs(p.z)));}
float ere(vec3 p){p=abs(p);return max(axi(p)-c1,min(p.x,min(p.y,p.z))-0.001);}
float hol(vec3 p){p=abs(mod(p,c2*2.))-c2;return min(length(p.xy),min(length(p.yz),length(p.xz)));}
float tube(vec3 pa, vec3 ba){return length(pa-ba*clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0));} 

float DE(vec3 p){
  float s=1./3.,md=1./(27.*s);//menger sizes
  p+=0.1*abs(mod(p.zxy,2.*md)-md);//make wonky
  float r=box(p)-1.0,d=axi(p)-s,r1=r;//1st menger iter
  vec3 m=floor(p/md);//find what box we are in (k)
  float k=sin(m.x+2.4*sin(m.z))+m.z,tim=time*(2.+7.*fract(k));
  vec3 v=mod(p+.5*md,md)-.5*md;//mod to the box
  vec3 q=vec3(v.x,mod(p.y+k+tim*0.01+sin(tim*4.)*0.003,0.1+0.25*fract(k))-0.2,v.z)-0.02;
  q.xz=0.707*vec2(q.x-q.z,q.x+q.z);//q is the spider, turn 45 deg
  float f=max(length(q)-0.01,-q.z-0.003);//body
  vec3 sq=sign(q);sq.z=-1.;//legs
  f=min(f,tube(q-sq*vec3(0.006,0.007,0.003),sq*vec3(0.002,0.014+q.z*abs(sin(tim+.5*sq.x)),0.014))-0.001);
  if(min(abs(p.x),abs(p.z))<s || max(abs(p.x),abs(p.z))>1.)f=10.;//remove unwanted spiders
  vec3 av=abs(v)-c2;//bolt things (b)
  float b=max(max(length(av)-0.0055,box(av)-0.004),r-c1);
  r=max(ere(v),r);//erector t bars
  p=2.*clamp(p,-s,s)-p;//2nd menger iter
  s*=s;//reduce size of halls
  if(abs(p.x)<s || abs(p.z)<s)f=10.;//remove more spiders
  d=min(d,axi(p)-s);//menger hallways
  r=max(r,-min(d+c2*2.,hol(v)-0.004));//remove holes and halls from t bars
  b=max(b,-d-0.02);//remove unwanted bolts
  f=max(min(f,.1-length(v)),r1);//slow the march down around the spiders (hack)
  mcol+=(r<min(b,f)?vec3(.5):b<f?vec3(-.25)-.25*sin(sign(v)*vec3(k,k+1.,k+2.)):vec3(0.));
  return min(r,min(b,f))*.9;//what did we hit? color it (mcol)
}
float RD; //secret sauce
vec3 normal(vec3 p, float d){//from dr2
  vec2 e=vec2(d,-d);vec4 v=vec4(DE(p+e.xxx),DE(p+e.xyy),DE(p+e.yxy),DE(p+e.yyx));
  RD=8.*abs(d/length(v));//not from dr2
  return normalize(2.*v.yzw+vec3(v.x-v.y-v.z-v.w));
}
vec3 sky(vec3 rd, vec3 L){
  float d=0.4*dot(rd,L)+1.6;
  return vec3(0.6,0.8,1.)*d*max(0.1,rd.y+.2)+rd*.1;
}
float rnd;
void randomize(in vec2 p){rnd=fract(float(time)+sin(dot(p,vec2(13.3145,117.7391)))*42317.7654321);}

float ShadAO(in vec3 ro, in vec3 rd){
 float t=0.001*rnd,s=1.0,d,mn=0.001;
 for(int i=0;i<4;i++){
  d=max(DE(ro+rd*t),mn);
  s=min(s,d/t+t);
  t+=d;
 }
 return s;
}
vec3 scene(vec3 ro, vec3 rd){
  float t=DE(ro)*rnd,tt=t,d,px,s=1.;
  vec3 L=normalize(vec3(ro.x,0.5,ro.z+.4));
  vec3 col=vec3(0);
  for(int j=0;j<2;j++){
    px=s/rez.x;
    for(int i=0;i<50;i++){
      t+=d=DE(ro+rd*t);
      if(t>2.0 || d<px*t)break;
    }
    if(d<px*t){
      mcol=vec3(0.001);
      vec3 so=ro+rd*t;
      vec3 N=normal(so,d);
      vec3 scol=mcol*0.25;
      float dif=0.5+0.5*dot(N,L);
      float vis=clamp(dot(N,-rd),0.05,1.0);
      float fr=0.2*pow(1.-vis,5.0);
      ro=so+rd*DE(so);tt+=t;
      float shad=clamp(1.0-tt*.5,0.,1.)*ShadAO(ro,N)*(s==1.?1.:.5-t);
      rd=reflect(rd,N);
      col+=(abs(scol)*dif+fr*sky(rd,L))*shad*RD;
      if(scol.x<0.)return col;
      t=DE(ro)*(1.-rnd);
      s=5.;
    }
  }
  if(s==1.)col=sky(rd,L);
  return col;
}
mat3 lookat(vec3 fw){fw=normalize(fw);vec3 up=vec3(0,1,0),rt=normalize(cross(up,fw));
  return mat3(rt,cross(fw,rt),fw);
}
void main(void) {
  vec2 U = gl_FragCoord.xy;
  vec2 uv=vec2(U-0.5*rez.xy)/rez.x;
  randomize(U.xy);
  float tim=time*.05;
  vec3 ro=vec3(cos(tim),0.6+sin(tim)*0.25,sin(tim))*0.7;
  tim=mod(time,60.);
  if(tim>50.)ro=vec3(-0.5,.85-(tim-50.)*0.025,-0.5);
  vec3 rd=lookat(ro)*normalize(vec3(uv,1.0));
  glFragColor=vec4(scene(ro,rd),1.0);
}
