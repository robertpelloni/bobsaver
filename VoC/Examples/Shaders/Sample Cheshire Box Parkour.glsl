#version 420

// original https://www.shadertoy.com/view/3tlyRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Cheshire Box Parkour - Result of an improvised live code session on Twitch
// LIVE SHADER CODING, SHADER SHOWDOWN STYLE, EVERY TUESDAYS 21:00 Uk time: 
// https://www.twitch.tv/evvvvil_

// "The Cheshire cat is probably on drugs, well, I know I am." - Lewis Carroll

vec2 z,v,e=vec2(.0035,-.0035);float t,tt,bb,sbb,boxZ,boxR,g,gg;vec3 np,bp,pp,op,po,no,ld,al;//Global vars. About as boring as living in Denmark.
float cx(vec3 p,vec3 r){return max(abs(length(p.yz)-r.x)-r.y,abs(p.x)-r.z);} //Hollow Tunbe primitive. My own primitive function, don't laugh, I'm not very good at Math but I'm better than you at skateboarding. (seriously though, wanna challenge me? game of skate? You're on broski)
float bo(vec3 p,vec3 r){p=abs(p)-r;return max(max(p.x,p.y),p.z);} //Box Primitive. Someone elese's primitive function (told you I'm not very good at Math but I'm French so I'm good at stealing and showing off)
mat2 r2(float r){return mat2(cos(r),sin(r),-sin(r),cos(r));}//Rotate function. Short and sweet, just like the perfect argument with your partner. It never %&*$ing is though, here we are 5 hours later like two howler monkeys hurling bananas at eachother.
vec4 texNoise(vec2 uv){ float f = 0.; //f+=texture(iChannel0, uv*.125).r*.5; //Rough shadertoy approximation of the bonzomatic noise texture by yx - https://www.shadertoy.com/view/tdlXW4
    //f+=texture(iChannel0,uv*.25).r*.25;f+=texture(iChannel0,uv*.5).r*.125;f+=texture(iChannel0,uv*1.).r*.125;f=pow(f,1.2);
return vec4(f*.45+.05);
}     
vec2 fb( vec3 p, float s) //fb is "%&*$ing bit" function that make base geometry for the more complex network / kifs made in mp
{
  p.yz*=r2(sin(p.x*.5)*.5);//Rotate everything along x axis
  p=abs(p)-vec3(4,0,0); //Everything is abs symetry cloned along the x to create mroe geom
  vec2 h,t=vec2(length(p)-1.8,6); //Big glowy spheres
  g+=0.1/(0.1+t.x*t.x*20.); //Glow trick from Balkhan, push distance field of geom in vairable and add at the end (see last line)
  h=vec2(length(abs(p.yz)-vec2(1.5))-.3,6);//4 GREY cylinders on sides
  h.x=min(h.x,cx(p,vec3(2.2,.3,.2)));//hollow tube / ring around the big glowy spheres
  h.x=max(h.x,abs(p.y)-1.4); //Cut grey sylinders and tube to reveal the blue ones underneath
  t=t.x<h.x?t:h;  //Merge glowy sphere and all grey shapes above
  h=vec2(length(abs(p.yz)-vec2(1.5))-.2,5); //Make 4 blue cylinders
  h.x=min(h.x,cx(p,vec3(2.2,.3,.2))); //Add blue hollow tube / ring around glowy spheres
  t=t.x<h.x?t:h;  //Add all blue shapes to rest of geometries
  h=vec2(length(p.yz-vec2(1.6,2.0))-s*min(.02,.1*sin(-p.x*.2)),3); //RED thin tubes going up the columns the variable "s" is to hide / show them depending on kifs we are using
  gg+=0.1/(0.1+h.x*h.x*(200.-190.*sin(p.x*.7-tt*4.-2.)))*s;//Glow the red %&*$ers with animated sweep along the y axis.
  t=t.x<h.x?t:h; //Add red %&*$ers to rest of scene
  return t;
}
vec2 road(vec3 p){ //Road make the black / glowy road like geometry AND the bouncing cheshire boxes
  vec2 h,t=vec2(bo(abs(p)-vec3(1.15,2.,0.),vec3(.2,.1,100.)),3); //Dull box making dull road
  h=vec2(bo(abs(p)-vec3(1.15,2.,0.),vec3(.05,.12,100.)),6); //Everybody loves a %&*$ing glow on the road
  g+=(.5+0.4*abs(sin(p.z*5.))*sbb)/(0.1+h.x*h.x*(400.-sin(p.z+1.57+boxZ)*399.*sbb)); //Make it glow again, reusing boxz position of boxes to align the glow, no real math %&*$ery here more of some gut feeling bull%&*$.
  t=t.x<h.x?t:h;  //Merge dullbox and glow bit
  vec3 flyPos=p+vec3(0,-.2-(bb),boxZ); //We make the actual box bouncing position in flyPos, I know lame variable name but hey I'm not the one actually called "Kevin", you are.
  flyPos.xy=abs(flyPos.xy)-vec2(1.15,2.);  //Somehow abs symetry cloning of pos seemed a good idea. I don't know since writting this plenty neurones went down the bottle and I even forgot pet lizard name... Dr something? Dr Dre? no wait. Dr Drizzle, that's it. Anyways what are we talking about here?
  flyPos.yz*=r2(sin(op.z)+boxR); //Just like throwing a soft dildo at your partner's face, the boxes nicely bend as they rotate in space with "sin(op.z)". Also they always land on the right face with mix(3.14,0.,fract(tt*2.))
  h=vec2(bo(flyPos,min(fract(tt*.2),.1)*10.*vec3(.05,mix(.05,.15,bb),.05)),6);//Draw the actual cheshire boxes with mad position above
  gg+=0.1/(0.1+h.x*h.x*75.); //Make em glow a bit but this time red for bit of contrast
  t=t.x<h.x?t:h; //Add cheshire boxes to the rest of road
  t.x/=.6; t.x*=.8; //Tweak distance field to avoid aritfact. I know not exactly elegant to have 2 calc in a row, but then I had 7 pints in a row last friday and despite wearing a fancy hat, it wasn't elegant either.
  return t; 
}
vec2 mp( vec3 p )
{ 
  op=np=p; //op is original position and it is just here to remember how p was orginally before we start tweaking the %&*$ outta everything
  np.z=mod(np.z+tt*2.,75.)-37.5;  //np is the more complex position based on p which we put in loop to make a KIFS (kaleidoscopic iteration funciton system)
  for(int i=0;i<4;i++){ //Here is our KIFS loop, I used to call it "pseudo fractal" because I'm not a nerd but someone self-righteous showed me the virtuous jargon-filled path and now I call them KIFS and I'm ok being a self-righteous prick.
    np.xz=abs(np.xz)-vec2(6,6); //Push out a bit each loop, sort of a "reverse %&*$ing", if you don't think about it too long. Indulge me, it's the lockdown and I have to amuse myself.
    np.xz*=r2(.7+sin(np.z*.2)*.3); //Yeah rotate bit and add sin(np.z) to break symetry along z.
  }
  vec2 h,t=fb(np,0.); t.x*=0.8; //Make first bunch of geometry with kifs above
  h=vec2(p.y,6); //Make simple "terrain" with plane at 0, not eveything has to be fancy marble %&*$ing columns, this isn't some crass nouveau-riche footballer's bachelor pad.
  t=t.x<h.x?t:h; //merge terrain and 1st kifs
  bp=np*.5; //Create new position bp based on np but twice bigger, to make bigger round of kifs
  bp.xz*=r2(.785); //Rotate the %&*$ers a bit for good luck
  bp.xz+=vec2(.5,-2.5); //And shift them into place so it';s snug  with the first round of kifs
  h=fb(bp,0.); h.x/=.6; //Draw 2nd bigger bit of geom with kifs, and it is snug with first one
  t=t.x<h.x?t:h; //Merge 2nd kifs with rest
  h=road(bp); //Make da road and the bouncing cheshire boxes because shadertoy need more comedy
  t=t.x<h.x?t:h; //Merge road and rest
  bp=np*.5; //yeah yeah we do it again, dumb %&*$ i know but don't care broh
  bp.xy*=r2(1.57); //Rotate 180 to make it stand up, yeah we making oclumns basically
  bp.xz-=vec2(1.,1.6); //Shift columns a bit make it snug with rest
  h=fb(bp,1.); h.x/=.7; //Here we draw column with bp position above
  t=t.x<h.x?t:h; //Merge columns with rest
  pp=np; //PP is the position used for BLACK boxes on terrain, it is based on np so it's also a kifs
  pp.xz=mod(pp.xz,2.)-1.;  //Make loads of em by doing a grid of em
  h=vec2(bo(pp,vec3(.5,1.+2.*(.5+.5*sin(np.z*.5)),.5)),3); // Draw all those black boxes
  h.x=max(h.x,-(length(bp.yz)-3.2)); //Remove black boxes that are too close to the blue / grey kifs geometry based on bp
  h.x=max(h.x,-(length(np.yz)-4.8)); //Remove black boxes that are too close to the blue / grey kifs geometry based on np
  t=t.x<h.x?t:h; //Merge black boxes with rest of scene
  t.x*=.7; //Tweak distance field of everything to avoid artifact
  return t;
}
vec2 tr( vec3 ro, vec3 rd) // main trace / raycast / raymarching loop function 
{
  vec2 h,t= vec2(.1); //Near plane because when it all started the hipsters still lived in Norwich and they only wore tweed.
  for(int i=0;i<128;i++){ //Main loop de loop 
    h=mp(ro+rd*t.x); //Marching forward like any good fascist army: without any care for culture theft. (get distance to geom)
    if(h.x<.00001||t.x>40.) break;//Conditional break we hit something or gone too far. Don't let the bastards break you down!
    t.x+=h.x;t.y=h.y; //Huge step forward and remember material id. Let me hold the bottle of gin while you count the colours.
  }
  if(t.x>40.) t.y=0.;//If we've gone too far then we stop, you know, like Alexander The Great did when he realised his wife was sexting some Turkish bloke. (10 points whoever gets the reference)
  return t;
}
#define a(d) clamp(mp(po+no*d).x/d,0.,1.)
#define s(d) smoothstep(0.,1.,mp(po+ld*d).x/d)
void main(void)
{
  vec2 uv=(gl_FragCoord.xy/resolution.xy-0.5)/vec2(resolution.y/resolution.x,1); //get UVs, nothing fancy, 
  tt=mod(time,62.82)+24.5;  //Time variable, modulo'ed to avoid ugly artifact. Imagine moduloing your timeline, you would become a cry baby straight after dying a bitter old man. Christ, that's some %&*$ing life you've lived, Steve.
  bb=abs(sin(tt*2.)); //bb is an animation variable used to move boxes
  boxZ=mix(0.,6.7,fract(tt*.2)); //boxZ is the bouncing box z pos animation variable
  boxR=mix(3.14,0.,fract(tt*2.)); //boxR is the bouncing box angle rotation animation variable
  sbb=1.-smoothstep(0.,1.,bb);  //sbb is the reverse of bb but also smoothed / eased animation variable
  vec3 ro=mix(vec3(1),vec3(-1,1.7,1),ceil(sin(tt*.4)))*vec3(cos(tt*.4+.1)*2.,7.,-10),//Ro=ray origin=camera position We build camera right here broski. Gotta be able to see, to peep through the keyhole.
  cw=normalize(vec3(0)-ro),cu=normalize(cross(cw,vec3(0,1,0))),cv=normalize(cross(cu,cw)), //camera forward, left and up vector.
  rd=mat3(cu,cv,cw)*normalize(vec3(uv,.5)),co,fo;//rd=ray direction (where the camera is pointing), co=final color, fo=fog color
  ld=normalize(vec3(-.1,.5,-.3));//ld=light direction
  co=fo=vec3(.1)-length(uv)*.1-rd.y*.1;//background is dark with vignette and small gradient along y, like a  horizon
  z=tr(ro,rd);t=z.x; //Trace the trace in the loop de loop. Sow those %&*$ing ray seeds and reap them %&*$ing pixels.
  if(z.y>0.){ //Yeah we hit something, unlike you trying to throw a spear at a pig. We wouldnt have survive the ice age with you and your nerdy mates.
    po=ro+rd*t; //Get ray pos, know where you at, be where you is.
    no=normalize(e.xyy*mp(po+e.xyy).x+e.yyx*mp(po+e.yyx).x+e.yxy*mp(po+e.yxy).x+e.xxx*mp(po+e.xxx).x); //Make some %&*$ing normals. You do the maths while I count how many brain cells I lost during my mid 2000s raving haydays.
    float tnoi=texNoise(np.xz*.5).r;
    if(z.y==5.) {no+=tnoi*.4;no=normalize(no);al=vec3(.0,.3,1.)*(.5+.5*cos(bp*.5))+tnoi;} //defaulkt material is gradient of blue and green with some noi
    if(z.y<5.) al=vec3(0); //material system if less than 5 make it black
    if(z.y>5.) al=vec3(1); //material system if more than 5 make it white
    float dif=max(0.,dot(no,ld)-tnoi), //Dumb as %&*$ diffuse lighting
    fr=pow(1.+dot(no,rd),4.), //Fr=fresnel which adds background reflections on edges to composite geometry better
    sp=pow(max(dot(reflect(-ld,no),-rd),0.),30.);//Sp=specular, stolen from shane
    co=clamp(mix(sp+mix(vec3(.7),vec3(1),abs(rd))*al*(a(.1)*a(.3)+.2)*(dif+s(1.)),fo,min(fr,.5)),0.,1.);//Building the final lighting result, compressing the %&*$ outta everything above into an RGB %&*$ sandwich    
  }
  co=mix(fo,co+g*.2*vec3(0.1,.2,.7)+gg*.1*mix(vec3(1.,.1,.0),vec3(.7,0.2,.1),.5+.5*sin(np.y*.5)),exp(-.0001*t*t*t)); //Fog soften things, but it won't stop your annoying uncle from thinking "Bloody fiddling with bloody numbers, ain't gonna get you a job, son. Real graft is what ye need, wee man."(last sentence read with Scottish accent if you can)
  glFragColor = vec4(pow(co,vec3(.65)),1); //Add glow at the end. g & gg are red and blue glow global variables containg distance fields see lines 42,50,58
}
