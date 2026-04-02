#version 420

// original https://www.shadertoy.com/view/7ljcWV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Winning shader made at Revision 2022 Shader Showdown Quarter-final

// This shader was coded live on stage in 25 minutes. Designed beforehand in several hours.

// "Christian Fitness Shrine" because I was listening to "Christian Fitness" UK band while preparing for the showdown. One of the best UK bands at the moment imo.
// https://christianfitness.bandcamp.com/album/hip-gone-gunslingers

vec2 z,v,e=vec2(.00035,-.00035);float t,tt,g,r,a,bb;vec3 op,pp,po,no,al,ld,lp;vec4 kp;
float smin(float a,float b,float k){ float h=max(0.,k-abs(a-b)); return min(a,b)-h*h*.25/k;}
float smax(float a,float b,float k){ float h=max(0.,k-abs(-a-b)); return max(-a,b)+h*h*.25/k;}
mat2 r2(float r){return mat2(cos(r),sin(r),-sin(r),cos(r));}
vec2 mp( vec3 p,float ga)
{
  op=p;bb=1.-(sin((p.z+tt*4.)*0.064)*.5+.5);
  p.x=abs(p.x)-bb*15.;
  p.xy*=r2(1.57*bb);
  p.z=mod(p.z+tt*4.,50.)-25.;
  pp=p; pp.xz=abs(pp.xz)-7.3;
  vec2 h,d,t=vec2(length(pp)-2.5,0);  // balls
  t.x=smin(t.x,length(pp-1.6)-.6,.5); // BUBBLE    
  t.x=smax(length(pp-1.7)-.3,t.x,.5); // bubble hole
  h=vec2(length(pp-1.5)-.5,2); //bubble light
  kp=vec4(p-vec3(0,4.63,0),1); //kp
  r=1.;                             //r
  for(int i=0;i<4;i++){    //greeble greeble bro bro         
      kp.xz=abs(kp.xz)-.4;
      kp.xz*=r2(.785*mod(float(i),2.));
      kp*=2.3;      
      r=min(r,clamp(abs(cos(kp.y*.3)*abs(cos(kp.z*.3)*3.)-.5)-.5,-.25,.25)/kp.w);
    }
  t.x=smin(t.x,p.y+1.+sin(length(p.xz)-tt*2.)*0.5,1.5); //TERRAIN 
  t.x=min(t.x,length(p.yz-vec2(8,0))-.1-r); //Bridge
  a=max(length(p.xz)-8.+r+p.y*.75,-(length(p.xz)-2.)); //PYRA
  t.x=smin(t.x,a,1.5); //add pyra
  t.x=max(t.x,-(abs(abs(p.y-4.)-1.)-.2-r)); //blue cut
  a+=.2;  //push pyra
  h.x=min(h.x,a);  //add pyra to glo
  pp+=cos(p.y*.5); //deform
  h.x=min(h.x,length(pp.xy-vec2(0,9)));; //lazers
  g+=0.1/(0.1+h.x*h.x*(50.-45.*sin(op.z*.2+tt*2.)))*ga; //glow
  t=t.x<h.x?t:h; //add t and h
  pp.xz=abs(pp.xz)-.3; //spread out lines
  h=vec2(length(pp.xz)-.1+r*.3,1); //BLACK LINES VERTICAL
  pp.y=abs(pp.y-6.)-2.;
  h.x=smin(h.x,length(pp.xy-vec2(0,1))-.1+r,1.5);  
  pp=p;pp.y=abs(abs(p.y-5.)-1.)-.5-r;
  h.x=smin(h.x,max(a-.5,pp.y),2.);
  a=max(abs(length(p.xz)-16.+r)-.6,abs(p.y+r)-1.5); //BLACK CYLINDER
  h.x=smin(h.x,a,1.5);
  h.x=smin(h.x,(length(p.xy)-1.+r),1.5);   //FLOOR CYLINDER BLACK
  t=t.x<h.x?t:h;
  t.x*=0.6;
  return t;
}
vec2 tr( vec3 ro,vec3 rd)
{
  vec2 h,t=vec2(.1);
  for(int i=0;i<128;i++){
    h=mp(ro+rd*t.x,1.);
    if(h.x<.0001||t.x>70.) break;
    t.x+=h.x;t.y=h.y;
  }
  if(t.x>70.) t.y=-1.;
    return t;
}
#define a(d) clamp(mp(po+no*d,0.).x,0.,1.)
#define s(d) smoothstep(0.,1.,mp(po+ld*d,0.).x)
void main(void) {
vec2 uv=(gl_FragCoord.xy/resolution.xy-0.5)/vec2(resolution.y/resolution.x,1);   
tt=mod(time,75.); 
  vec3 ro=vec3(cos(tt*.1)*13.,13.-sin(tt*.4)*8.,-10),
  cw=normalize(vec3(0,0,0)-ro),
  cu=normalize(cross(cw,vec3(0,1,0))),
  cv=normalize(cross(cu,cw)),
  rd=mat3(cu,cv,cw)*normalize(vec3(uv,.5)),co,fo;
  co=fo=clamp(vec3(.17,.15,.14)-length(uv)*.15-rd.y*.1,0.,1.);
  z=tr(ro,rd);t=z.x;
  if(z.y>-1.){
    po=ro+rd*t;
    no=normalize(e.xyy*mp(po+e.xyy,0.).x+e.yyx*mp(po+e.yyx,0.).x+e.yxy*mp(po+e.yxy,0.).x+e.xxx*mp(po+e.xxx,0.).x);
    ld=normalize(ro-po);
    al=clamp(mix(vec3(.3,.4,.7)-r*15.,vec3(0.1)-r*15.,z.y*1.3),0.,1.);    
    if(z.y>1.) al=vec3(1);
    float dif=max(0.,dot(no,ld)),
    fr=pow(1.+dot(no,rd),4.),
    sp=pow(max(dot(reflect(-ld,no),-rd),0.),40.);    
    co=mix(sp+al*(a(.1)*a(.5)+.4)*(dif+s(2.0)),fo,min(fr,.5));
    co=mix(fo,co,exp(-.00002*t*t*t));
  }
  co+=g*.2*vec3(.9,.5,.1);  
  co=mix(co,co.xzy,length(uv)*.5);
  glFragColor = vec4(pow(co,vec3(.45)),1);
}
