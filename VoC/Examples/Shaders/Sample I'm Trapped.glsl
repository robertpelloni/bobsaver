#version 420

// original https://www.shadertoy.com/view/WtsfWr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Code by Flopine

// Thanks to wsmind, leon, XT95, lsdlive, lamogui, 
// Coyhot, Alkama,YX, NuSan and slerpy for teaching me

// Thanks LJ for giving me the spark :3

// Thanks to the Cookie Collective, which build a cozy and safe environment for me 
// and other to sprout :)  https://twitter.com/CookieDemoparty

#define PI acos(-1.)
#define time time
#define BPM (135./60.)
#define dt(speed) fract(time*speed)

#define bouncy(speed) sqrt(abs(sin(dt(speed)*PI)))
#define switchanim(speed) floor(sin(dt(speed)*2.*PI)+1.)

struct obj 
{
    float d;
    float m;
    vec3 c;
}
;

mat2 rot (float a)
{return mat2(cos(a),sin(a),-sin(a),cos(a));}

void mo (inout vec2 p, vec2 d)
{
    p = abs(p)-d;
    if (p.y>p.x) p = p.yx;
}

vec3 pal (float t, vec3 c)
{return vec3(0.5)+vec3(0.5)*cos(2.*PI*(c*t+vec3(0.,0.37,0.63)));}

obj strucmin (obj a, obj b)
{
    if (a.d<b.d) return a;
     else return b;
}

float box (vec3 p, vec3 c)
{
    vec3 q = abs(p)-c;
    return min(0., max(q.x,max(q.y,q.z)))+length(max(q,0.));
}

float sc (vec3 p, float d)
{
    p = abs(p);
    p = max(p,p.yzx);
    return min(p.x,min(p.y,p.z))-d;
}  

obj cages (vec3 p)
{
    mo(p.xz, vec2(0.5));
    p.x -= 0.8;

    mo(p.yz, vec2(1.));
    p.y -= 1.+bouncy(BPM/4.);

    mo(p.xz, vec2(2.));
    p.x -= 1.5;

    float anim = (PI/2.)*(floor(time*(BPM/2.))+pow(dt(BPM/2.),5.));
    p.xz += vec2(cos(anim),sin(anim));

    return obj(max(-sc(p,0.9-bouncy(BPM)*0.1),box(p,vec3(1.)))-0.02,0.,pal(length(p),vec3(1.)));
}

obj gem (vec3 p)
{
    p.xz *= rot(dt(BPM/5.)*PI);
    return obj (dot(p,normalize(sign(p)))-1., 1., vec3(1.));
}

obj SDF (vec3 p)
{
    p.yz *= rot(-atan(1./sqrt(2.)));
    p.xz *= rot(PI/4.0);
    return strucmin(gem(p),cages(p));
}

vec3 getnorm(vec3 p)
{
    vec2 eps = vec2(0.001,0.);
    return normalize(SDF(p).d-vec3(SDF(p-eps.xyy).d,SDF(p-eps.yxy).d,SDF(p-eps.yyx).d));
}

float mask(vec2 uv)
{
    return smoothstep(0.1,0.4, sin(fract(length(uv))-time*(BPM/4.)));
}

void main(void)
{
    vec2 uv = vec2(gl_FragCoord.xy.x / resolution.x, gl_FragCoord.xy.y / resolution.y);
    uv -= 0.5;
    uv /= vec2(resolution.y / resolution.x, 1);

    vec2 uu = floor(uv*30.)/30.;
    uv *= 0.95+mask(uu);
    
    vec3 ro = vec3(uv*8.,-50.),
        rd = vec3(0.,0.,1.),
        l = normalize(vec3(1.,2.,-2.)),
        p = ro,
        col = vec3(0.);

    bool hit = false; obj O;

    for (float i=0.; i<64.;i++)
    {
        O = SDF(p);
        if (O.d<0.001)
        {
            hit = true; break;
        }
        p += O.d*rd;
    }

    if (hit)
    {
        vec3 n = getnorm(p);
        float lighting = max(dot(n,l),0.);
        if (O.m == 0.) col = O.c*lighting;
        if (O.m == 1.) col = mix(vec3(0.1,0.2,0.8),vec3(1.,0.8,0.8), lighting);

    }
    
    glFragColor = vec4(sqrt(col),1.);
}
