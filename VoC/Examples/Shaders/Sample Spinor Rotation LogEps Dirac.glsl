#version 420

// original https://www.shadertoy.com/view/tdXXzl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//parent: is: https://www.shadertoy.com/view/WdfXz2
//-  created by florian berger (flockaroo) - 2019
//-  License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//...saw this on twitter and had to give it a try on shadertoy.
// https://twitter.com/lexfridman/status/1101871948664049664
// original author of the above video seems to be Jason Hise
// https://en.wikipedia.org/wiki/File:Belt_Trick.ogv

//a twisting deformation around rotating space, without tangling up.
//dirac invented it to describe electron spin
//it needs 720 degrees for one full period
//as it oscillates between (over and under) over time
//while avoiding accumulation of twists over time.
//and that needs some getting used to

//this adds more geometry and
//logEps() performs better in twisted space (larger local lipschitz)
//gets closer to surfaces, no matter how deformed space is
//and passes further trough voids and alon near-parallel surfaces.
//logeps() disadvantage is that its not too  good for reflections.
//logEps mainly allows for larger zFar (while there are large voids) and for more twist deformation, without overstepping (as much)

#define zFar 1500.

#define doLogEps
//the core idea of logeps lies within how calculus and logstar() work
//and it uses that to care less for lipschitz continuity and space deformations.

//doLogEps has much better precision within deformed fields.
//- ideal within a Dirac-context ?
//gets closer to surfaces, where it gets better normals
//better at long distances (epsilon increases logarythmically over log(eps*distance*distance/pow(numberOfSteps,1.+n)))<0 ???
//, where n is roughly equal to 1/maxLipschitzConstant
//, where n is the value that you normally multiply d by foreach step, if you have twisted space.
//Stepcount or n can easily be made smaller, on a log scale this is less intuitive and more forgivable.
//Is slower while the camera is close to a surface (might want  to avoid looking along  walls)
//otherwise significantly faster AND more precise
//can traverse further with less steps (especially in deformed space)
//,due to log(eps) scaling AND accumulative overstepping over distance
//that is, in the distance precision does VERY BAD, but that barely matters, due to inverseSquare laws.
//so we like it rough in the distance, in favor of a larger zFar.

//this optionally adds a second tensor around a different axis, with a different speed
//but really, it just needs a quaternion rotation instead!
//and a double buffer to have that quaternion be changed by keyboard input over time.

#define doDobleTension
//rotate around 2 axis  insuccession (this really lacks quaternion rotatiob, theres no excuse!
//i add a second tensor to illustrate how far we can push logeps() here.

//a lot of code in this shader is copied from [blackhole canvas]
//and this could use its quaternion camera 
//to set the rotation within ROT()

#define PI2 (acos(-1.)*2.)

//box distance
float sdBox( vec3 p, vec3 b
){vec3 d = abs(p) - b
 ;return length(max(d,0.0))
        // + min(max(d.x,max(d.y,d.z)),0.0); // +fully signed box (negative inside)
;}

//this REALLY should be quaterion rotation in this context!
//but it only rotates around a static axis
void ROT(float ang,inout vec2 v) { 
    vec2 cs=sin(vec2(1.6,0)+ang); 
    v=mat2(cs,cs.yx*vec2(-1,1))*v;
}

//float sd4chords(vec2 u){ return length(abs(u)-1.)-.2;}

float sd4chords(vec3 u){
          ;float t=time*2.1
     //;u.xy=mix(u.xy,vec2(-u.y,u.x),step(abs(u.y),abs(u.x)))
     //;u.x=abs(u.x);
    ;if(   (u.x)<abs(u.y))u.xy=vec2(-u.y,u.x)
  //;if(abs(u.x)<abs(u.y))u.xy=vec2(-u.y,u.x)
    ;if(   (u.x)<abs(u.z))u.xz=vec2(-u.z,u.x)
  //;if(   (u.x)<abs(u.z))u.xz=vec2(-u.z,u.x)
    ;u.y=abs(u.y)//-2.//+.5*(sin(t)*.5+.5)
    ;u.z=abs(u.z)-2.//-(cos(t)*.5+.5)
 //above 4 lines are diagonal folds AND chord mirrors
//swap [<] for [>], remove ONE [abs] in any line, change oders
//,swivel values, change signs, change oder of lines
 //, to get an intuition for too much symmetry to explain.
    //;u.z=abs(u.z)-2.
     //u.y=abs(u.y)-2.
  
    //; u.yz=abs(u.yz)-(vec2(cos(t),sin(t*1.61))*.5+.5)
   ;return length(u.zy)-.1
       //there are ways to turn athese if() branches into a linear interpolation.
;}

float getDist(vec3 p){
    float d=10000.;
    //float falloff=clamp(1./(1.+.025*max(0.,dot(p,p))),0.,1.);
    float falloff=1.-(smoothstep(2.,20.,length(p)));
    
    

    //float ang=(mouse*resolution.xy.xy/resolution.xy*PI2).x;
    float ang=time;

    // those 3 lines are the core part
    // ...remove them and you'll just have 3 boring sticks and a cube ;-)
    ROT(-ang,p.xy);             // globally rotate around z
    ROT(PI2*.50*falloff,p.yz);   // locally rotate around x by 180 degrees
    ROT(ang,p.xy);              // globally rotate back around z 
    
    #ifdef doDobleTension
    ROT(-ang*.61,p.xz);             // globally rotate around z
    ROT(PI2*.5*falloff,p.zy);   // locally rotate around x by 180 degrees
    ROT(ang*.61,p.xz);              // globally rotate back around z 
#endif
    ;d=min(d,sdBox(p,vec3(2)))//box
        
    ;d=min(d,sd4chords(p))//strings
 ;vec4 t=.1*(vec4(0,1,2,3)+.61)
 ;vec4 e=mix(vec4(2),vec4(0),sin(time*t)*.5+.5)
    ;d=min(d,sdBox(p,vec3(0.,e.x,zFar)));//vertical1
    ;d=min(d,sdBox(p,vec3(e.y,.1,zFar)));//vertical2
    //get special cross-treatment for a gravity bias.
    ;d=min(d,sdBox(p,vec3(zFar,.1,e.z)));
    ;d=min(d,sdBox(p,vec3(.1,zFar,e.w)));
    
   ; return d;
}

vec3 getDerivative(vec3 pos,float eps
){vec3 d=vec3(eps,0,0)
 ;return vec3(
       getDist(pos+d.xyz)-getDist(pos-d.xyz),
        getDist(pos+d.zxy)-getDist(pos-d.zxy),
        getDist(pos+d.yzx)-getDist(pos-d.yzx)
        )/eps/2.;
}

bool cond(float d,float s//t=distanceToCamera s=numberOfmarchingIterations
){//if(1./exp(d)<.01)return s<.001;//better for short distance reflections
    //well, the above line fails within a tensor-distorted gradient...
    //i am still triddling for it
 return log(d*d/s/1e5)>0.
    //return log(d*d/s/.0001)0.
     ;}//better for long distance

//logeps() marching trough a tensor
//this gets trickier to eak, as the strong tensor twist really pushes
//lipschitz continuity to its limits
//my assertion, that lobeps() is a better choice within high lipschitz values
//parely passes, but it passes.
float march(inout vec3 pos, inout vec3 dir       
){
 #ifdef doLogEps
 ;float s=0.
 ;float d=0.;
 ;vec3 p=pos//+1.*dir
 //pos//+1.*dir is optional zNear, logeps is a bit bad when camera is close to a wall
 //, this is easily avoided
 //logeps() shines in LONG distances, not as much in short distances (within large lipschitz)
 //i have plans for a [logNeps], which should be better ingeneral average fractals
 
 ;for(float i=0.;i<1000.;i++ //logeps is fine with 4x as many iterations, it unlikely leads half of them.
 ){if(cond(d,s))return d
  ;s=getDist(p)
  ;d+=s*.15
  ;p=pos+dir*d
 #else
 ;float eps = .0001
 ;float mat=-1.
 ;for(int i=0;i<250;i++
 ){float d=getDist(pos)
  ;pos+=dir*d*.25
   ;if(d<eps)return d

 #endif
 ;}return 0.;}

void main(void)
{float camDist=60.
 ;vec3 camDir = vec3(0,1,0)
 ;vec3 dir = normalize(camDir+vec3((gl_FragCoord.xy-.5*resolution.xy)/resolution.x,0).xzy)
 ;vec2 ang = vec2(.4,-.2)
 ;//if(mouse*resolution.xy.x<.5) ang += vec2(time,time*.3);
    ang += mouse*resolution.xy.xy/resolution.xy*PI2;
    ROT(ang.y,camDir.yz);
    ROT(ang.x,camDir.xy);
    ROT(ang.y,dir.yz);
    ROT(ang.x,dir.xy);
    vec3 pos=-camDir*camDist;
    vec3 camPos = -camDir*10.;
    float d=march(pos,dir);
  
    vec3 n = getDerivative(pos+dir*d,.0001)
   ;
    glFragColor=vec4(n*.5+.5,1);
  ;if(d>zFar*.5) glFragColor=vec4(.1,.3,.7,1);
  //logeps() allows for a larger zFar horizon!
}

