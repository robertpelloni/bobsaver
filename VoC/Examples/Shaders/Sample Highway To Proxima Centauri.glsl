#version 420

// original https://www.shadertoy.com/view/NtBXDz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Highway to Proxima Centauri - Result of an improvised live coding session on Twitch
// LIVE SHADER CODING, SHADER SHOWDOWN STYLE, EVERY TUESDAYS 21:00 Uk time: 
// https://www.twitch.tv/evvvvil_

// "I can smell the pigs around the corner, on the shortness of your breath." - Johnny Hobbo and the freight trains

vec2 z,v,e=vec2(.00035,-.00035);float t,tt,b,gg,bb,g,tn=0.,r=1.;vec3 np,bp,pp,op,po,no,al,ld,gr,vp;
vec4 c=vec4(.85,-3,5,.0);
float bo(vec3 p, vec3 r){ p=abs(p)-r;return max(max(p.x,p.y),p.z); }
float smin(float a,float b,float k){ float h=max(0.,k-abs(a-b));return min(a,b)-0.25*h*h/k;}
float smax(float a,float b,float k){ float h=max(0.,k-abs(-a-b));return max(-a,b)+0.25*h*h/k;}
vec2 smin( vec2 a, vec2 b,float k ){ float h=clamp(.5+.5*(b.x-a.x)/k,.0,1.);return mix(b,a,h)-k*h*(1.0-h);}
mat2 r2(float r){return mat2(cos(r),sin(r),-sin(r),cos(r));}
vec2 mp( vec3 p,float ga)
{
  p.xy*=r2(sin(p.z*.5)*.2);
  vec2 h,t=vec2(bo(p,vec3(5,5,20)),1); //MAIN OUTTER BOX  
  t.x=max(abs(t.x)-.2,abs(abs(p.x)-4.)-1.5); //CUT BOX INTO HOLLOW
  t.x=max(t.x,-(abs(p.y)-2.)); //CUT MIDDLE OF BOX TO LEAVE JUST CORNERS
  h=vec2(length(p.xy)-.05,0); //LONG INFINITE THIN CYLINDER ALONG Z AXIS
  pp=p; //NEW POSTION PP FOR ROTATOR WHICH IS JUST THE CROSS BUILDING THING
  pp.xy=abs(pp.xy); //SIMETRY CLONE TO GET X cross
  pp.xy*=r2(-.785);   //GET X CROSS BY ROTATING 45 DEG
  pp.z=mod(pp.z-tt,10.)-5.;  //INFINITE WHOLE SCENE ALONG Z
  gr=clamp(cos(pp*15.),-.5,.5)*.01;//GREEBLE
  float rotator=bo(pp,vec3(.4+gr.y,15,.4+gr.y));  //ROTATOR / CROSS 
  float cut=-(abs(abs(pp.y)-3.)-.5); //CROSS CUT MAIN
  rotator=max(rotator,cut); //CUT CROSS 
  float cutter=length(pp.xz)-.2+gr.y*2.; 
  rotator=smax(cutter,rotator,.45); //CROSS / ROTATOR CUT CORE
  vec3 rp=bp=pp;bp.y-=3.; //POSITON FOR LINES ALONG CROSS
  rp.y=sin(pp.y*7.5)*.2;  //WEIRD SIN REPETITION INSTEAD OF MODULO
  rp.x=abs(rp.x)-.25;   //REPAET POS ALONG X
  h.x=min(h.x,.8*max(abs(length(bp)-.7)-.04,-(abs(abs(bp.y)-.15)-.05))); //BLACK SPHERE ENDS
  rotator=smax(length(rp.xy)-.075,rotator,.05);  //holes in ROTATOR  
  rp.z=abs(rp.z)-.35;  //REPEAT POS ALONG Z ONCE
  h.x=smin(h.x,.8*(length(rp.xz-vec2(0,.12+gr.y*5.))-.03),.023); //BLACK GREEBLE LINES  
  bp=pp;bp.x+=3.;  //BLACK SQUARES ON SIDES AND TOP BOTTOM POSITION
  float blackSquares=bo(bp-vec3(0,5,0),vec3(1.-gr.z,20,10.)); 
  blackSquares=min(blackSquares,bo(bp-vec3(6.5,0,0),vec3(1.-gr.z,20,10.))); //BLACK SQUARES BOTTOM/TOP AND ON SIDES
  bp.y=mod(bp.y,.5)-.35;  //CUTTERE POSITION FOR BLACK SQUARES
  h.x=min(h.x,max(blackSquares,-(abs(bp.y)-.05)));  //CUT BLACK SQUARES OT REVEAL GLOWY CORE INSIDE
  bp=pp;bp.x=abs(bp.x)-1.; //WHITE BITS OUTTER POSITION
  bp.z=abs(bp.z)-1.; //REPEAT WHITE BITS ONCE ALONG Z
  t.x=smin(t.x,.8*max(bo(bp,vec3(.2-gr.y*2.,10,.2+gr.x*3.)),-(abs(bp.x)-.05)),.5); //WHITE BITS OUTTER
  t.x=smin(rotator,t.x,0.1);  //ADD CROSS / ROTATOR TO WHOLE SCENE
  t=smin(t,h,.1); //MERGE BOTH MTERIAL IDS TOGETHER WITH SMOOTHMIN VEC2 so not only smin geom but material id too
  if(length(pp.xz)<.2) tn=0.0;
  b=sin(pp.y-tt*2.); //SOME DEFORMER
  bp=pp;bp.xz=abs(bp.xz)-max(0.02,tn-b*.09); //ELECTRICITY POSITION
  h=vec2(length(bp.xz),2); //GLOW BITS  
  g+=0.1/(0.1+h.x*h.x*(100.-90.*b))*ga;
  blackSquares+=.3;  //CHEAP WAY TO GET CORE REUSING THE BLACK SQUARES with distance field offset to push them back
  g+=0.1/(0.1+blackSquares*blackSquares*30.)*ga; //BLACK SQAURE CORE
  h.x=min(h.x,blackSquares);
  vp=mix(vec3(-4.4,1.8,6),vec3(3,-1,6),bb)+cos(tt)*.2; //CAR MOVING POSITON
  vec3 cap=(p-vp)*4.;//CAR MOVING POSITON
  cap.z=mod(cap.z+tt*5.,30.)-15.;//CAR MOVING POSITON MADE REPEATED ALONG Z
  cap.xy*=r2(mix(-.5,-6.5,bb)+cos(tt)); //ROTATE CAR ACCORDINGLY
  cap.xz*=r2(-cos(tt*.5)*.2);//ROTATE CAR ACCORDINGLY    
  h.x=min(h.x,max(.7*max(length(rp.xy)-.03+rp.z*.02,abs(pp.z)-max(0.55,0.55+b)),cut)); //WHITE LINES   
  bp=cap+vec3(0,0,1.);bp.x=abs(bp.x)-.75;  //CAR PIECES POSITION
  float car=bo(bp,vec3(.2+gr.z*3.,.1-gr.x*5.-gr.z,1.35)); /////////////////////////////CARRRRRR
  gr=clamp(sin(cap*10.),-.5,.5)*.1; //CAR GREEBLE
  car=smin(car,bo(cap,vec3(1.+gr.z,.1+gr.z,1)),.5); //CAR PIECE
  car=smin(car,length(abs(cap)-vec3(0,0,.7))-.6,.5);//CAR PIECE
  car=smax(length(abs(cap)-vec3(0,0,1.))-.4,car,.5);//CAR CUTTER  
  float lightTubes=0.7*max(length(bp.xy)-(1.+sin(cap.z*1.5-tt*5.))*.2+(cap.z-1.)*.15,-cap.z+1.1); //CAR GLOW ROCKET ENGINE
  car=min(car,lightTubes); //CAR GLOW ROCKET ENGINE
  gg+=0.1/(0.1+lightTubes*lightTubes*(50.+cos(clamp(cap.z,1.,50.)*1.5-tt*5.)*49.))*ga;  //CAR GLOW ROCKET ENGINE ADD GLOW
  float balls=length(abs(cap)-vec3(0,0,.9))-.4; //BALLS ON FRONT AND BACK OF CAR
  g+=0.1/(0.1+balls*balls*(50.-sin(abs(cap.z)-tt*5.)*49.))*ga; //GLOW BALLS
  car=min(car,balls); //GLOW BALLS
  h.x=min(h.x,car/4.);//ADD CAR TO REST OF SCENE /4. AS IT'S BEEN SCALED DOWN A LOT
  t=t.x<h.x?t:h;  
  return t;
}
vec2 tr( vec3 ro,vec3 rd)
{
  vec2 h,t=vec2(.1);
  for(int i=0;i<128;i++){
    h=mp(ro+rd*t.x,1.);
    if(h.x<.0001||t.x>30.) break;
    t.x+=h.x;t.y=h.y;
  }
  if(t.x>30.) t.y=-1.;
    return t;
}
#define a(d) clamp(mp(po+no*d,0.).x/d,0.,1.)
#define s(d) smoothstep(0.,1.,mp(po+ld*d,0.).x/d)
void main(void)
{
  vec2 uv=(gl_FragCoord.xy/resolution.xy-0.5)/vec2(resolution.y/resolution.x,1);   
  tt=26.21+mod(time,53.);
  bb=smoothstep(0.,1.,clamp(cos(tt*.35+.3),-.25,.25)*2.+.5);  
  vec3 ro=mix(vec3(1,-2,10),vec3(-1,1,10),bb),cw=normalize(vec3(cos(tt*.4)*4.,cos(tt*.4)*4.+3.,0)-ro),
  cu=normalize(cross(cw,vec3(0,1,0))),cv=normalize(cross(cu,cw)),rd=mat3(cu,cv,cw)*normalize(vec3(uv,.5)),co,fo;
  co=fo=vec3(.1,.12,.13)-length(uv)*.1-rd.y*.1;
  ro.xy*=r2(cos(pp.z*.5)*.2);
  vec3 lp=ro;
  z=tr(ro,rd);t=z.x;
  if(z.y>-1.){
    po=ro+rd*t;
    no=normalize(e.xyy*mp(po+e.xyy,0.).x+e.yyx*mp(po+e.yyx,0.).x+e.yxy*mp(po+e.yxy,0.).x+e.xxx*mp(po+e.xxx,0.).x);
    ld=normalize(lp-po);   
    v=pp.xz*.2;
    for(int i=0;i<3;i++){
      v=abs(v)-1.0;
      v*=r2(ceil(sin(v.y)));
      v*=2.;
      r=min(r,ceil(abs(sin(v.x*5.23))-.3));
    }    
    al=mix(vec3(.0),vec3(.75)-r,min(1.,z.y));
    if(z.y>1.) al=vec3(.5);
    float dif=max(0.,dot(no,ld)),
    fr=pow(1.+dot(no,rd),4.),
    sp=pow(max(dot(reflect(-ld,no),-rd),0.),40.),
    attn=1.-pow(min(1.,length(lp-po)/10.),4.0);
    co=attn*mix(sp+al*(a(.1)+.2)*(dif*vec3(1,.86,.7)+s(1.)),fo,min(fr,.5));
    co=mix(fo,co,exp(-.0003*t*t*t));
  }
    glFragColor = vec4(pow(co+g*vec3(1,.5,.1)*.2+gg*.2,vec3(.65)),1);
}
