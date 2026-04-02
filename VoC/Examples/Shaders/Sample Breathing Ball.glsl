#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tlBBRy

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//distortion settings
#define RECURSION 7
#define ROTFACT 1.85

//render settings
#define STEPSHRINK 3.5
#define MAXSTEPS 1200
#define CAMDIST 40.
#define CAMSTRT vec2(-0.05,0.)

#define HITDIST 1.e-3
#define MAXDIST 100.

//misc
#define pi atan(1.0) * 4.0
#define ZERO min(frames,0)
#define PLANEH -20.

//light and shadow
#define AMBIENT 0.65 
#define SUNLIGHT vec3(.7,.6,.5)*1.9
#define SHADQUAL .2
#define SHADSMOOTH 5.
//ambient occlusion
#define AO 1. //comment this line to disable ambient occlusion
#define AODIST 1.85
#define AOSTEPS 5
#define AOPOW 1.

struct CastResult
{
    vec3 pos; //hit location
    vec3 norm; //surface normal
    vec3 surf; //surface material/albedo
};
    
struct DirLight
{
  vec3 dir;
    vec3 col;
};

//Returns a rotation matrix for the given angles around the X,Y,Z axes.
mat3 Rotate(vec3 angles)
{angles=angles.yxz;
    vec3 c = cos(angles);
    vec3 s = sin(angles);
    
    mat3 rotX = mat3( 1.0, 0.0, 0.0, 0.0,c.x,s.x, 0.0,-s.x, c.x);
    mat3 rotY = mat3( c.y, 0.0,-s.y, 0.0,1.0,0.0, s.y, 0.0, c.y);
    mat3 rotZ = mat3( c.z, s.z, 0.0,-s.z,c.z,0.0, 0.0, 0.0, 1.0);
        return rotX*rotY*rotZ;
    }

mat3 Rotate(float a1,float a2,float a3){
 return Rotate(vec3(a1,a2,a3));   
}
//generates a rotation matrix that rotates (0,0,1) to face in the same
//direction as dir.
mat3 camRotation(vec3 dir){
    dir=normalize(dir);
    float xRot=atan(dir.z,dir.x)-pi/2.;
    float yRot=atan(dir.y,length(dir.xz));
    return Rotate(vec3(xRot,yRot,0));
}

//signed distance for the warped ball. higher levels of domain distortion
//from RECURSION or ROTFACT must be offset with greater value for STEPSHRINK
//to avoid the rayMarcher overshooting
float sdWarp( vec3 p)
{
    for(int i=1;i<RECURSION;i++){
        mat3 rotation=Rotate(normalize(p)*ROTFACT*sin(float(frames)/40.));
        p=p*rotation+vec3(0,1,0);
    }
    return length(p)-17.;
}

float distToScene(vec3 pos){
    float plane=pos.y-PLANEH;
    float result= (sdWarp(pos));
    result=min(result,plane);
    return result;
}
//calculate the norm by sampling the distance field around pos
//lifted from an iq raymarcher
vec3 calcNorm(vec3 pos){
        vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 1.*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*distToScene(pos+0.00005*e);
    }
    return normalize(n);
}

//clever ambient occlusion trick described here:
//https://www.iquilezles.org/www/material/nvscene2008/rwwtt.pdf
float ambientOcclusion(vec3 pos,vec3 normal){
    #ifdef AO
    float occlusion=0.;
    float itC=0.;
    for(int i=1;i<AOSTEPS;i++){
     itC++;
     float term=itC*AODIST-distToScene(pos+normal*AODIST*itC);
        occlusion+=1./pow(2.,itC)*term;
    }
    return 1.-clamp(AOPOW*occlusion/AODIST,0.,1.);
    #else
    return 1.;
    #endif
}

//cast a new ray from surface.pos and see if you hit anything 
//on your way to sun
float occlusion(CastResult surface,DirLight sun){
    vec3 rayOri=surface.pos+surface.norm*HITDIST*2.;//the ray starts from just above the surface of the hit.
    vec3 rayPos=rayOri;
    bool hit=false;
    float result=1.;
    for(int steps=ZERO;steps<MAXSTEPS&&(!hit)&&length(rayPos-rayOri)<MAXDIST;steps++){
        float dts=distToScene(rayPos);
        hit=dts<HITDIST;
        result=min(result,SHADSMOOTH*dts/length(rayPos-rayOri));
        rayPos-=sun.dir*dts/STEPSHRINK*SHADQUAL;
    }
    result=hit ? 0.:result;
    return result;
}

CastResult castRay(vec3 rayOri,vec3 rayVec){
    
    bool hit=false;
    vec3 rayPos=rayOri;
    for(int steps=ZERO;steps<MAXSTEPS&&hit==false&&length(rayPos-rayOri)<MAXDIST;steps++){
        float dts=distToScene(rayPos);//calculate distance to scene
        hit=dts<HITDIST;              //register a hit, if the distance is small
        rayPos+=rayVec*dts/STEPSHRINK;//march the ray
    }
    vec3 norm=calcNorm(rayPos);
    //here the surface color of the ball is adjusted based on ambient occlusion
    vec3 surfCol=vec3(.3);
    surfCol.r+=rayPos.y>.03+PLANEH?(1.-ambientOcclusion(rayPos,norm)):0.;
    surfCol=(length(rayPos-rayOri)>=MAXDIST)? vec3(0.): surfCol;
    return CastResult(rayPos,norm,surfCol);
}
//calculate the light hitting this castResult from sun, and ambient light
vec3 lightOn(CastResult hit,DirLight sun){
    vec3 sunLight=max(0.,(-dot(hit.norm,sun.dir)))*sun.col*occlusion(hit,sun);
    vec3 ambientLight=vec3(AMBIENT*ambientOcclusion(hit.pos,hit.norm));
    return hit.surf*(sunLight+ambientLight);
}
   

void main(void)
{
//Set up the camera
    vec2 mousePos=(length(mouse*resolution.xy.xy)>0.)? mouse*resolution.xy.xy/resolution.xy-.5:CAMSTRT;
    float mouseTheta=mousePos.x*2.*pi;
    float mouseH=mousePos.y*60.+19.;
    vec3 camPos=vec3(cos(mouseTheta)*CAMDIST,mouseH,CAMDIST*sin(mouseTheta));
    vec3 camTarget=vec3(0);
    
//set up lighting
    DirLight sun;
    sun.dir=normalize(vec3(1,-3,0.))*Rotate(vec3(10./5.,0,0));
    sun.col=SUNLIGHT;
    
//set up camera ray
//
//in the middle of the screen, uv.xy ==(0,0),
//so the rotation matrix that rotates (0,0,1) to normalize(camTarget-camPos)
//will point our rays towards camTarget
    mat3 rayRotation=camRotation(camTarget-camPos);
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec3 rayVec=normalize(vec3(uv.x,uv.y,1.)*rayRotation);
    
    
    
    vec3 rayOri=camPos;

    CastResult cRay=castRay(rayOri,rayVec);
    bool inBounds=length(cRay.pos-rayOri)<MAXDIST*.999;
    vec3 finalC=inBounds?lightOn(cRay,sun):vec3(0);
    glFragColor = vec4(finalC,1.0);
}

