#version 420

// original https://www.shadertoy.com/view/tsjGR3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////////////
//"Volumetric Merry-go-round" - Shader Showdown practice session 006

// WHAT THE FUCK IS THE SHADER SHOWDOWN?
// The "Shader Showdown" is a demoscene live-coding shader battle competition.
// 2 coders battle for 25 minutes making a shader from memory on stage. 
// The audience votes for the winner by making noise or by voting on their phone.
// Winner goes through to the next round until the final where champion is crowned.
// Live coding shader software used is BONZOMATIC made by Gargaj from Conspiracy:
// https://github.com/Gargaj/Bonzomatic

// Every tuesdays around 20:30 UK time I practise live on TWITCH.
// This is the result of session 005. 

// COME SEE LIVE CODING EVERY TUESDAYS HERE: https://www.twitch.tv/evvvvil_

// evvvvil / DESiRE demogroup

float t,tt;vec2 sc,e=vec2(.00035,-.00035);vec4 bp,sp; //Global fucking variables
//Cheap fucking box function (stolen from that place called the internet)
float bo(vec3 p,vec3 r){vec3 q=abs(p)-r;return max(max(q.x,q.y),q.z);}

//Simple 2d rotate function, nothing to see here, move along, find the girl surfing the wormhole
mat2 r2(float r) {return mat2(cos(r),sin(r),-sin(r),cos(r));}

//Fucking bits function which makes the the fucking bit/piece: one rectangle with two spheres at each end
vec2 fb( vec3 p,float f )
{
  vec2 h,t=vec2(length(abs(p)-vec3(2,0,0))-.4,5); //spehres with "symetry cloning"
  h=vec2(bo(p,vec3(2.,.5+f,.5)),3); //dumb as fuck box
  t=(t.x<h.x)?t:h; //Blending both geometry together while passing correct material ID
  return vec2(t.x,t.y);
}

//IQ/Shane's compact 3d noise function. Because I have more memory than math (despite "smoking away huge chunks of memory")
float noise(vec3 p){
    vec3 ip=floor(p),s=vec3(7,157,113);p-=ip;
    vec4 h=vec4(0,s.yz,s.y+s.z)+dot(ip,s);
    p=p*p*(3.-2.*p);
    h=mix(fract(sin(h)*43758.5),fract(sin(h+s.x)*43758.5),p.x);
    h.xy=mix(h.xz,h.yw,p.y);return mix(h.x,h.y,p.z);
}
//Map function / scene / Where the geometry is made. This fucker is like Richard Pryor after too much freebase.(on fire)
vec2 mp( vec3 p )
{
  p.y=abs(p.y-3.)-11.;    
  bp=vec4(p.xyz*.1,1.);
  for(int i=0;i<7;i++){
    bp.xyz=abs(bp.xyz)-vec3(1.6,0,.8);     
    bp.xz*=r2(.785*2.+float(i)*.785);
    bp=bp*(1.4);
    if(i==2){ bp.xyz-=vec3(1.5,2.5,2.5); bp.xy*=r2(.785*3.);  }
    sp=bp;
    sp.xz+=1.2;    
  }
    bp.xyz=abs(bp.xyz)-vec3(0,4,0);
    vec2 h,t=fb(bp.xyz,0.);
    t.x/=bp.w*.1;

    sp.xyz=abs(sp.xyz)-vec3(0,4,0);
    h=fb(sp.xyz,4.);
    h.x/=sp.w*.1;h.y=6.;sp.x-=2.;
    h.x=max(h.x,-bo(abs(sp.xyz)-vec3(0,2,0),vec3(1.1)));
    t=(t.x<h.x)?t:h;
  return t;      
}

//Main raymarching loop with material ID flex, because Tottenham FC ain't gonna win nothing this year again!
vec2 tr(vec3 ro, vec3 rd,float p,float m,int it )
{
vec2 h,t;h=t=vec2(.1);
  for(int i=0;i<it;i++){
    h=mp(ro+rd*t.x);
    if(h.x<p||t.x>m) break;
    t.x+=h.x;t.y=h.y;
  } 
  if(t.x>m) t.x=0.;
  return t;
}

#define AN(A,B,C) clamp(A(tt*B-C),-.5,.5)

void main(void)
{    
    vec2 uv = vec2(gl_FragCoord.x / resolution.x, gl_FragCoord.y / resolution.y);
    uv -= 0.5; uv /= vec2(resolution.y / resolution.x, 1);//Boilerplate code building uvs by default in BONZOMATIC
    //Modulo time because I fucking hate noisey sins or whatever the fuck glitches after certain time, hey? (stops it all getting fucking noisy)  
    tt=mod(time,100.);
    
       float as=AN(sin,1.,0.),ac=AN(cos,1.,0.),a2s=AN(sin,.5,.785),a2c=AN(cos,0.5,.785);
    vec3 ro=vec3(as*3.,a2s*25.,a2c*40.), //Camera ro=ray origin, rd=ray direction, co=final color, fo=fog, ld=light direction
    cw=normalize(vec3(0.)-ro),cu=normalize(cross(cw,vec3(0,1,0))),cv=normalize(cross(cu,cw)),
    rd=mat3(cu,cv,cw)*normalize(vec3(uv,.5)),co,fo,lp=vec3(0,0,10);
    co=fo=vec3(.2)*(1.-(length(uv)-.2));//Setting up default background colour and fog colour some shit vignette thing broski
    //light position
    
    lp.y+=(smoothstep(-1.,1.,sin(tt))*2.-1.)*18.;
    lp.z=(0.-(smoothstep(-1.,1.,cos(tt))*2.-1.)*9.);
    //Grabbing the fucking scene by shooting fuckin' rays, because we all wanna gather rays for a living
    sc=tr(ro,rd,0.0001,50.,128);t=sc.x;
  if(t>0.){
    //We hit some geometry so let's get the current position (po) and build some normals (no). You do the Maths while I get some fucking beer.
    vec3 po=ro+rd*t,no=normalize(e.xyy*mp(po+e.xyy).x+e.yxy*mp(po+e.yxy).x+e.yyx*mp(po+e.yyx).x+e.xxx*mp(po+e.xxx).x),    
    
    //LIGHTING MICRO ENGINE BROSKI 
    ld=normalize(lp-po),//We get ld=light direction from light position lp
    //Default albedo is red because punk rock and you're not hot enough (al=albedo)
    al=vec3(.7,.1,.1);     
    //THIS TRICK! Adds some detail to geometry by tweaking the normals. not that much diff this week but still a nice touch.
    no*=(1.+.6*ceil(sin(sp.xyz*2.)));no=normalize(no);
    
    //Different material id? Changeacolourooo... It's all very black and white, makes the red a little punchindaface
    if(sc.y<5.) al=vec3(0);
    if(sc.y>5.) al=vec3(1);
       float attn=1.0-pow(min(1.0,length(lp-po)/20.),4.0), //light attenuation
    //dif = diffuse because I dont have time to cook torrance
    dif=max(0.,dot(no,ld)),
    //ao = ambient occlusion, aor = ambient occlusion range
    aor=t/50.,ao=exp2(-2.*pow(max(0.,1.-mp(po+no*aor).x/aor),2.)),
    //spo=specular power, THIS TRICK is some fucking sweet gloss map generated from recursive noise function. Fuck yeah broski!
    spo=exp2(1.+3.*noise(bp.xyz/vec3(.4,.8,.8))+noise((bp.xyz+1.)/vec3(.2,.4,.4))),
          
    //Fresnel blends the geometry in the background with some sort of gradient edge reflection colouring mother fucker
    fresnel=pow(1.+dot(no,rd),4.); // yeah i know it should be reflected but i don't give a shit broski and the background is a vignette, so fuck you
    //Fake sub surface fucking scattering, sort of reverse ambient occlusion trick from tekf, big up tekf! https://www.shadertoy.com/view/lslXRj
    vec3 sss=vec3(.5)*smoothstep(0.,1.,mp(po+ld*0.4).x/0.4),
    //spec=specular with the spo gloss map above, yeah broski, it's a thing of fucking beauty.
    spec=vec3(2.0)*pow(max(dot(reflect(-ld,no),-rd),0.),spo);
    co=mix((spec+al*(0.8*ao+0.2)*(dif+sss))*attn,fo,fresnel*.3);//Ultimate final lighting result
  }
  co=mix(co,fo,1.-exp(-.00002*t*t*t));//Add some fucking fog to blend it even more, get cosy, stay on your branch.

   float st=0.1+length(ro-lp)*0.02,s=0.,//fract(sin((dot(uv, vec2(1.2, 3.3))))*43578.5453)*0.5,
    vol = 0.0;
    for(int i = 0; i <40; i++) {
        if(s>t&&t>0.) break;
        vec3 pos=ro+rd*s;      
        float dis=length(lp-pos),
        g=tr(pos,normalize(lp-pos),0.2,dis,20).x,
        l =step(0.0, (g < dis) ? -g : 1.);        
        l *=.3/dis;
        vol+=l; s+=st;
    } co+=vec3(0.6,0.42,0.3)*vol;
  if(length(lp-ro)<t||t==0.) co+=1.6*pow(max(dot(normalize(lp-ro),rd),0.),150.);
  //Add some sort of tone mapping... but just like a Hipster's beards and boating shoes: it's not the real thing
  glFragColor = vec4(pow(co,vec3(0.45)),1);
}
