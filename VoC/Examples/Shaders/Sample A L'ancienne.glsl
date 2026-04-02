#version 420

// original https://www.shadertoy.com/view/wlKSR1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Code by Flopine
// Thanks to wsmind, leon, XT95, lsdlive, lamogui, Coyhot, Alkama and YX for teaching me
// Thanks LJ for giving me the love of shadercoding :3

// Thanks to the Cookie Collective, which build a cozy and safe environment for me 
// and other to sprout :)  https://twitter.com/CookieDemoparty

#define PI 3.141592
#define TAU (2.*PI)
#define ITER 64.
#define st (time*0.5)

float hash21 (vec2 x)
{return fract(sin(dot(x,vec2(12.4,65.14)))*1245.4);}

mat2 rot (float a)
{return mat2(cos(a),sin(a),-sin(a),cos(a));}

void mo (inout vec2 p, vec2 d)
{
    p = abs(p)-d;
    if (p.y>p.x) p = p.yx;
}

float box (vec3 p, vec3 c)
{
    vec3 q = abs(p)-c;
    return min(0.,max(q.x,max(q.y,q.z))) + length(max(q,0.));
}

float cyl (vec2 p, float r)
{return length(p)-r;}

float sc (vec3 p, float d)
{
    p = abs(p);
    p = max(p.xyz, p.yzx);
    return min(p.x,min(p.y,p.z))-d;
}

float bid;
float g1 = 0.;
float SDF (vec3 p)
{
    float per = 7.;
    bid = floor(p.z/per);
    p.z = mod(p.z, per)-per*0.5;
    float anim = (mod(bid,2.)==0.) ? bid+st : bid-st; 
    p.xy *= rot(anim);
    p.xz *= rot(PI/2.);
    mo(p.yz, vec2(2.));
    mo(p.xz, vec2(1.));
    p.x -= sin(time)*0.6;
    float d = max( 
            abs(
            max(
                -max(-sc(p, .3), box(p, vec3(1.))),
                box(p,vec3(1.5,1.5,0.5))
                )
               )
            -0.04,
            abs(p.z)-0.4
                );
    g1 += 0.01/(0.01+d*d);
    return d;
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;

    float dith = hash21(uv);
    
    vec3 ro = vec3(0.001,0.001,-7.+time),
        p=ro,
        rd = normalize (vec3(uv,1.)),
        col = vec3(0.);
        
    float shad =0.;
    bool hit = false;
    
    for (float i=0.;i<ITER;i++)
    {
        float d = SDF(p);
        if (d<0.001)
        {
            hit = true;
            shad = i/ITER;
            break;
        }
        d *= 0.8+dith*0.15;
        p += d*rd;
    }
    
    if (hit)
    {
        float glow = (mod(bid,2.) == 0.) ? g1*0.2 : shad*0.5;
        col = vec3(0.8,0.3,0.1)*glow;
    
    }
    // Output to screen
    glFragColor = vec4(col,1.0);
}
