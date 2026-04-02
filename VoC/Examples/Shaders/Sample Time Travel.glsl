#version 420

// original https://www.shadertoy.com/view/MdcBzf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Code by Flopine, for Outline 2018 shader showdown
// Thanks to wsmind, leon, lsdlive, XT95, lamogui for teaching me :) <3

#define time time
#define PI 3.141592
#define ITER 65.

float  mid  = 0.;

float tiktak(float period)
{
    float tik = floor(time)+pow(fract(time),3.);
    tik *= 3.*period;
    return tik;
}

mat2 rot (float a)
{
    return mat2(cos(a),sin(a),-sin(a),cos(a));
}

vec2 moda (vec2 p, float per)
{
    float a = atan(p.y,p.x);
    float l = length(p);
    a = mod(a-per/2.,per)-per/2.;
    return vec2(cos(a),sin(a))*l;
}

float stmin(float a, float b, float k, float n)
{
    float st = k/n;
    float u = b-k;
    return min(min(a,b) , 0.5 * (u+a+abs(mod(u-a+st,2.*st)-st)));
}

float od (vec3 p, float d)
{
    return dot(p,normalize(sign(p)))-d;
}

float box (vec3 p, vec3 c)
{
    return length(max(abs(p)-c,0.));
}

float cylY(vec3 p, float r, float h)
{
    return max(length(p.xz)-r, abs(p.y)-h);
}

float cylZ(vec3 p, float r, float h)
{
    return max(length(p.xy)-r, abs(p.z)-h);
}

float prim1 (vec3 p, float h)
{
    p.xz *= rot(p.y);
    p.xz = moda(p.xz, 2.*PI/5.);
    p.x -= .6;
    return cylY(p,0.07,h);
}

float prim2 (vec3 p, float h)
{
    return min(cylY(vec3(p.x,p.y+h,p.z),1.,0.2), cylY(vec3(p.x,p.y-h,p.z),1.,0.2));
}

float sablier (vec3 p)
{
    float h = 1.8;
    float s1 = stmin(prim1(p,h), prim2(p,h),0.3,5.);
    p.xz *= rot(time);
    p.xy *= rot(time);
    return min(s1,od(p,0.3));
}

float ring (vec3 p)
{
    p *= 1.2;
    float s1 = max(-cylZ(p,0.6,1.), cylZ(p,1.,0.3));
    p.xy = moda(p.xy, 2.*PI/8.);
    p.x -= 1.2;
    return stmin(box(p,vec3(0.4,0.2,0.2)), s1,0.3,5.);
}

float SDF (vec3 p)
{
    float per = 6.;
    float d = 0.;

    p.z = mod(p.z-per/2.,per)-per/2.;

    vec3 pp = p;
    p.xy *=rot(tiktak(0.5));
    float r1 = ring (p);

    p = pp;

    p.xy *=rot(-tiktak(0.5));
    p.xy = moda(p.xy,2.*PI/5.);
    p.x -= 5.;
    float s = sablier(p);

    if (d<r1)
    {
        mid = 1.;
        d = r1;
    }

    if (d>s)
    {
        mid = 2.;
        d = s;
    }

    return d;
}

void main(void)
{
      vec2 uv = 2.*(gl_FragCoord.xy/resolution.xy)-1.;
    uv.x *= resolution.x/resolution.y;

    vec3 ro = vec3(0.001,0.001,time*3.); vec3 p = ro;
    vec3 dir = normalize(vec3(uv,1.));
    float shad = 0.;

    for (float i = 0.; i<ITER; i++)
    {
        float d = SDF(p);
        if (d<0.001)
        {
            shad = i/ITER;
            break;
        }
        p+=d*dir*0.35;
    }

    float t = length(ro-p);

    vec3 col = vec3(0.);

    if (mid == 1.) col = vec3(1.-shad)/vec3(0.3,0.8,0.)*0.8;
    if (mid == 2.) col = mix(vec3(shad), vec3(0.1,0.5,0.7), 1.-abs(p.y)+2.);

    col = mix(col,length(uv)* vec3(0.,0.,0.1),1.-exp(-0.001*t*t));
    glFragColor = vec4(col,1.);
}
