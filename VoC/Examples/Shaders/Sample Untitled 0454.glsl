#version 420

// original https://www.shadertoy.com/view/WtsSWN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Winning shader made at Revision 2019 Shader Showdown "world championships",
// Qualifying round against LJ. Video of the battle: https://www.youtube.com/watch?v=YKtvYAn-v2Y

// The "Shader Showdown" is a demoscene live-coding shader battle competition.
// 2 coders battle for 25 minutes making a shader on stage. No google, no cheat sheets.
// The audience votes for the winner by making noise or by voting on their phone.

// "Coughin' to a coffin, might as well scoff the pork, then." - MF DOOM

// Comments have been commented, due to the general lack of sense of humour in the post-graduatosphere.

vec2 s,e=vec2(.00035,-.00035);float t,tt,g,b,bb,bs;vec3 np;
float bo(vec3 p,vec3 r){vec3 q=abs(p)-r;return max(max(q.x,q.y),q.z);}
mat2 r2(float r){return mat2(cos(r),sin(r),-sin(r),cos(r));} 
vec2 fb(vec3 p)
{
  vec2 h,t=vec2(bo(abs(p)-vec3(2,0,0),vec3(.6,10,.5)),3);
  h=vec2(bo(abs(p)-vec3(2,0,0),vec3(.4,10,.7)),5);
  t=t.x<h.x?t:h;
  h=vec2(bo(abs(p)-vec3(2.7,0,0),vec3(.1,10,.1)),6);
  g+=0.1/(.1+h.x*h.x*20.);  t=t.x<h.x?t:h;
  h=vec2(bo(abs(abs(p)-vec3(0,1,0))-vec3(0,.5,0),vec3(2,.3,.3)),6);
  t=t.x<h.x?t:h;
  h=vec2(bo(p+4.,vec3(20,.6,.5)),6);
  t=t.x<h.x?t:h;
  h=vec2(bo(p+4.,vec3(20.2,.4,.7)),3);
  t=t.x<h.x?t:h;
  h=vec2(bo(p+1.,vec3(5.+5.*(.5+sin(tt-1.57)*.5),.2,.2)),3);
  t=t.x<h.x?t:h;
  t.x*=.6;
  return t;
}
vec2 mp( vec3 p )
{
  bb=sin(p.y*.5)*.5;  
  b=sin(p.y*.1-tt*.5);
  p.xz*=r2(sin(p.y*.1+tt)*.3);
  np=p;
  np.y=mod(np.y+tt*10.,20.)-10.;
  for(int i=0;i<8;i++){
    np=abs(np)-vec3(2.-b,4.+bs*3.,2.-b+bs);
    np.xz*=r2(.8-4.*bs);
  }
  np.x-=5.;
  vec2 h,t=fb(np);
  h=vec2(length(cos(bb-np*.5)-0.1),6);
  g+=0.1/(.1+h.x*h.x*200.);
  t=t.x<h.x?t:h;
  p.y=0.;
  h=vec2(length(p)-1.5+bb,6);
  g+=0.1/(.1+h.x*h.x);
  t=t.x<h.x?t:h;
  h=vec2(bo(abs(np*.5)-9.,vec3(1.2-b,10,1.+b)),5);
  t=t.x<h.x?t:h;
  h=vec2(bo(abs(np*.5)-9.,vec3(1.4-b,10,.1)),6);
  g+=0.1/(.1+h.x*h.x*100.);
  t=(t.x<h.x)?t:h;
  return t;
}
vec2 tr( vec3 ro, vec3 rd )
{
  vec2 h,t=vec2(0.1);
  for(int i=0;i<128;i++){
    h=mp(ro+rd*t.x);
      if(h.x<.0001||t.x>120.) break;      
      t.x+=h.x;t.y=h.y;
  } if(t.x>120.) t.x=0.;
  return t;
}
void main(void)
{
    vec2 uv = vec2(gl_FragCoord.x / resolution.x, gl_FragCoord.y / resolution.y);
    uv -= 0.5;uv /= vec2(resolution.y / resolution.x, 1);    
    tt=mod(time,62.83);
      bs=clamp(sin(-tt*.5),-.25,.25)+.25;
    vec3 ro=vec3(7,-1,sin(tt*.5)*60.),
    cw=normalize(vec3(0)-ro),
    cu=normalize(cross(cw,vec3(0,1,sin(tt)*2.))),
    cv=normalize(cross(cu,cw)),
    rd=mat3(cu,cv,cw)*normalize(vec3(uv,0.5)),co,fo,
    ld=normalize(vec3(0.1,0.5,.1));
    co=fo=vec3(.1,.5,.6)-rd.y*.5;
    s=tr(ro,rd);t=s.x;
    if(t>0.){
        vec3 po=ro+rd*t,no=normalize(e.xyy*mp(po+e.xyy).x+e.yyx*mp(po+e.yyx).x+e.yxy*mp(po+e.yxy).x+e.xxx*mp(po+e.xxx).x),
        al=vec3(1,0.5,0.);
        if(s.y<5.) al=vec3(0);
        if(s.y>5.) al=vec3(1);
        float dif=max(0.,dot(no,ld)),
        spo=1.5;//exp2(10.*texture(iChannel0,vec2(np.y,dot(np.xz,vec2(0.7)))/vec2(30,10)).r),
        float fr=pow(1.+dot(no,rd),4.),
        aor=t/50.,ao=exp2(-2.*pow(max(0.,1.-mp(po+no*aor).x/aor),2.)),
        sss=smoothstep(0.,1.,mp(po+ld*0.4).x/0.4),
        sp=pow(max(dot(reflect(-ld,no),-rd),0.),spo);
        co=mix(sp+al*(.8*ao+0.2)*(dif+sss),fo,min(fr,.5));
    }
    glFragColor = vec4(pow(mix(co,fo,1.-exp(-.000003*t*t*t))+g*.3,vec3(0.45)),1);
}
