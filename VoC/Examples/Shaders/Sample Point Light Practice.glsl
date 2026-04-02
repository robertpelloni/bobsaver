#version 420

// original https://www.shadertoy.com/view/NtKSRV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define hash(x) fract(sin(x)*1e3)

float pi2=acos(-1.)*2.;

float hash12(vec2 p){
  float s=dot(p,vec2(1.6523,1.2452));
  return hash(s);
}

vec3 rot3d(vec3 v,float a,vec3 ax){
  ax=normalize(ax);
  return cos(a)*v+(1.-cos(a))*dot(ax,v)*ax-sin(a)*cross(ax,v);
}

float map(vec3 p){
  float d;
  
  d=p.y;
  vec3 q=p;
  q.zx=mod(q.zx,4.)-2.;
  d=min(d,length(q-vec3(0,1,0))-1.);
  
  return d;
}

vec3 calcN(vec3 p){
  vec2 e=vec2(1e-3,0);
  return normalize(vec3(map(p+e.xyy)-map(p-e.xyy),
  map(p+e.yxy)-map(p-e.yxy),
  map(p+e.yyx)-map(p-e.yyx)));
}

float shadow(vec3 rp,vec3 rd){
  float d,h=.001,res=1.,c=0.2;
  for(int i=0;i<50;i++){
    vec3 p=rp+rd*h;
    if(p.y>4.)break;
    d=map(p);
    if(d<.001)return c;
    res=min(res,16.*d/h);
    h+=d;
  }
  return mix(c,1.,res);
}

float calcAO(vec3 rp,vec3 rd){
  float ao,s=1.,i,h,d;
  for(float i=0.;i<20.;i++){
    h=.01+.02*i*i;
    d=map(rp+rd*h);
    ao+=s*clamp(h-d,0.,1.);
    s*=.75;
  }
  return 1.-clamp(.5*ao,0.,1.);
}

vec3 hsv(float h,float s,float v){
  return ((clamp(abs(fract(h+vec3(0,2,1)/3.)*6.-3.)-1.,0.,1.)-1.)*s+1.)*v;
}

vec3 getC(vec3 p){
  vec3 col=vec3(0);
  if(p.y>.01){
    col+=hsv(hash12(ceil(p.zx/4.)),.7,1.);
  } else {
    p*=pi2/8.;
    col+=step(sin(p.z)*sin(p.x),0.)*.95+.05;
  }
  return col;
}

float fs(float f0,float c){
  return f0+(1.-f0)*pow(1.-c,5.);
}

vec3 march(inout vec3 rp,inout vec3 rd,inout bool hit,inout vec3 ra,vec3 cp){
  vec3 col=vec3(0);
  float d;
  hit=false;
  
  vec3 rp0=rp;
  for(int i=0;i<100;i++){
    d=map(rp);
    if(abs(d)<1e-4||length(rp0-rp)>100.){
      hit=true;
      break;
    }
    rp+=rd*d;
  }
  
  vec3 lv=vec3(cp.x*.7,4,cp.z*.3)-rp;
  vec3 ld=normalize(lv);
  float lp=5000./dot(lv,lv);
  vec3 n=calcN(rp);
  vec3 al=getC(rp);
  vec3 ref=reflect(rd,n);
  float m=.95;
  
  float diff=max(dot(ld,n),0.);
  float spec=pow(max(dot(reflect(ld,n),rd),0.),20.);
  float sh=shadow(rp+.001*n,ld);
  float ao=calcAO(rp+.001*n,n);
  
  col+=al*diff*sh*(1.-m)*lp;
  col+=al*spec*sh*m*lp;
  col+=al*ao*.1;
  
  float fog=exp(-dot(rp-rp0,rp-rp0)*.0005);
  col=mix(vec3(0),col,fog);
  
  col*=ra;
  
  ra*=al*fs(.8,dot(ref,n))*fog;
  
  rp+=.001*n;
  rd=ref;
  
  return col;
}
 
vec3 rh(vec3 col,float l){
  return col/(1.+col)*(1.+col/l/l);
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.xy.x / resolution.x, gl_FragCoord.xy.y / resolution.y);
  uv -= 0.5;
  uv /= vec2(resolution.y / resolution.x, 1)*.5;
  vec3 col=vec3(0);
  
  vec3 cp=vec3(0,9,15)*(2.+sin(time*.2)*.5);
  cp=rot3d(cp,time*.2,vec3(0,1,0));
  vec3 rd=normalize(vec3(uv,-2));
  rd=rot3d(rd,1.,vec3(1,0,0));
  rd=rot3d(rd,time*.2,vec3(0,1,0));
  
  vec3 rp=cp;
  bool hit=false;
  vec3 ra=vec3(1);
  
  col+=march(rp,rd,hit,ra,cp);
  if(hit)col+=march(rp,rd,hit,ra,cp);
  if(hit)col+=march(rp,rd,hit,ra,cp);
  
  col=rh(col,8.);
  col=pow(col,vec3(1./2.2));
  
  glFragColor = vec4(col,1.);
}
