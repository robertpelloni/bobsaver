#version 420

// original https://www.shadertoy.com/view/7scSDN

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

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define hash21(x) fract(sin(dot(x,vec2(13.5,24.8)))*164.5)

struct obj {
    float d;
    vec3 sha;
    vec3 li;
};

obj objmin(obj a, obj b)
{
    if(a.d<b.d) return a;
    else return b;
}

vec2 edge (vec2 p)
{
    vec2 p2 = abs(p);
    return (p2.x>p2.y)?vec2((p.x<0.)?-1.:1.,0.):vec2(0.,(p.y<0.)?-1.:1.);
}

float box (vec3 p, vec3 c)
{
    vec3 q = abs(p)-c;
    return min(0.,max(q.x,max(q.y,q.z)))+length(max(q,0.));
}

float sc (vec3 p, float d)
{
    p = abs(p);
    p=max(p,p.yzx);
    return min(p.x,min(p.y,p.z))-d;
}

obj prim1 (vec3 p, vec3 size, vec2 id)
{
    obj p1 = obj(max(-sc(p,size.x*0.9),box(p,size)), vec3(0.1,0.,0.15), vec3(0.95,0.25,0.5));
    obj p2 = obj(length(p-vec3(0.,1.5,0.))-max(hash21(id)*0.45,0.1), vec3(0.1,0.,0.6), vec3(0.1,0.8,0.4));
    return objmin(p1,p2);
}

obj SDF (vec3 p)
{
    p.yz*=rot(-atan(1./sqrt(2.)));
    p.xz *= rot(PI/4.);
    p.z -= time;
    
    float size = 0.45;
    vec2 center = round(p.xz),
    neigh = center+edge(p.xz-center);
    
    obj me = prim1(p-vec3(center.x,0.,center.y),vec3(size,max(hash21(center)*2.,0.1),size),center),
    next = obj(box(p-vec3(neigh.x,0.,neigh.y),vec3(size,2.,size)),vec3(0.),vec3(0.));
    
    return objmin(me,next);
}

vec3 getnorm (vec3 p)
{
    vec2 eps = vec2(0.001,0.);
    return normalize(SDF(p).d-vec3(SDF(p-eps.xyy).d,SDF(p-eps.yxy).d,SDF(p-eps.yyx).d));
}

float AO (float eps, vec3 p, vec3 n)
{return clamp(SDF(p+eps*n).d/eps,0.,1.);}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec3 ro = vec3(uv*5.,-30.), rd=vec3(0.,0.,1.),p=ro,
    col=vec3(0.), l=normalize(vec3(1.,2.,-2.));
    
    bool hit = false; obj O;
    for (float i=0.; i<100.;i++)
    {
        O = SDF(p);
        if (O.d<0.001)
        {hit=true;break;}
        p += O.d*rd;
    }
    
    if (hit)
    {
        vec3 n = getnorm(p);
        float light = max(dot(n,l),0.0);
        float ao = AO(0.1,p,n)+AO(0.15,p,n)+AO(0.4,p,n);
        col = mix(O.sha, O.li, light)*ao/3.;
    }

    glFragColor = vec4(sqrt(col),1.0);
}
