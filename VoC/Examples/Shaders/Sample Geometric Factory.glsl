#version 420

// original https://www.shadertoy.com/view/fs33DM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Code by Flopine

// Thanks to wsmind, leon, XT95, lsdlive, lamogui, 
// Coyhot, Alkama,YX, NuSan, slerpy, wwrighter 
// BigWings and FabriceNeyret for teaching me

// Thanks LJ for giving me the spark :3

// Thanks to the Cookie Collective, which build a cozy and safe environment for me 
// and other to sprout :)  
// https://twitter.com/CookieDemoparty

#define PI acos(-1.)
#define TAU (2.*PI)

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define crep(p,c,l) p-=c*clamp(round(p/c),-l,l)
#define cyl(p,r,h) max(length(p.xy)-r,abs(p.z)-h)

#define frt(sp,off) fract((time+off)*sp)
#define flt(sp,off) floor((time+off)*sp)

struct obj{
    float d;
    vec3 sha;
    vec3 li;
};

obj minobj (obj a, obj b)
{if(a.d<b.d)return a; else return b;}

float box (vec3 p, vec3 c)
{
    vec3 q = abs(p)-c;
    return min(0.,max(q.x,max(q.y,q.z)))+length(max(q,0.));
}

float sc (vec3 p, float d)
{
    p = abs(p);
    p = max(p,p.yzx);
    return min(p.x,min(p.y,p.z))-d;
}

obj grid (vec3 p)
{
    crep(p.xz,8.,2.);
    float per=1.;
    crep(p,per,2.);
    float d = max(-sc(p,per*0.34),box(p,vec3(per*0.4)));
    obj scene = obj(d,vec3(0.),vec3(1.));
    
    return scene;  
}

float pipe (vec3 p, float pid)
{
    float d = cyl(p,0.15,20.);
    
    float per = 1.5, id = round(p.z/per), speed=1., off=id*0.1,
    anim=(TAU/4.)*(flt(speed,off)+pow(frt(speed,off),6.));
    crep(p.z,per,6.);
    p.xy *= (mod(pid,2.)<0.5)?rot(anim):rot(-anim);
    d = min(d,cyl(p,0.2, 0.15));
    d = min(d, cyl(p.xzy,0.065,0.4));
    d = min(d, cyl(p.yzx,0.065,0.4));
    
    return d; 
}

obj SDF (vec3 p)
{
    p.yz *= rot(-atan(1./sqrt(2.)));
    p.xz *= rot(PI/4.);
    vec3 pp = p;
    obj scene = grid(p);
    
    p.y -= 1.;
    float p1id = round(p.x/2.);
    crep(p.x, 2., 5.);
    scene = minobj(scene,obj(pipe(p,p1id),vec3(0.2,0.,0.),vec3(1.,0.5,0.9)));
    
    p=pp;
    p.y += 1.;
    float p2id = round(p.z/2.);
    crep(p.z,2.,5.);
    scene = minobj(scene,obj(pipe(p.yzx,p2id),vec3(0.,0.,0.1),vec3(0.,1.,0.5)));
    
    return scene;
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

    vec3 ro=vec3(uv*5.,-30.),rd=vec3(0.,0.,1.),p=ro,
    col=vec3(0.),l=normalize(vec3(2.,3.,-3.));
    
    bool hit=false; obj O;
    for(float i=0.;i<64.;i++)
    {
        O = SDF(p);
        if (O.d<0.001)
        {hit=true; break;}
        p += O.d*rd;
    }

    if (hit)
    {
        vec3 n = getnorm(p);
        float light = max(dot(n,l),0.);
        float ao = AO(0.1,p,n)+AO(0.3,p,n)+AO(0.5,p,n);
        col = mix(O.sha,O.li,light)*ao/3.;
    }
    
    glFragColor = vec4(sqrt(col),1.0);
}
