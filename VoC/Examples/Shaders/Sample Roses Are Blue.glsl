#version 420

// original https://www.shadertoy.com/view/MsyfWh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Code by Flopine
// Thanks to wsmind, leon, lsdlive, lamogui and XT95 for teaching me <3 cookie collective rulz

#define ITER 64.
#define PI 3.141592
#define MAT_LIANE 0.
#define MAT_FLOWER 1.

vec2 moda (vec2 p, float per)
{
   float a = atan(p.y, p.x);
    float l = length(p);
    a = mod(a-per/2.,per)-per/2.;
    return vec2(cos(a),sin(a))*l;
}

// iq's palette http://www.iquilezles.org/www/articles/palettes/palettes.htm
vec3 palette (float t, vec3 a, vec3 b, vec3 c, vec3 d)
{return a+b*cos(2.*PI*(c*t+d));}

vec2 mo (vec2 p, vec2 d)
{
    p.x = abs(p.x)-d.x;
    p.y = abs(p.y) - d.y;
    if (p.y>p.x) p.xy = p.yx;
    return p;
}

mat2 rot (float a)
{return mat2(cos(a),sin(a),-sin(a),cos(a));}

float stmin (float a, float b, float k, float n)
{
    float st = k/n;
    float u = b-k;
    return min(min(a,b), 0.5 * (u+a+abs(mod(u-a+st, 2.*st)-st)));
}

vec2 path(float t) 
{
    float a = sin(t*.2 + 1.5), b = sin(t*.2);
    return vec2(a*2., a*b);
}

float sphe (vec3 p, float r)
{return length(p)-r;}

float od ( vec3 p, float d)
{return dot(p, normalize(sign(p)))-d;}

float cyl(vec2 p, float r)
{return length(p)-r;}

float prim1 (vec3 p)
{
    float r = .8;
    float s = sphe(p,r);
    for (int i = 0; i < 5; i++)
    {
        r -= 0.15;
         p.y += r*2.;
        float b = length(max(abs(p)-vec3(0.5),0.));
        s = min(min(s, sphe(p,r)),b);
    }
    return s;
}

float prim2 (vec3 p)
{
    
    float o = od(p, 1.2);
    p.xz *= rot(time);
    p.xy = mo(p.xy, vec2(2.));
    p.yz = moda(p.yz, 2.*PI/5.);
    p.y -= 2.;
    return stmin(prim1(p), o, 0.5, 5.);
}

vec2 flower(vec3 p)
{ 
    p.xy = moda(p.xy, 2.*PI/5.);
    p.x -= 2.;
    return vec2(prim2(p), MAT_FLOWER); 
}

vec2 liane (vec3 p)
{
    p.yx = moda(p.yx, 2.*PI/7.);
    p.y -= 7.*(sin(time*0.5)+1.*0.4);
    p.x += sin(p.y+time*2.);
    return vec2(cyl(p.xz, 1.- abs(p.y)*0.15), MAT_LIANE);
}

vec2 mat_min(vec2 a, vec2 b)
{
    if (a.x < b.x) return a;
    else return b;
}

float g = 0.;

vec2 SDF (vec3 p)
{
    float per = 30.;

    p.xz = mod(p.xz-per/2., per) -per/2.;
    p.yz *= rot(PI/2.);
    vec2 f = flower(p);
    p.z -= 1.5;
    
    vec2 d = mat_min(liane(p), f);
    // glow from lsdlive, originally from balkhan : https://www.shadertoy.com/view/4t2yW1
    g += 0.01/(0.01+d.x*d.x);
    
    return d;
}

////////////////////////////////////////////////////////////////////
// CAMERA
vec3 getcam (vec3 eye, vec3 lookat, vec2 uv, float fov)
{
    vec3 forward = normalize(lookat-eye);
    vec3 right = cross(vec3(0.,1.,0.),forward);
    vec3 up = cross(forward, right);
    return normalize(forward*fov+right*uv.x+up*uv.y);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = 2.*(gl_FragCoord.xy/resolution.xy)-1.;
    uv.x *= resolution.x/resolution.y;
    
    vec3 ro = vec3(2.,10.,-5.+time*5.); vec3 p = ro;
    vec3 target = vec3(0.,0., 1.+time*5.);
    vec3 dir = getcam(ro, target,uv,0.4);
    
    float shad = 0.;
    vec3 c = vec3(0.);
    
    vec3 back = palette(length(uv),
                       vec3(0.5),
                       vec3(0.5),
                       vec3(0.08),
                       vec3(0.5,0.1,0.7));
    
    for (float i = 0.; i<ITER; i++)
    {
        vec2 d = SDF(p);
        if (d.x < 0.001)
        {
            shad = i/ITER;
            if (d.y == MAT_LIANE) c = vec3(1.-shad)*palette(i,
                                                     vec3(0.2,0.8,0.2),
                                                     vec3(0.5),
                                                     vec3(0.04),
                                                     vec3(0.5));
            
            if (d.y == MAT_FLOWER) c = vec3(1.-shad)*palette(p.z,
                                                     vec3(0.6,0.1,0.2),
                                                     vec3(0.9),
                                                     vec3(0.05),
                                                     vec3(0.1,0.2,0.3));
            break;
        }
        p+= d.x * dir *0.3;
    }

    float t = length(ro-p);
    c = mix(c,vec3(0.2,0.,0.1), 1.-exp(-0.001*t*t))+(g*length(uv)*0.02);

    // Output to screen
    glFragColor = vec4(c,1.0);
}
