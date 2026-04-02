#version 420

// original https://www.shadertoy.com/view/WdfXz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// created by florian berger (flockaroo) - 2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

//...saw this on twitter - https://twitter.com/lexfridman/status/1101871948664049664
// and had to give it a try on shadertoy...

//rotation of locally twisted space without tangling up.
//i guess paul dirac invented it for describing electron spin
//needs 720 degrees!!! for one full period

#define PI2 6.28318530718

// inigo quilez's box distance
float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0))
         + min(max(d.x,max(d.y,d.z)),0.0); // remove this line for an only partially signed sdf 
}

void ROT(float ang,inout vec2 v) 
{ 
    vec2 cs=sin(vec2(1.6,0)+ang); 
    v=mat2(cs,cs.yx*vec2(-1,1))*v;
}

float getDist(vec3 p)
{
    float d=10000.;
    //float falloff=clamp(1./(1.+.025*max(0.,dot(p,p))),0.,1.);
    float falloff=1.-(smoothstep(1.,15.,length(p)));
    
    //float ang=(mouse*resolution.xy.xy/resolution.xy*PI2).x;
    float ang=time;
    
    // those 3 lines are the core part
    // ...remove them and you'll just have 3 boring sticks and a cube ;-)
    ROT(-ang,p.xy);             // globally rotate around z
    ROT(PI2*.5*falloff,p.yz);   // locally rotate around x by 180 degrees
    ROT(ang,p.xy);              // globally rotate back around z 

    d=min(d,sdBox(p,vec3(1)));
    d=min(d,sdBox(p,vec3(.1,.8,100)));
    d=min(d,sdBox(p,vec3(100,.1,.8)));
    d=min(d,sdBox(p,vec3(.8,100,.1)));
    return d;
}

vec3 getGradDist(vec3 pos,float eps)
{
    vec3 d=vec3(eps,0,0);
    return vec3(
        getDist(pos+d.xyz)-getDist(pos-d.xyz),
        getDist(pos+d.zxy)-getDist(pos-d.zxy),
        getDist(pos+d.yzx)-getDist(pos-d.yzx)
        )/eps/2.;
}

bool march(inout vec3 pos, inout vec3 dir)
{
    float eps = .0001;
    float mat=-1.;
    for(int i=0;i<250;i++)
    {
        float d=getDist(pos);
        pos+=dir*d*.25;
        if(d<eps) { return true; }
    }
    return false;
}

void main(void)
{
    float camDist=60.;
    vec3 camDir = vec3(0,1,0);
    vec3 dir = normalize(camDir+vec3((gl_FragCoord.xy-.5*resolution.xy)/resolution.x,0).xzy);
    vec2 ang = vec2(.4,-.2);
    //if(mouse*resolution.xy.x<.5) ang += vec2(time,time*.3);
    ang += mouse*resolution.xy.xy/resolution.xy*PI2;
    ROT(ang.y,camDir.yz);
    ROT(ang.x,camDir.xy);
    ROT(ang.y,dir.yz);
    ROT(ang.x,dir.xy);
    vec3 pos=-camDir*camDist;
    vec3 camPos = -camDir*10.;
    bool hit=march(pos,dir);
    vec3 n = getGradDist(pos,.001);
    glFragColor=vec4(n*.5+.5,1);
    if (!hit) glFragColor=vec4(.1,.2,.3,1);
}

