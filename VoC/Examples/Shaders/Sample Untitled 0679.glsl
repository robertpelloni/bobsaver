#version 420

// original https://www.shadertoy.com/view/mlS3Dw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Code by Flopine

// Thanks to wsmind, leon, XT95, lsdlive, lamogui, 
// Coyhot, Alkama,YX, NuSan, slerpy, wwrighter 
// BigWings, FabriceNeyret and Blackle for teaching me

// Thanks LJ for giving me the spark :3

// Thanks to the Cookie Collective, which build a cozy and safe environment for me 
// and other to sprout :)  
// https://twitter.com/CookieDemoparty

#define PI acos(-1.)
#define TAU (2.*PI)

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))

#define BPM (100./60.)
#define speed (BPM/2.)
#define time mod(time, 4.)
#define dt(sp, off) fract((time+off)*sp)
#define ft(sp, off) floor((time+off)*sp)

#define anim(sp, off, st, po) (TAU/st)*(ft(sp,off)+pow(dt(sp,off), po)) 

#define crep(p,c,l) p -= c*clamp(round(p/c), -l, l)

float box (vec3 p, vec3 c)
{
    vec3 q = abs(p)-c;
    return min(0., max(q.x,max(q.y,q.z)))+length(max(q,0.));
}

float prim1 (vec3 p)
{
    float ys = (p.y > .0) ? 1.:-1.,
    xs = (p.x > 0.) ? 1.: -1.,
    zs = (p.z > 0.) ? 1.: -1.;
    
    if (time > 0. && time <= speed) p.yz *= rot(anim(speed, 0.5, 4., 10.)*xs);
    if (time > speed && time <= 2.9*speed) p.xz *= rot(anim(speed, 0.5, 4., 10.)*ys);
    if (time > 2.9*speed && time <= 3.9*speed) p.xy *= rot(anim(speed, 0.5, 4., 10.)*zs);
    
    p = abs(p)-.15;
    
    return box(p,vec3(.1));
}

float SDF (vec3 p)
{
    p.yz *= rot(-atan(1./sqrt(2.)));
    p.xz *= rot(PI/4.);
    
    float per = .9;
    vec3 id = round(p/(per));
   
    if (time > 0.5 && time <= 1.5) p.yz *= rot(anim(speed, id.x*.1, 4., 10.));
    if (time > 1.5 && time <= 2.5) p.xz *= rot(anim(speed, id.y*.1, 4., 10.));
    if (time > 2.5 && time <= 3.9) p.xy *= rot(anim(speed, id.z*.1, 4., 10.));
    
    crep(p, per, 1.);
    
    return prim1(p)-0.02;
}

vec3 gn (vec3 p, float e)
{
    vec2 eps = vec2(e, 0.);
    return normalize(SDF(p)-vec3(SDF(p-eps.xyy),SDF(p-eps.yxy),SDF(p-eps.yyx)));
}

float AO (vec3 p, vec3 n, float e)
{return clamp(SDF(p+e*n)/e, 0., 1.);}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;

    vec3 ro = vec3(uv*2., -30.), rd=vec3(0.,0.,1.), p=ro,
    col=vec3(0.85, 1., .95), l=normalize(vec3(0.1, 1., -2.));
    
    bool hit = false;
    
    for (float i=0.; i<64.; i++)
    {
        float d = SDF(p);
        if (d<0.01)
        {
            hit=true; 
            break;
        }
        p += d*rd*.5;
    }

    if (hit)
    {
        vec3 n = gn(p,1e-3);
        float li = max(dot(n,l), 0.);
        float ao = AO(p,n,0.01)+AO(p,n,0.03)+AO(p,n,0.055);        
        col = mix(vec3(0.75, 0.1, 0.5), vec3(0.45, .9, .99), li);
        col *= ao/3.;
    }

    glFragColor = vec4(sqrt(col),1.0);
}
