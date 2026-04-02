#version 420

// original https://www.shadertoy.com/view/WslyDl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Energy Confinement - Result of an improvised live code session on Twitch

// LIVE SHADER CODING, SHADER SHOWDOWN STYLE, EVERY TUESDAYS 21:00 Uk time:
// https://www.twitch.tv/evvvvil_

// "Seven continents in the %&*$, smoking like it's %&*$in London" - EL-P

vec2 z,v,e=vec2(.00035,-.00035); float t,tt,b,bb,g,grow,gg,ps;vec3 pp,np,cp,xp,po,no,al,ld;//global vars. 
float bo(vec3 p,vec3 r){p=abs(p)-r;return max(max(p.x,p.y),p.z);} //box primitive function. 
mat2 r2(float r){return mat2(cos(r),sin(r),-sin(r),cos(r));} //rotate function. 
float octa( vec3 p, float s){  p = abs(p); return (p.x+p.y+p.z-s)*0.57735027;} //dumb octagone function. Clearly not as cool as Dr Octagon, but then nobody really is...
vec2 fb( vec3 p,float s, float f,float gs) // fb "%&*$ing bit" function make a base geometry which we use to make weird spliune network
{ //I will comment all this %&*$ later...
  b=sin(p.y*.2+1.57)+sin(p.y+tt*5.)*.15;
  vec2 h,t=vec2(length(p.xz)-(1.+b),5);
  t.x=min(length(abs(p.xz)-(1.+b)*.7)-(.2+b*.2),t.x);
  pp=p; pp.y=mod(p.y,1.)-0.5;
  h=vec2(length(pp.xy)-(.2),3);
  h.x=max(h.x,length(p.xz)-(1.2+b));
  t=t.x<h.x?t:h;
  t.x=max(abs(t.x)-.2,-bo(p+vec3(0,0,0),vec3(3,s,3)));  
  h=vec2(length(p.xz)-(1.1+b),6);
  t=t.x<h.x?t:h;
  t.x=max(abs(t.x)-.05,-bo(p,vec3(3,s-.5,3)));  
  h=vec2(length(p.xz)-(.1+b*.3*f),6);
  h.x=max(h.x,bo(p,vec3(3,12.3,3)));  
  g+=0.2/(0.1+(h.x/gs)*(h.x/gs)*(80.-sin(p.y*.3-tt*3.)*79.));  
  t=t.x<h.x?t:h;  
  pp=p; pp.xz*=r2(sin(p.y*.3+tt));
  h=vec2(length(abs(pp.xz)-(1.+b)*.2+sin(p.y*.3)*.2)-(.2*f),6);  
  t=t.x<h.x?t:h;  
  h=vec2(length(abs(pp.xz)-(1.+b)*.5+sin(p.y*.3)*.2)-((1.+b*2.)*.05)*f,3);  
  t=t.x<h.x?t:h; 
  t.x*=0.7;return t;
}
vec2 pyra(vec3 p,float s,float of,float m,float o){  
  p*=(1.-grow*.1);
  pp=p;pp.xz*=r2(.785); 
  vec2 h,t=vec2(octa(pp+vec3(0,grow*15.,0),s),m); //PYRA TOP  
  t.x=max(abs(t.x)-o,p.y+grow*15.+of);    
  h=vec2(octa(pp+vec3(0,-grow*15.,0),s),m); //PYRA BOTTOM
  h.x=max(abs(h.x)-o,-p.y+grow*15.+of);  
  t=t.x<h.x?t:h;
  t.x=max(t.x,-(length(p.xz)-5.)); //CYLINDER CUT
  if(s>24.) {
    pp=abs(abs(abs(p)-vec3(0,8.+grow*15.,0))-vec3(0,2,0))-vec3(0,1,0);
    t.x=max(t.x,-bo(pp,vec3(20,.3,20))); //THIN RECTANGLE CUT
  }else{
    gg+=0.15/(0.1+t.x*t.x*(20.-abs(sin(p.y*.2-tt*3.))*19.));//GLOW ONLY THE INSIDE PYRAMID
  } return t;
}
vec2 mp( vec3 p )
{ 
  bb=cos(p.y*.1);  ps=(1.-grow*.4);
  cp=p*ps;cp.xz*=r2(grow*10.+sin(p.y*.05));    
  np=cp;  np.xz*=r2(.785);  np.xz=abs(np.xz);  
  np.xz-=(2.5+bb*4.*grow);
  vec2 h,t=fb(np,4.5,1.,1.); h.x/=ps; //TWIRLS MIDDLE 4
  h=fb(p*.42,2.,1.,.42); h.x/=.42; //TWIRLS MIDDLE SMALL
  t=t.x<h.x?t:h; 
  h=fb(p*.105,2.+grow*8.,0.,.35); h.x*=6.; //TWIRLS HUGE
  t=t.x<h.x?t:h; 
  h=fb(abs(p*.7)-(15.+grow*7.+bb*2.,11.,15.+grow*7.+bb*2.),2.,1.,.7); h.x/=.7; //TWIRLS outter 4
  xp=p; t=t.x<h.x?t:h; 
  pp=cp;pp.xz=abs(pp.xz)-vec2(5.+bb*6.,5.+bb*6.)*grow;
  h=fb(pp*.6,4.5,1.,.6); h.x/=(.7*ps); t=t.x<h.x?t:h;  //TWIRLS BIG 4
  h=vec2(.9*length(cos(abs(p*.4)-vec3(0.,tt*4.+grow*10.,0.)+np*.04)),6); //PARTICLES
  h.x=max(h.x,length(p.xz)-(14.+bb*3.+grow*6.));
  gg+=0.1/(0.1+h.x*h.x*100.); t=t.x<h.x?t:h; 
  bb=15.+grow*18.;
  h=vec2(bo(p,vec3(bb,10.,bb)),6); //ROAD WHITE  
  h.x=max(abs(h.x)-2.5,bo(p,vec3(bb+.5,.5,bb+.5)));
  gg+=0.1/(0.1+h.x*h.x*50.); t=t.x<h.x?t:h;  
  h=vec2(bo(p,vec3(bb-1.,10.,bb-1.)),3); //ROAD BLACK
  h.x=max(abs(abs(h.x)-.6)-.3,bo(p,vec3(bb,.7,bb)));
  t=t.x<h.x?t:h;  
  h=pyra(p,25.,0.,3.,1.); t=t.x<h.x?t:h; //OUTTER PYRA BLACK
  h=pyra(p,24.,1.,6.,0.2); t=t.x<h.x?t:h;  //INNER PYRA BLUE
  return t;// Add central structure and return the whole %&*$
}
vec2 tr( vec3 ro, vec3 rd ) // main trace / raycast / raymarching loop function 
{
  vec2 h,t= vec2(.1); //Near plane because when it all started the hipsters still lived in Norwich and they only wore tweed.
  for(int i=0;i<128;i++){ //Main loop de loop 
    h=mp(ro+rd*t.x); //Marching forward like any good fascist army: without any care for culture theft. (get distance to geom)
    if(h.x<.0001||t.x>250.) break; //Conditional break we hit something or gone too far. Don't let the bastards break you down!
    t.x+=h.x;t.y=h.y; //Huge step forward and remember material id. Let me hold the bottle of gin while you count the colours.
  }
  if(t.x>250.) t.y=0.;//If we've gone too far then we stop, you know, like Alexander The Great did when he realised his wife was sexting some Turkish bloke. (10 points whoever gets the reference)
  return t;
}
#define a(d) clamp(mp(po+no*d).x/d,0.,1.)
#define s(d) smoothstep(0.,1.,mp(po+ld*d).x/d)
void main(void)
{
  vec2 uv=(gl_FragCoord.xy/resolution.xy-0.5)/vec2(resolution.y/resolution.x,1); //get UVs, nothing fancy, 
  tt=mod(5.+time*.5,31.41); //Time variable, modulo'ed to avoid ugly artifact. Imagine moduloing your timeline, you would become a cry baby straight after dying a bitter old man. Christ, that's some %&*$ing life you've lived, Steve.
  grow=smoothstep(0.,1.,.5+.5*sin(tt));
  vec3 ro=mix(vec3(1),vec3(-1.2,-2,1),ceil(sin(tt)))*vec3(cos(tt*.2+.2)*38.,5,sin(tt*.2)*38.),//Ro=ray origin=camera position We build camera right here broski. Gotta be able to see, to peep through the keyhole.
  cw=normalize(vec3(0)-ro), cu=normalize(cross(cw,vec3((sin(grow*.2))*2.,1,0))),cv=normalize(cross(cu,cw)),
  rd=mat3(cu,cv,cw)*normalize(vec3(uv,.5+grow*.1)),lp=vec3(0,0,0)-ro,co,fo;//rd=ray direction (where the camera is pointing), co=final color, fo=fog color
  ld=normalize(vec3(1,5,0)), //ld=light direction
  co=fo=vec3(.15)-length(uv*1.1)*.15-rd.y*vec3(.05,.05,.1);//background is dark blueish with vignette and subtle vertical gradient based on ray direction y axis. 
  z=tr(ro,rd);t=z.x; //Trace the trace in the loop de loop. Sow those %&*$ing ray seeds and reap them %&*$ing pixels.
  if(z.y>0.){ //Yeah we hit something, unlike you at your best man speech.
    po=ro+rd*t; //Get ray pos, know where you at, be where you is.
    no=normalize(e.xyy*mp(po+e.xyy).x+e.yyx*mp(po+e.yyx).x+e.yxy*mp(po+e.yxy).x+e.xxx*mp(po+e.xxx).x); //Make some %&*$ing normals. You do the maths while I count how many instances of Holly Willoughby there really is.
    al=mix(vec3(0.7,0.05,.0),vec3(.8,.2,.0),.5+.5*sin(xp*.3)); //al=albedo=base color, by default it's a gradient between red and orange. 
    if(z.y<5.) al=vec3(0); //material ID < 5 makes it black
    if(z.y>5.) al=vec3(1); //material ID > 5 makes it white
    float dif=max(0.,dot(no,ld)), //Dumb as %&*$ diffuse lighting
    attn=1.-pow(min(1.,length(lp-po)/(20.+grow*70.)),4.),
    fr=pow(1.+dot(no,rd),4.), //Fr=fresnel which adds background reflections on edges to composite geometry better
    sp=pow(max(dot(reflect(-ld,no),-rd),0.),30.); //Sp=specular, stolen from Shane
    co=attn*mix(sp+al*(a(.1)*a(.3)+.2)*(dif+s(2.)),fo,min(fr,.2)); //Building the final lighting result, compressing the %&*$ outta everything above into an RGB %&*$ sandwich
    co=mix(fo,co,exp(-.000005*t*t*t));//Fog soften things, but it won't stop your mother from being unimpressed by your current girlfriend
  } ps=.07+.13*grow;
  glFragColor = vec4(pow(co+gg*ps*mix(vec3(0.1,0.2,.4),vec3(.1,.3,.6),.5+.5*sin(xp*.3))+g*ps*mix(vec3(0.7,0.05,.0),vec3(.8,.2,.0),.5+.5*sin(xp*.3)),vec3(.55)),1);// Naive gamma correction and glow applied at the end. Glow switches from blue to red hues - nice idea by Haptix - cheers broski
}
