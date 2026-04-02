#version 420

// original https://www.shadertoy.com/view/NtsGW7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define SS(a,b,t) smoothstep(a,b,t)
const int MAX_STEPS=70;
const float MAX_DIS=100.;
const float MIN_DIS=.01;
vec4 s;//sphere
float plane=-5.3;//plane height
const int LIGHT_NUM=3;
const int nid=0;//nothing id
const int pid=1;//plane id
const int sid=2;//sphere id
mat2 rotMat;
struct Light
{
    vec3 pos;
    vec3 col;
};
Light lig[3];//light pos 
void initEnv()
{
    lig[0].pos=vec3(0.,5.,0.);
    lig[0].col=vec3(.5);
    lig[1].pos=vec3(2.,8.,2.);
    lig[1].col=vec3(0.,0.,1.);
    lig[2].pos=vec3(-2.,8.,-2.);
    lig[2].col=vec3(1.,.3,0.);
    s=vec4(0.,1.,0.,2.);
}
#define DREMAP(type)\
type remap(float a,float b,float x,float y,type t)\
{return (t-a)/(b-a)*(y-x)+x;}\
type remapS(float x,float y,type t)\
{return remap(-1.,1.,x,y,t);}
DREMAP(float)
DREMAP(vec3)

//----------------------Camera------------------------
struct Cam
{
    vec3 ro;
    vec3 lookat;
    vec3 lookdir;
    vec3 fr;
    vec3 ri;
    vec3 up;
}cam;
void setCam(out Cam cam,vec3 ro,vec3 lookat)
{
    cam.ro=ro;
    cam.lookat=lookat;
    cam.lookdir=normalize(lookat-ro);
    cam.fr=cam.lookdir;
    cam.ri=cross(vec3(0.,1.,0.),cam.fr);
    cam.up=cross(cam.fr,cam.ri);
}
//----------------------------------------------------

//----------------------RayMarch----------------------
struct Hit
{
    int id;
    vec3 pos;
    vec3 norm;
};
float getDist(vec3 pos)
{
    float sd=length(pos-s.xyz)-s.w;
    vec3 pPos=pos;
    pPos.xy=rotMat*pos.xy;
    float pd=pPos.y-plane;
    return min(sd,pd);
}
int getId(vec3 pos)
{
    float minDis=MAX_DIS;
    int id;
    float sd=length(pos-s.xyz)-s.w;
    vec3 pPos=pos;
    pPos.xy=rotMat*pos.xy;
    float pd=pPos.y-plane;
    if(pd<minDis)
    {
        minDis=pd;
        id=pid;
    }
    if(sd<minDis)
    {
        minDis=sd;
        id=sid;
    }
    if(minDis>2.*MIN_DIS)
        id=0;
    return id;
}
float rayMarch(vec3 ori,vec3 dir)
{
    dir=normalize(dir);
    float eod=0.;
    for(int i=0;i<MAX_STEPS;i++)
    {
        vec3 curPos=ori+dir*eod;
        float d=getDist(curPos);
        eod+=d;
        if(abs(d)<MIN_DIS||eod>MAX_DIS) break;
    }
    return eod;
}
vec3 getNormal(vec3 pos)
{
   vec2 e=vec2(.01,.00);
   //getDist is the mapping D=f(x,y,z),
   //so the following code finds its gradient by grad(f)=(dD/dx,dD/dy,dD/dz)
   //the gradient point to the direction where the dist increases fastest
   vec3 normal=getDist(pos)-
   vec3(getDist(pos-e.xyy),
       getDist(pos-e.yxy),
       getDist(pos-e.yyx));
   return normalize(normal);
}
vec3 getLight(Hit h)
{
    float ambient=.3;
    //diffuse
    vec3 diff=vec3(0.)+ambient;
    for(int i=0;i<LIGHT_NUM;i++)
    {
        vec3 ld=normalize(lig[i].pos-h.pos);
        float tdiff=clamp(dot(h.norm,ld),0.,1.);
        
        //shadow
        h.pos+=h.norm*MIN_DIS*2.;//take out from attach point
        if(rayMarch(h.pos,ld)<length(lig[i].pos-h.pos)-MIN_DIS*2.)
        {
            tdiff*=.1;
        }
        diff+=tdiff*lig[i].col;
    }      
    return min(diff,1.);
}
Hit rayCast(vec3 ro,vec3 rd)
{
    Hit h;
    float len=rayMarch(ro,rd);
    if(len>MAX_DIS) len=MAX_DIS;
    h.pos=ro+rd*len;
    h.norm=getNormal(h.pos);
    h.id=getId(h.pos);
    return h;
}
//----------------------------------------------------

//----------------------hexCoord----------------------
float hexDist(vec2 p)
{
    p=abs(p);
    float d=dot(p,normalize(vec2(1.,1.732)));
    d=max(d,p.x);//p.x=dot(p,normalize(vec2(1.,0.)));
    return d;
}
vec4 hexCoord(vec2 uv)
{
    vec2 r=vec2(1.,1.732)*2.;
    vec2 auv=mod(uv,r)-.5*r;
    vec2 buv=mod(uv-.5*r,r)-.5*r;
    vec2 guv=length(auv)<length(buv)?auv:buv;
    
    vec2 id=round(uv-guv);
    vec2 polar=vec2(hexDist(guv),atan(-guv.y,-guv.x)/6.2832+.5);
    vec4 coord=vec4(polar.x,polar.y,id.x,id.y);
    return coord;    
}
//----------------------------------------------------

float random21(vec2 p)
{
    return fract(sin(27.*p.x+137.*p.y)*7492.);
}
vec3 getShade(Hit h)
{
    if(h.id==0)
        return vec3(0.);
    vec3 diff=getLight(h);
    vec3 col;
    if(h.id==pid)
    {
        float scale=3.;
        vec4 hc=hexCoord(h.pos.xz/scale);
        vec3 hcpos;
        hcpos.xz=hc.zw*scale;
        hcpos.y=plane;
        float hcr=min(1.,length(s.xyz-hcpos)/10.);
        col=vec3(step(hc.x,.98*hcr));
        if(hcr<.98)
            col*=vec3(.45,.75,1.);
        float hcyt=hc.y+time+random21(hc.zw)*6.28;
        
        col*=remapS(.5,.7,sin(vec3(hcyt,hcyt*2.,hcyt*4.)));

    }
    else if(h.id==sid)
        col=vec3(.8,.8,0.);
    return col*diff;
}

void main(void)
{
    
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    float t=time;
    float a=3.1415*remapS(0.,.05,sin(t));
    float rc=cos(a);
    float rs=sin(a);
    rotMat=mat2(rc,-rs,rs,rc);
    initEnv();
    
    float camMovR=remapS(30.,50.,sin(t*.8));
    float camMovH=remapS(8.,15.,sin(cos(t*.2)*10.));
    vec3 ro=vec3(sin(t)*camMovR,camMovH,cos(t)*camMovR);
    setCam(cam,ro,vec3(0.));
    vec3 rd=normalize(cam.ri*uv.x+cam.up*uv.y+cam.fr);
            
    //scene manage
    lig[1].pos+=vec3(sin(t*2.),0,cos(t*3.))*30.;
    lig[2].pos+=vec3(cos(t*4.),0,sin(t*2.))*30.;
    s.y+=remapS(0.,3.,sin(sin(t)*15.));
    s.xz+=vec2(sin(t*3.),cos(t*3.))*remapS(5.,20.,sin(t));
    
    //rayMarch
    Hit h=rayCast(cam.ro,rd);  
    
    //shade
    glFragColor.rgb=getShade(h);
    
    //post
    
}
