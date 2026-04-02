#version 420

// original https://www.shadertoy.com/view/3scSWr

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
#define ITER 100.

mat2 rot (float a)
{return mat2(cos(a),sin(a),-sin(a),cos(a));}

void moda (inout vec2 p, float rep)
{
    float per = 2.*PI/rep;
    float a = atan(p.y,p.x);
    float l = length(p);
    a = mod(a,per) -per*0.5;
    p = vec2(cos(a),sin(a))*l;
}

float stmin (float a, float b, float k, float n)
{
    float st = k/n;
    float u = b-k;
    return min(min(a,b), 0.5 * (u+a+abs(mod(u-a+st, 2.*st)-st)));
}

float box (vec3 p, vec3 c)
{
    vec3 q = abs(p)-c;
    return min(0.,max(q.x,max(q.y,q.z))) + length(max(q,0.));
}

float cyl(vec2 p, float r)
{return length(p)-r;}

float pillars (vec3 p)
{
    float per = 2.;
    p.z = mod(p.z, per)-per*0.5;
    p.x = abs(p.x)-1.6;
    float c1 = cyl(p.xz, 0.3);
    moda(p.xz, 5.);
    p.x -= .3;
    return max(-cyl(p.xz, 0.1), c1);
}

float room (vec3 p)
{return stmin(pillars(p),-box(p, vec3(2.,1.,1e10)),0.2, 3.);}

float carpet (vec3 p)
{
    vec3 pp = p;
    p.y += 0.99;
    float b1 = box(p, vec3(0.8,0.02,1e10));
    
    p = pp;
    p.y +=0.6;
    p.x = abs(p.x) - 2.;
    float b2 = box(p, vec3(0.02,0.5,1e10));
    
    return min(b1,b2);
}

int mat_id;
float SDF (vec3 p)
{
    p.xy *= rot(-p.z*0.1);
    float c = carpet(p);
    float r = room(p);
    float d = min(carpet(p),room(p));
    
    if (d == c) mat_id = 1;
    if (d == r) mat_id = 2;
    
    return d;
}

vec3 getnorm (vec3 p)
{
    vec2 eps = vec2(0.01,0.0);
    return normalize(SDF(p) - vec3(SDF(p-eps.xyy),SDF(p-eps.yxy), SDF(p-eps.yyx)));
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;

    vec3 ro = vec3(0.001,0.001,-3.+time),
        p = ro,
        rd = normalize(vec3(uv,1.)),
        l = vec3(0.,1.,-0.5),
        col = vec3(0.);
    
    float shad = 0.;
    
    for (float i=0.; i<ITER; i++)
    {
        float d = SDF(p);
        if (d<0.001)
        {
            shad = i/ITER;
            break;
        }
        
        p += d*rd;
    }
    
    float t= length(ro-p);
    
    if (mat_id == 1) col = vec3(0.6-abs(p.x*0.15),0.,0.1);
    if (mat_id == 2) col = vec3(0.8,0.7,0.6);
    vec3 n = getnorm(p);
    col *= mix(vec3(0.05,0.,0.2),
               vec3(0.9,0.8,0.7),
               dot(n,normalize(l))*0.5+0.5
               );
    col *= vec3(1.-shad);

    col = mix(col, vec3(0.7,0.7,0.8),1.-exp(-0.05*t*t));
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
