#version 420

// original https://www.shadertoy.com/view/fdsczl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))

//global-everything
vec3 cp,cn,cr,ro,rd,cc,oc,fc,ss,gl;
float tt=0.,cd,sd=1.,ot,ct=1.,iv=1.,io=1.5,lp;

//box + infinite cylinder + smooth min
float bx(vec3 p,vec3 s){vec3 q=abs(p)-s;return min(max(q.x,max(q.y,q.z)),0.)+length(max(q,0.));}
float cy(vec3 p, vec2 s){p.y+=s.x/2.;p.y-=clamp(p.y,0.,s.x);return length(p)-s.y;}
float smin(float a, float b, float k){float h=clamp(0.5+0.5*(b-a)/k,0.,1.);return mix(b,a,h)-k*h*(1.-h);}

//scene
float mp(vec3 p)
{
    float id=floor(p.x/5.)+lp; //flower ID
    p.y+=2.;p.x=mod(p.x,5.)-2.5; //move everything up slightly and duplicacte horizontally
    p.xz+=sin(tt*0.2+id)*vec2(0.2);//wiggle things around horizontally because yes
    p.xz*=rot((tt*0.2+id)*(mod(id,2.)==0.?1.:-1.)); //rotate each complete flower slowly
    vec3 pp=p;p.xz+=sin(p.yy*vec2(0.8,1.2))*0.15; //add waviness to Y position for stem
    float st=cy(p+vec3(0,2,0),vec2(6.5,0.3)); //create stem
    float stc=cy(p+vec3(0,2,0),vec2(5,0.1)); //create stem centre for the fake sss
    p.y=min(max(mod(p.y,1.)-.5,p.y-0.5),p.y+4.5); //duplicate a bound section vertically (so that the thorns don't go too far up or down)
    p.xy*=rot(sin(floor(p.y-0.5)+floor(pp.y)*2.5)*0.3); //rotate thorns semi-randomly around Z, using bounds so things don't turn into a mess
    p.xz*=rot(pp.y); //rotate thorns semi-randomly around Y
    float th=mix(length(p)+cos(pp.y+p.x)*0.1,length(p.zy)-0.18,0.8)*0.7; //create thorns by mixing infinite cylinders towards a single point
    st=smin(st,th,0.1);p=pp; //smooth min the thorns into the stem
    vec3 of=vec3(0.12,-1.8,0.18); //offset for flower head to align it with stem
    float an=cos(tt*0.2+id)-1.; //animation for flower head opening
    p+=of+vec3(0,an,0); //adjust position for flower head
    float pe=bx(p,vec3(0.1)); //create initial box that gets kifs'd into the flower head
    float sc=0.1; //scale factor to change box sizes across iterations
    for(float i=0.;i<4.;i++) //kifs!
    {
        p.xz=abs(p.xz)-0.3; //duplicate
        p.xz*=rot(i+0.7+id*3.+tt*0.05); //rotate
        p.yz*=rot(-0.15+sin(id+tt*0.1)*0.05); //rotate but around a different axis
        pe=min(pe,bx(p-vec3(0,length(p)*0.1,0),vec3(sc,sc,0))-0.02); //add current iteration
        sc+=length(p)*0.2; //adjust scale
    }
    float fcn=length(pp+vec3(0,0.5,0)+of); //centre for flower head
    pe=mix(pe,fcn-1.6,0.5); //mix kifs towards centre sphere to spherify it and make it look nice
    sd=min(pe,st); //combine stem and flower head into scene
    //flower head colours... these took a long time to get working properly
    vec3 fcs = mix(normalize(p.xzz*p.zzz),mix(normalize(p.xxy*p.yyy),normalize(p.yxz*p.yyz),sin(id*10.+tt*0.2)*0.5+0.5),cos(id*10.+tt*0.2)*0.5+0.5);
    vec3 stcs=mix(vec3(0.3,0.6,0.2),vec3(0.1,0.3,0.8),sin(id*3.+tt)*0.5+0.5);//stem colours based on ID and time
    gl+=0.001/(0.001+sd*sd)*(stc<fcn*0.7?stcs:fcs)*0.004; //add glow colour based on things
    if(sd<0.001) //inside-scene-material-settings TM
    {
        oc=stc<fcn*0.9?vec3(0.2,0.6,0.2):vec3(0.9,0.7,0.8); //base colour
        ss=stc<fcn*0.7?pow(stc*5.,2.)*vec3(0.2,0.2,0.2):pow(fcn*0.7,5.)*vec3(0.1); //fake sss
        ot=1.-(fcn<stc?pow(fcn,8.)*0.01:0.2); //transmission (inverse opacity)
    }
    return sd; //return distance
}

//raymarch loop + normalse calculation
void tr(){cd=0.;for(float i=0.;i<222.;i++){mp(ro+rd*cd);sd*=iv;cd+=sd;if(sd<0.0001||cd>16.)break;}}
void nm(){mat3 k=mat3(cp,cp,cp)-mat3(.0001);cn=normalize(mp(cp)-vec3(mp(k[0]),mp(k[1]),mp(k[2])));}

//make things get have colors yes thanks
void px()
{
  cc=vec3(0.3,0.45,0.7)+length(pow(cr,vec3(3)))*0.4+gl; //background
  if(cd>16.)return;//we are in the background now
  vec3 l=vec3(0.4,0.9,0.7);//light
  float df=length(cn*l);//diffuse kinda thing
  float fr=pow(1.-df,2.)*0.8;//fresnel
  float sp=(1.-length(cross(cr,cn)))*0.6;//specular
  float ao=min(mp(cp+cn*0.3)-0.3,0.3)*0.9;//ambient occlusion, gotta turn it right up for this one
  cc=oc*(df+fr+ss)+fr+sp+ao+gl;//mixify
}

//main or whatever
void main(void)
{
  tt=mod(time+160., 360.);lp=floor(time/360.);//time. time for what? time for shadering.
  vec2 uv=vec2(gl_FragCoord.xy.x/resolution.x,gl_FragCoord.xy.y/resolution.y);//yeah yeah centred UVs we get the idea
  uv-=0.5;uv/=vec2(resolution.y/resolution.x,1);//but like, actually centred now
  ro=vec3(0,4,-10);rd=normalize(vec3(uv+vec2(0,-0.5),1.));//we need a camera and a direction to look so we do that here
  for(int i=0;i<4*2;i++)//this just like... loops for a while and makes things transparent eventually
  {
     tr();cp=ro+rd*cd;nm();cr=rd;ro=cp-cn*(0.01*iv);//raymarch and do things
     rd=refract(cr,cn*iv,iv>0.?1./io:io); //refract or something
     if(length(rd)==0.)rd=reflect(cr,cn*iv); //reflect if the refraction didn't refract and needs reflecting instead
     px();iv*=-1.;if(iv<0.)fc=mix(fc,cc,ct); //figure out the colour for this surface and do stuff
     ct*=ot;if(ct<=0.||cd>16.)break; //check if we need to get out of the loop, get out of it if we do, don't if we don't
  }
  glFragColor = vec4(pow(fc,vec3(1.2)),1.); //set final colour
}
