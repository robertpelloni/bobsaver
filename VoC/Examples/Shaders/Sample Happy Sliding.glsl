#version 420

// original https://www.shadertoy.com/view/fssBWn

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

#define crep(p,c,l) p-=c*clamp(round(p/c),-l,l)
#define od(p,d) (dot(p,normalize(sign(p)))-d)

#define dt(off) mod(time+off,8.)
#define anim(x) clamp(asin(sin(x*(PI/4.)))*(PI/2.5), 0., 1.)
#define bounce(off) sqrt(sin(dt(off)*PI))

float box (vec3 p, vec3 c)
{
    vec3 q= abs(p)-c;
    return min(0.,max(q.x,max(q.y,q.z)))+length(max(q,0.));
}

float sc (vec3 p, float d)
{
    p = abs(p);
    p = max(p,p.yzx);
    return min(p.x,min(p.y,p.z))-d;
}

vec2 id;
float SDF (vec3 p)
{
    p.yz *= rot(-atan(1./sqrt(2.)));
    p.xz *= rot(PI/4.);
    
    float per = 2.8;
    id = floor(p.xz/per);
    
    if (mod(id.y,2.)<0.5) p.x += anim(dt(0.))*per;
    else p.x -= anim(dt(0.))*per;
    
    if (mod(id.x,2.)<0.5) p.z += anim(dt(-1.))*per;
    else p.z -= anim(dt(-1.))*per;
    
    p.xz = mod(p.xz, per)-per*.5;   
    
    vec3 pp = p-vec3(0.,bounce(1.)*2.,0.);
    pp.xz *= rot(dt(0.5)*PI);
    
    return min(od(pp,0.2),max(-sc(p, .35),max(sc(p,.45),box(p,vec3(1.)))));
}

vec3 getnorm (vec3 p)
{
    vec2 e = vec2(0.01,0.);
    return normalize(SDF(p)-vec3(SDF(p-e.xyy),SDF(p-e.yxy),SDF(p-e.yyx)));
}

float AO (float eps, vec3 p, vec3 n)
{return SDF(p+eps*n)/eps;}

void main(void)
{   
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;

    vec3 ro=vec3(uv*3.5,-60.), rd=vec3(0.,0.,1.), p=ro,
    col=vec3(0.7,0.9,0.99), l=normalize(vec3(.5,1.,-1.));
    bool hit=false;
    
    for(float i=0.;i<64.;i++)
    {
        float d = SDF(p);
        if (d<0.001)
        {
            hit=true;break;
        }
        p += d*rd*.75;
    }

    if (hit)
    {
        vec3 n = getnorm(p);
        float l = max(dot(n,l),0.);
        float ao = AO(0.02,p,n)+AO(0.03,p,n)+AO(0.08,p,n);
        col = mix(vec3(0.1,0.8,0.5),vec3(0.95,0.9,0.4),l);
        col *= ao/3.;
    }

    glFragColor = vec4(sqrt(col),1.0);
}
