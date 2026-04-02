#version 420

// original https://www.shadertoy.com/view/stSSzy

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
#define TAU 6.283185

#define od(p,d) (dot(p,normalize(sign(p)))-d)

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define crep(p,c,l) p=p-c*clamp(round(p/c),-l,l)
#define rep(p,c) p=(mod(p,c)-c*.5)

#define frt(sp,off) fract((time+off)*sp)
#define flt(sp,off) floor((time+off)*sp)

struct obj
{
    float d;
    vec3 shadowcol;
    vec3 lightcol;
};

obj minobj (obj a, obj b)
{
    if (a.d<b.d) return a;
    else return b;
}

float box (vec3 p, vec3 c)
{
    vec3 q=abs(p)-c;
    return min(0., max(q.x,max(q.y,q.z)))+length(max(q,0.));
}

obj set (vec3 p, vec3 scol, vec3 lcol)
{
    float id = round(p.x/5.);
    crep(p.x, 5., 2.);
    p.y += sin(p.z*0.5)*0.5;
    vec3 pp = p;
    
    rep(p.z,5.);
    float speed = 2.,offset = id*0.2;
    p.yz *= rot(PI/2.*(flt(speed,offset)+pow(frt(speed,offset),1.5)));
    float d = mix(box(p,vec3(.5)),od(p,0.6),0.5); 
    
    p=pp;
    p.z += time;
    p.y += 0.65;
    rep(p.z,1.1);
    d = min(d,box(p,vec3(1.5,0.1,0.5)));
    return obj(d, scol, lcol);
}

obj SDF (vec3 p)
{
    p.yz *= rot(-atan(1./sqrt(2.)));
    p.xz *= rot(PI/4.);
    
    obj d = set(p,vec3(0.1,0.4,0.2),vec3(0.95,0.9,0.3));
    p.xy += vec2(-2.,2.5);
    p.xz *= rot(PI/2.);
    d = minobj(d, set(p,vec3(0.4,0.,0.1),vec3(0.5,0.8,0.9)));
    
    return d;
}

vec3 getnorm (vec3 p)
{
    vec2 eps = vec2(0.001,0.);
    return normalize(SDF(p).d-vec3(SDF(p-eps.xyy).d,SDF(p-eps.yxy).d,SDF(p-eps.yyx).d));
}

float AO (float eps, vec3 n, vec3 p)
{return SDF(p+eps*n).d/eps;}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;

    vec3 ro = vec3(uv*5.,-30.), 
    rd=vec3(0.,0.,1.),
    p=ro,
    col=vec3(0.),
    l=normalize(vec3(2.,3.,-2.));
    
    bool hit = false; 
    obj O;
    
    for (float i=0.;i<100.;i++)
    {
        O = SDF(p);
        if (O.d<0.001)
        {
            hit = true; break;
        }
        p += O.d*rd*0.8;
    }
    
    if (hit)
    {
        vec3 n = getnorm(p);
        float li = max(dot(n,l),0.);//*.5+.3;
        float ao = AO(0.1,n,p) + AO(0.4,n,p) + AO(0.3,n,p);
        col = mix(O.shadowcol,O.lightcol,li)*ao/2.5;
    }
    
    glFragColor = vec4(sqrt(col),1.0);
}
