#version 420

// original https://www.shadertoy.com/view/Wsf3zl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////
// WHAT IS THE SHADER SHOWDOWN?

// The "Shader Showdown" is a demoscene live-coding shader battle competition.
// 2 coder battle for 25 minutes making a shader from memory on stage. 
// The audience votes for the winner by making noise or by voting on their phone.
// Winner goes through to the next round until the final where champion is crowned.
// Live coding shader software used is BONZOMATIC made by Gargaj from Conspiracy:
// https://github.com/Gargaj/Bonzomatic

// Every tuesdays around 20:00 UK time I practise live on TWITCH.
// This is the result of session 003. 
// Theme of the day was: MC Esher feat. DJ Confused Domain

// COME SEE LIVE CODING EVERY TUESDAYS HERE: https://www.twitch.tv/evvvvil_

// evvvvil / DESiRE demogroup

vec2 sc,e=vec2(.00035,-.00035);float t,tt;vec3 np;

//Cheap box function bullshit, distilling some of IQ's brain so I can play god
float mx(vec3 p){return max(max(p.x,p.y),p.z);}
float bo(vec3 p,vec3 r){return mx(abs(p)-r);}

//Simple 2d rotate function, nothing to see here, move along, find the shiny piece of candy
mat2 r2(float r) {return mat2(cos(r),sin(r),-sin(r),cos(r));}

//Fucking bits function which make the the fucking bit/piece:
//Essentially the piece is some stairs + walls around + poles nearly as long as my dick
vec2 fb( vec3 p )
{
    p.xz*=r2(0.785*(1.+2.*clamp(sin(tt*.5),-.5,.5)));
    p.xy*=r2(0.785*(1.+2.*clamp(sin(tt*.5),-.5,.5)));
    vec2 h,t=vec2(1000,5);
    for(int i=0;i<7;i++){
        t.x=min(t.x,bo(p+vec3(0,0.2*float(i),0.4*float(i)),vec3(1,.1,0.2)));
    }
    h=vec2(bo(abs(p-vec3(0,-.6,-1.3))-vec3(1,0,0),vec3(0.2,.8,1.6)),3);
    h.x=min(h.x,bo(abs(p-vec3(0,0,-1.4))-vec3(1,0,1),vec3(0.1,6,0.1)));
    t.x=min(t.x,bo(abs(p-vec3(0,-.3,-1.4))-vec3(1,abs(sin(tt*.66))*6.,1),vec3(.15)));
    t=(t.x<h.x)?t:h;
    return t;
}

//Map function / scene / Where the geometry is made. This fucker is centre stage broski
vec2 mp( vec3 p )
{
  p.yz*=r2(0.785*clamp(cos(tt*0.5),-.25,.25)*4.);
  p.z=mod(p.z+tt*6.3,40.)-20.;
  //np=new position. We we symetry clone the fucker, rotate it, shift the bitch, then rotate again till it fucking screams
  np=p;
  for(int i=0;i<5;i++){
      np=abs(np)-vec3(3.9+clamp(sin(tt*.5),-.5,.5),3.7,2);
      np.xy*=r2(.785*float(i)*2.);
      np-=vec3(-2,1,2.5);
      np.xz*=r2(.785*float(i)*3.);
  }
  vec2 t=fb(np);
  return t;
}

//Main raymarching loop with material ID flex
vec2 tr( vec3 ro, vec3 rd )
{
  vec2 h,t=vec2(.1);
  for(int i=0;i<128;i++){
    h=mp(ro+rd*t.x);
    if(h.x<.0001||t.x>60.) break;
    t.x+=h.x;
    //This extra line passes the material id
    t.y=h.y;
  }
  if(t.x>60.) t.x=0.;
  return t;
}

void main(void)
{
    vec2 uv = vec2(gl_FragCoord.x / resolution.x, gl_FragCoord.y / resolution.y);
    uv -= 0.5; uv /= vec2(resolution.y / resolution.x, 1);//Boilerplate code building uvs by default in BONZOMATIC
    //Modulo time because I am god and I fucking decide how long this world lives (not really just stops it all getting fucking noisy)  
    tt=mod(time,100.);
    //Camera simple bullshit thing ro=ray origin, rd=ray direction, co=color, fo=fog colour, ld=light direction
    vec3 ro=vec3(0,0,0),
        cw=normalize(vec3(cos(tt)*2.,5.,sin(tt*.25)*15.)-ro),
        cu=normalize(cross(cw,vec3(0,1,0))),
        cv=normalize(cross(cu,cw)),
        rd=normalize(mat3(cu,cv,cw)*vec3(uv,.5)),co,fo,ld=vec3(.3,.5,-.5);
    //Setting up default background colour and fog colour
    vec3 bk=vec3(.5)*(1.-(length(uv)-.2));co=fo=bk;
    //Grabbing the fucking scene by shooting fuckin' rays, because I am god and I'm the kind of god that shoots fucking rays from his eyes
    sc=tr(ro,rd);
    //Stick scene geometry result in this shorter one char variable. Fast and fucking bulbous, get me?
    t=sc.x;  
  if(t>0.){
    //We hit some geometry so let's get the current position (po) and build some normals (no). Get building broh, grab a fucking shovel
    vec3 po=ro+rd*t,no=normalize(e.xyy*mp(po+e.xyy).x+e.yxy*mp(po+e.yxy).x+e.yyx*mp(po+e.yyx).x+e.xxx*mp(po+e.xxx).x),
    
    //LIGHTING MICRO ENGINE BROSKI 
        
    //Default albedo is yellow because you're still acting like a mango (al=albedo)
    al=vec3(1,.5,0);    
    //Yo different material id? No way broski, change the fucking colours then broh! (al=albedo)
    if(sc.y<5.)al=vec3(.01*ceil(cos(np))+ceil(sin(np.x*1.5)));
    //dif = diffuse because I dont have time to cook torrance
    float dif=max(0.,dot(no,ld)),
    //ao = ambient occlusion, aor = ambient occlusion range
    aor=t/50.,ao=exp2(-2.*pow(max(0.,1.-mp(po+no*aor).x/aor),2.)),
    //spo=specular power, yeah it's dumb as it's 1, but if I had had time to type in noise function this would be a gloss map. Get over it broski
    spo=1.,
    //Fresnel blends the geometry in the background with some sort of gradient edge detection colouring mother fucker
    fresnel=pow(1.+dot(no,rd),4.);
    //Fake sub surface fucking scattering, sort of reverse ambient occlusion trick from tekf, big up tekf! https://www.shadertoy.com/view/lslXRj
    vec3 sss=vec3(.5)*smoothstep(0.,1.,mp(po+ld*0.4).x/0.4),
    //spec=specular again if had had time to type noise function this would be better
    spec=vec3(1)*pow(max(0.,dot(no,normalize(ld-rd))),spo)*spo/32.;
    //Ultimate final lighting result
    co=mix(spec+al*(0.8*ao+0.2)*(dif+sss),bk,fresnel);
    //Add some fucking fog to blend it even more. Don't get even broh, get soft
    co=mix(co,fo,1.-exp(-.00003*t*t*t));
  }
  //Add some sort of tone mapping for cheap byte sized fuckers (not really god in the end then, hey? just some cheap byte sized fucker)
  glFragColor = vec4(pow(co,vec3(0.45)),1);
}
