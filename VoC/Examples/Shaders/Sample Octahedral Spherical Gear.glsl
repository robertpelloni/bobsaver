#version 420

// original https://www.shadertoy.com/view/3tKXR1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//https://www.shadertoy.com/view/XlVcWz nolibab

//#define test

#define Pi 3.141592
#define a1 = 0.25*Pi
#define a2 = 0.5*PI
// 
mat2 mat2rot(float a) {return mat2( cos(a), -sin(a), sin(a), cos(a));}

//
float w(vec3 p,float a, float nt) //wheel
{
nt = float(int(nt));    // number teeth gear
const float rw = 0.58;    // radius wheel   
const float hw = 1.2;    // hight wheel
const float ht = 0.1;    // amplitude hight teeth wheel
const float ct = 0.0000;// shape of the tooth. 1. -> sinus;  0.1 -> rect

a=atan(p.x,p.z)+a; // angle around y-axis + phase r
float o= hw - ht* pow(abs(sin(nt*a)),0.1) * sign(sin(nt*a)); //radius of the wheel rw(a)
return length(p.xz) + p.y*rw*o; //  rw radius of wheel     
}

void main(void)
{
// fragcoord -> Viewportcoord
vec3 o=vec3((2.*gl_FragCoord.xy-resolution.xy)/min(resolution.x,resolution.y),1.);    
// camera     
float v=time;
float sinv = sin(v);
float cosv = cos(v);
vec3 p=3.0*vec3(sinv,0.3,cosv); // scale, rotate object camera target point
vec3 d=normalize(vec3(o.x*cosv+o.z*sinv ,o.y+.3 ,-o.x*sinv+o.z*cosv)-p);
vec3 op=p;
//    
if(abs(o.x)<1.) // sky
glFragColor=vec4(0.,0.,0.,1.);
// raymarch   
for(int i=0;i<120;++i)
{
    float g = 1000000.;
    float nt = 8.; nt *= 2.; nt += 1.; // number teeth odd number
    float ra=time;    // rotation velocity spherical gear
    float rb=ra+Pi/nt; // phase sphericalgear    
    // rotations
    float f1 = 0.305;
    vec3 qz0 = p; qz0.yz *= mat2rot(f1*Pi);    
    vec3 qz1 = p; qz1.zx *= mat2rot(0.5*Pi); qz1.yz *= mat2rot(f1*Pi);
    vec3 qz2 = p; qz2.zx *= mat2rot(1.0*Pi); qz2.yz *= mat2rot(f1*Pi);
    vec3 qz3 = p; qz3.zx *= mat2rot(1.5*Pi); qz3.yz *= mat2rot(f1*Pi);    
    // copy gearcone and rotate it
#ifdef test   
    g=min(g,w(p,ra,nt));
#else    
    //
    g=min(g,w(qz0,ra,nt));
    g=min(g,w(-qz0,rb,nt));
    //
    g=min(g,w(qz1,-ra,nt));
    g=min(g,w(-qz1,-rb,nt));
    //
    g=min(g,w(qz2,ra,nt));
    g=min(g,w(-qz2,rb,nt));
    //
    g=min(g,w(qz3,-ra,nt)); 
    g=min(g,w(-qz3,-rb,nt));
    //
#endif    
    g=max(g,length(p)-.5);  // upper limit sphericalgear radius r < 0.5
    g=max(g,.4-length(p));  // lower limit sphericalgear radius r > 0.4
    
    if(g<.001)
        {
        glFragColor = vec4(1.-float(i)/200.)*(dot(normalize(p),normalize(op))*.4+.6)*vec4(.9,.6,.0,1.);
        break;
        }
    p+=d*.3*g;
    if(distance(p,op)>6.)break;
}
}

