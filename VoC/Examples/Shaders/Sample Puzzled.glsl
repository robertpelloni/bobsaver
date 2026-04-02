#version 420

// original https://www.shadertoy.com/view/NlXBWl

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

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define PI acos(-1.)
#define TAU (2.*PI)
#define dt(sp,off) fract((time-off)*sp)
#define bouncy(sp,off) sqrt(sin(dt(sp,off)*PI))

#define hr vec2(1.,sqrt(3.))
#define hex(p) max(abs(p.x),dot(abs(p),normalize(hr)))

struct obj {
    float d;
    int mat_id;
};

obj minobj (obj a, obj b)
{
    if (a.d<b.d) return a;
    else return b;
}

float box (vec3 p, vec3 c)
{
    vec3 q = abs(p)-c;
    return min(0.,max(q.x,max(q.y,q.z)))+length(max(q,0.));
}

float tore (vec3 p, vec2 h)
{
    vec2 q = vec2(length(p.xy)-h.y, p.z);
    q*=rot(atan(q.y,q.x)*3.);
    return hex(q)-h.x;
}

float per = 2.;
obj grid (vec3 p)
{
    p.xz = mod(p.xz,per)-per*.5;
    return obj(tore(p.xzy,vec2(0.3,1.)),1);
}

obj balls (vec3 p)
{
    p.xz -= per*.5;
    vec2 id = floor(p.xz/(per*2.));
    
    float angle = atan(id.y*0.1,id.x*0.1)/(PI*.5);
    float anim = sin(angle+length(id));
    
    p.y -= bouncy(.6,anim)*3.5-1.5;
    p.xz = mod(p.xz, per*2.)-per;
    p.xz *= rot(dt(0.5,id.x)*TAU);
    p.yz *= rot(dt(0.5,id.y)*TAU);
    return obj(dot(p,normalize(sign(p)))-0.3,2);
}

obj cyls (vec3 p)
{
    p.xz += 1.; p.y += .4;
    vec2 id = floor(p.xz/(per*2.));
    p.xz = mod(p.xz, per*2.)-per;
    
    float r = 0.6, thicc = 0.035, c=1e10,
    angle = atan(id.y*0.1,id.x*0.1)/(PI*.5),
    anim = sin(angle+length(id));
    
    for (int i=0; i<3; i++)
    {
        float ratio = float(i)/3.;
        p.y -= bouncy(0.6,ratio*anim)*0.7; 
        c = min(c,max(abs(p.y)-0.2,abs(max(length(p.xz)-r, abs(p.y)-1.))-thicc));
    
        r -= 0.15;
        thicc -= 0.008;
    }
    
    return obj(c,3);
}

obj SDF (vec3 p)
{
    p.yz *= rot(-atan(1./sqrt(2.)));
    p.xz *= rot(PI/4.);
    
    obj scene = grid(p);
    scene = minobj(scene, balls(p));
    scene = minobj(scene, cyls(p));
    
    return scene;
}

vec3 getnorm (vec3 p, float eps)
{
    vec2 e = vec2(eps,0.);
    return normalize (SDF(p).d-vec3(SDF(p-e.xyy).d,SDF(p-e.yxy).d,SDF(p-e.yyx).d) );
}

float AO (float e, vec3 p, vec3 n)
{return SDF(p+e*n).d/e;}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
     
    
    vec3 ro=vec3(uv*5.,-30.), 
    rd=normalize(vec3(0.,0.,1.)),
    p=ro,
    l=vec3(2.,3.,-2.),
    col=vec3(0.,0.02,0.03);
    
    bool hit = false;float shad;obj O;
    
    for (float i=0.; i<64.; i++)
    {
        O = SDF(p);
        if (O.d<0.001)
        {
            hit = true; shad = i/64.; break;
        }
        p += O.d*rd;
    }

    if (hit)
    {
        vec3 n;
        if (O.mat_id == 1) 
        {
            n = getnorm(p,0.1);
            col = vec3(1.);
        }
        
        else if (O.mat_id == 2)
        {
            n = getnorm(p,0.001);
            col = vec3(0.9,0.8,0.);
        }
        
        else if (O.mat_id == 3)
        {
            n = getnorm(p,0.001);
            col = vec3(0.8,0.,0.3);
        }
        
        float lit = dot(n,normalize(l))*.5+.5;
        vec3 h = normalize(l-rd);
        float spec = pow(max(dot(n,h),0.),20.);
        float ao = AO(0.05,p,n)+AO(0.15,p,n)+AO(0.2,p,n);
        col *= lit;
        col *= ao/3.;
        col += spec;
    }
    
    // Output to screen
    glFragColor = vec4(sqrt(col),1.0);
}
