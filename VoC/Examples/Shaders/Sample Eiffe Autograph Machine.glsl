#version 420

// original https://www.shadertoy.com/view/NdXBz7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Autograph Machine by eiffie
#define rez resolution.xy
#define pi 3.14159
mat2 rmat(float a){float ca=cos(a),sa=sin(a);return mat2(ca,sa,-sa,ca);}
float tube(vec3 pa, vec3 ba){return length(pa-ba*clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0));}
vec2 curl(float a1, float a2, float t, float h, float w){
  return vec2(t+sin(a2*pi*2.)*w,(1.-cos(a1*pi*2.))*h*.5+.75);
}
vec2 eiffie(float t){
  float b=t*8.,a=fract(b),a2=a,aa=4.-abs(b-4.),s,h=.125,w=.075;
  b=floor(b);if(b==4.)aa=2.;else if(b==5.)aa=3.;
  s=b;
  if(b>2.){s-=1.;if(b>4.)s-=1.;}
  if(aa<1.){s+=a;
  }else if(aa<2.){w=.04;s+=a;
  }else if(aa<3.){h=.2;
    if(a<.75)s+=a;else{s+=.75;a2=.75;}
  }else{h=-.15;
    if(a<.25){s+=.75;a2=-.25;}
    else {h+=(a-.25)*(a-.25)*0.2;s+=1.-a;a2=-a*a-.1875;if(a>.85){w=-w;s+=.6;}}
  }
  vec2 v=curl(a,a2,s/6.,h,w);
  return v;
}
float getAng(){return abs(mod(0.1*time,2.)-1.);}

float disc(vec3 p, float s){
  float a=atan(p.x,p.y)/(pi*2.);if(a<0.)a+=1.;
  float r=length(p.xy);
  vec3 e=vec3(eiffie(a),0.)-vec3(.5,0.,0.),b=vec3(0);
  b.y=e.y-sqrt(1.-e.x*e.x);
  vec3 f=normalize(cross(b-e,vec3(0,0,1)))*s;
  r-=e.y+f.y*.7-0.05;
  return max(max(r,s>0.?min(.05-p.x,p.y):min(.05+p.x,p.y)),abs(p.z)-.05);
}
float wav(float t){return abs(fract(t)-.5);}
float gear(vec3 p, float r, float f){
  float a=atan(p.x,p.y)/(pi*2.);if(a<0.)a+=1.;
  r=length(p.xy)-r;
  return max(max(r-wav(a*f)*.2,-r-.15),abs(p.z+0.1)-.05);
}
vec3 mcol=vec3(0.0);
float DE(vec3 p){
  vec3 pc=p,ps=p;
  float a=getAng();
  mat2 rmx=rmat(a*pi*2.);
  ps+=vec3(1.,1.,.0);
  ps.xy=ps.xy*rmx;
  pc+=vec3(-1.,1.,.0);
  pc.xy=pc.xy*rmx;
  float dc=disc(pc,-1.),ds=disc(ps,1.);
  vec3 e=vec3(eiffie(a),0.)-vec3(.5,0.,0.),b=vec3(0);
  b.y=e.y-sqrt(1.-e.x*e.x);
  vec3 f=normalize(cross(b-e,vec3(0,0,1)));
  float dt=tube(p-e,b-e);
  dt=min(dt,tube(p-e,b-e+f));
  dt=min(dt,tube(p-e,b-e-f));
  dt-=0.02;
  p.y+=1.75;p.xy=rmat(a*pi*.54)*p.xy;
  float g=gear(p,.87,30.);
  g=min(g,min(gear(pc,.2,8.),gear(ps,.2,8.)));
  float d=min(min(dc,ds),min(dt,min(g,-p.z+.1)));
  
  if(mcol.x>0.){
    vec3 col=vec3(.4,.25,.1);
    vec2 v;
    if(d==ds)v=ps.xy;
    else if(d==dc)v=pc.xy;
    else if(d==dt)v=vec2(1);
    else if(d==g){v=vec2(10.5);col=col.grb;}
    else {v=vec2(10.5);col=col.bgr;}
    mcol+=abs(0.75+.25*sin(dot(v,v+v.yx*.1)*80.))*col;
  }
  return d;
}
vec3 normal(vec3 p, float d){//from dr2
  vec2 e=vec2(d,-d);vec4 v=vec4(DE(p+e.xxx),DE(p+e.xyy),DE(p+e.yxy),DE(p+e.yyx));
  return normalize(2.*v.yzw+vec3(v.x-v.y-v.z-v.w));
}
float rnd;
void randomize(in vec2 p){rnd=fract(float(time)+sin(dot(p,vec2(13.3145,117.7391)))*42317.7654321);}

float ShadAO(in vec3 ro, in vec3 rd){
 float t=0.01*rnd,s=1.0,d,mn=0.01;
 for(int i=0;i<12;i++){
  d=max(DE(ro+rd*t)*1.5,mn);
  s=min(s,4.*d/t+t*0.5);
  t+=d;
 }
 return s;
}
vec3 scene(vec3 ro, vec3 rd){
  float t=DE(ro)*rnd,d,px=1.0/rez.x;
  for(int i=0;i<64;i++){
    t+=d=DE(ro+rd*t);
    if(t>20.0 || d<px*t)break;
  }
  vec3 L=normalize(vec3(0.4,0.025,-0.5));
  vec3 col=vec3(0);
  if(d<px*t*5.0 && t<20.){
    mcol=vec3(0.001);
    vec3 so=ro+rd*t;
    vec3 N=normal(so,d);
    vec3 scol=mcol*0.25;
    if(scol.b>scol.r){
      if(abs(so.x)<.02 && so.y<0. && so.y>-.4)scol=vec3(0.);
      vec3 p=so;
      t=max(abs(p.x)-.6,abs(p.y-.8)-.2);
      if(t<0.){
        d=1.;p.z=0.;
        float a=getAng();t=0.;
        for(int i=0;i<24;i++){
          vec3 v=vec3(eiffie(t),0.);v.x-=.5;
          float b=length(p-v);
          d=min(d,b);
          t+=b*.2;
          if(t>a)break;
        }
        d=smoothstep(0.0,0.025,d);
        scol=vec3(d);
      }
    }
    float dif=0.5+0.5*dot(N,L);
    float shad=ShadAO(so,L);
    col=1.5*scol*dif*shad;
  }
  return col;
}
void main(void) {
  vec2 U=gl_FragCoord.xy;
  vec2 uv=vec2(U-0.5*rez)/rez.x;
  randomize(U.xy);
  vec3 rd=normalize(vec3(uv.xy,1.0));
  vec3 ro=vec3(0,0,-4);
  glFragColor=vec4(scene(ro,rd),1.0);
}
