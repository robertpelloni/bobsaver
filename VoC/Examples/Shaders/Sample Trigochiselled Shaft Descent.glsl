#version 420

// original https://www.shadertoy.com/view/NdfGDl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Trigochiselled shaft descent - Result of an improvised live coding session on Twitch
// LIVE SHADER CODING, SHADER SHOWDOWN STYLE, EVERY TUESDAYS 20:00 Uk time: 
// https://www.twitch.tv/evvvvil_

// "You've always been the same, even at school. Nothing but books, learning, education...
// - that's why you're no good at snooker." - Del Boy

vec2 z,v,vv,e=vec2(.00035,-.00035);float tt,b,bb,g=0.,gg=0.,tnoi,res=1.;vec3 bp,pp,rd,fo,lp,po,op,no,al,ld,vcp;
float bo(vec3 p,vec3 r){p=abs(p)-r;return max(max(p.x,p.y),p.z);}
mat2 r2(float r){return mat2(cos(r),sin(r),-sin(r),cos(r));}
float smin(float a,float b,float k){float h=max(k-abs(a-b),0.);return min(a,b)-h*h*.25/k;}
float smax(float a,float b,float k){float h=max(k-abs(-a-b),0.);return max(-a,b)+h*h*.25/k;}
//vec4 texNoise(vec2 uv,sampler2D tex ){ float f = 0.; f+=texture(tex, uv*.125).r*.5; f+=texture(tex,uv*.25).r*.25;
//                       f+=texture(tex,uv*.5).r*.125; f+=texture(tex,uv*1.).r*.125; f=pow(f,1.2);return vec4(f*.45+.05);}
vec2 mp( vec3 p )
{
  op=p;p.y=mod(p.y-tt*2.,20.)-10.;  
  vec2 h,t=vec2(bo(p,vec3(3,20,3)),6); //white box
  vec3 cp=p+vec3(0.,0.0,.3);  
  t.x=max(t.x,-(length(cp.xz)-3.0)); //inner white cylinder
  h=vec2(bo(p,vec3(3.05,20,3.05)),3); //black box  
  h.x=max(h.x,-(length(cp.xz)-3.0));
  t.x=abs(abs(t.x)-.5)-.2; //onion 
  h.x=abs(abs(h.x)-.5)-.3;
  vcp=p; //cut position
  vcp.y=abs(abs(abs(p.y)-10.)-4.)-2.;  //first horizontal cut  
  t.x=max(t.x,min(vcp.y,p.z+1.2)); 
  h.x=max(h.x,min(vcp.y+.2,p.z+1.4)); 
  vcp.yz*=r2(0.785);
  t.x=max(t.x,-(abs(abs(vcp.y+1.)-.4)-.1)); 
  t.x=max(t.x,vcp.y-1.5);  
  h.x=max(h.x,-(abs(abs(vcp.y+1.)-.4)-.3)); 
  h.x=max(h.x,vcp.y-1.3); 
  bp=op+vec3(0.,bb,.3);  
  float glo=length(abs(bp)-vec3(0,2.,0.))-.5;   //platform
  t.x=min(t.x,max(length(abs(bp.xz)-.75)-.1,abs(bp.y)-1.));  
  float glo2=max(abs(length(bp.xz)-1.)-.5,abs(abs(bp.y)-1.5)-.2);
  glo=min(glo,glo2);
  g+=0.1/(0.1+glo*glo*40.);
  t.x=min(t.x,glo);  
  t=t.x<h.x?t:h;   
  h=vec2(length(abs(p.xz)-3.)-0.15,7);  //shaft edge cylinders
  h.x=min(h.x,max(abs(length(bp.xz)-1.)-.4,abs(abs(bp.y)-1.5)-.5));  
  t=t.x<h.x?t:h;    
  vec3 mop=op+vec3(0,-tt*2.,0);
  tnoi=0.0;//texNoise(mop.xy*.06,iChannel0).r*1.2;
  vec3 tp=op-vec3(0,0,12);  
  b=sin(op.y-tt*2.)+sin(op.x*.5);  
  h=vec2(abs(length(tp.xz)-22.+tnoi+b)-.2,5);  //main tunnel cylinder    
  h.x=max(abs(h.x)-2.,abs(p.y)-100.);    
  vec3 prp=vec3(atan(tp.x,tp.z)*3.142*5.,op.y-tt*2.,length(tp.xz)-19.5+b); //projected position
  prp.xy=mod(prp.xy,5.)-2.5;
  h.x=smin(h.x,length(prp.yz)-1.-sin(mop.x)*.3+tnoi,1.2) ;
  h.x=smin(h.x,length(abs(prp.yz)-vec2(1.,0))-.1-sin(prp.x*10.0)*.1-tnoi,.5) ;  
  float tun=h.x+1.;
  h.x=smax((abs(prp.y)-.1),h.x,.5);
  pp=op+vec3(0,0,-13);pp.xz=abs(pp.xz)-15.+b;
  h.x=smin(h.x,length(pp.xz)-2.0-sin(mop.y*.5),3.); //edges bits    
  tun=abs(tun)-.2; 
  tun=max(tun,abs(p.y)-100.);
  g+=0.1/(0.1+tun*tun*4.);
  h.x=min(h.x,tun);h.x*=0.6;
  t=t.x<h.x?t:h;
  return t;
}
vec2 tr( vec3 ro,vec3 rd)
{
  vec2 h,t=vec2(.1);
  for(int i=0;i<128;i++){
    h=mp(ro+rd*t.x);
    if(h.x<.0001||t.x>65.) break;
    t.x+=h.x;t.y=h.y;
  }
  if(t.x>65.) t.y=0.;
    return t;
}
#define a(d) clamp(mp(po+no*d).x/d,0.,1.)
#define s(d) smoothstep(0.,1.,mp(po+ld*d).x/d)
vec3 lit(float da,float atn){    
    ld=normalize(lp-po);
    float dif=da*max(0.,dot(no,ld)),
    fr=pow(1.+dot(no,ld),4.),
    sp=pow(max(dot(reflect(-ld,no),-rd),0.),40.),
    attn=1.-pow(min(1.,length(lp-po)/atn),4.0); 
    return attn*mix(sp+al*(a(.1)+.2)*(dif+s(.5)),fo,min(fr,.5)); 
}
void main(void)
{
  vec2 vv,uv = vec2(gl_FragCoord.xy.x / resolution.x, gl_FragCoord.xy.y / resolution.y);
  vv=uv;uv-=0.5;vv*=1.-vv;uv/=vec2(resolution.y/resolution.x,1);
  tt=mod(time,62.83)+23.6;
  bb=-40.+smoothstep(0.,1.,smoothstep(0.,1.,sin(tt*.2)*.5+.5))*80.;
  b=ceil(cos(tt*.2));
  vec3 ro=mix(vec3(-9.,00,6.+sin(tt*.2)*4.),vec3(sin(tt*.2)*12.,-bb-sin(bb*.05)*10.,5.0),b),
  cw=normalize(vec3(0.,mix(-bb*.2,-bb,b),1)-ro),
  cu=normalize(cross(cw,vec3(0,1,0))),cv=normalize(cross(cu,cw)),co;
  rd=mat3(cu,cv,cw)*normalize(vec3(uv,.55));
  co=fo=vec3(.1);
  z=tr(ro,rd);
  if(z.y>0.){
    po=ro+rd*z.x;
    no=normalize(e.xyy*mp(po+e.xyy).x+e.yyx*mp(po+e.yyx).x+e.yxy*mp(po+e.yxy).x+e.xxx*mp(po+e.xxx).x);    
    al=mix(vec3(.5,.4,.3),vec3(.2,.2,.2),tnoi*5.0);
    if(z.y<5.) {
      v=vcp.yz; 
      for(int i=0;i<4;i++){
        v=abs(v)-.3;
        v*=r2(-.785); v*=1.22;
        float per=abs(sin(v.x))-.1+clamp(sin(v.y*2.),-.1,.1)*.5;
        res=min(res,ceil(per));
        g+=.25/(0.1+(per*per)*(20.-18.9*sin(uv.y*1.5+tt*2.)));  
      }
      al=vec3(1.-res);
    }
    if(z.y>5.) al=vec3(0.4,.5,.7);
    if(z.y>6.) al=vec3(0.);
    lp=vec3(0,-bb,0);    
    co=lit(3.,10.);    
    lp=ro;
    co+=.75*lit(2.,15.);      
    co=mix(fo,co,exp(-.00003*z.x*z.x*z.x));    
  }  
  co=mix(co+g*.2*vec3(.1,.2,.7),fo,min(1.,length(ro.y-op.y)*.02));      
  glFragColor = vec4(pow(co*pow(vv.x*vv.y*15.0,0.25),vec3(.65)),1);
}
