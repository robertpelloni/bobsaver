#version 420

// original https://www.shadertoy.com/view/sscSDn

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

// Still exploring repetition trick presenting by Blackle on Perfect Pistons <3 
// https://youtu.be/I8fmkLK1OKg
// https://www.shadertoy.com/view/WtXcWB

#define PI acos(-1.)
#define TAU (2.*PI)
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))

#define od(p,d) (dot(p,normalize(sign(p)))-d)
#define hash21(x) fract(sin(dot(x,vec2(13.4,32.7)))*134.5) 

vec2 edge (vec2 p)
{
    vec2 p2 = abs(p);
    return (p2.x>p2.y) ? vec2((p.x<0.) ? -1. : 1., 0.) : vec2(0., (p.y<0.) ? -1. : 1.);
}

float box (vec3 p, vec3 c)
{
    vec3 q = abs(p)-c;
    return min(0.,max(q.x,max(q.y,q.z)))+length(max(q,0.));
}

float sc (vec3 p, float d)
{
    p = max(abs(p),abs(p.yzx));
    return min(p.x, min(p.y,p.z))-d;
}

float g1=0.;
float prim1 (vec3 p, float size) 
{
    float odile = od(p,size*.75);
    g1 += 0.001/(0.001+odile*odile);
    return min(odile,
                max(-sc(p,size*.75),
                     box(p,vec3(size))
                   )
               );
}

vec2 center;
float SDF (vec3 p)
{
    p.yz *= rot(-atan(1./sqrt(2.)));
    p.xz *= rot(PI/4.);
    
    vec2 id = floor(p.yz)+.5;
    p.y += (mod(id.y,2.)<=0.5) ? time*0.2 : -time*0.2;
    center = floor(p.yz)+.5; 
    vec2 neighbour = center+edge(p.yz-center);    
    
    float size = clamp(hash21(center+0.5)/2.,0.1,0.36),
    me = prim1(p-vec3(0.,center),size),
    next = box(p-vec3(0.,neighbour),vec3(0.45));
    
    return min(me,next);
}

vec3 getnorm (vec3 p)
{
    vec2 eps = vec2(.001,0.);
    return normalize(SDF(p)-vec3(SDF(p-eps.xyy),SDF(p-eps.yxy),SDF(p-eps.yyx)));
}

float AO (float eps, vec3 p, vec3 n)
{return clamp(SDF(p+eps*n)/eps,0.,1.);}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    float dither = hash21(uv);
    
    vec3 ro = vec3(uv*3.,-30.), rd=vec3(0.,0.,1.), p=ro,
    col = vec3(0.), l = normalize(vec3(1.5,-2.,-2.));

    bool hit = false;
    for (float i=0.;i<100.;i++)
    {
        float d = SDF(p);
        if (d<0.001)
        {hit = true; break;}
        d *= 0.95+dither*0.1;
        p += d*rd;
    }

    if (hit)
    {
        vec3 n = getnorm(p);
        float light = max(dot(n,l),0.), ao = AO(0.1,p,n)+AO(0.2,p,n)+AO(0.38,p,n);
        col = vec3(light)*ao/3.;
    }

    col += g1*0.2*vec3(0.45,.8,hash21(center));

    glFragColor = vec4(sqrt(clamp(col,0.,1.)),1.0);
}
