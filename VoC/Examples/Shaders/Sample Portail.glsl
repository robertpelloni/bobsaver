#version 420

// original https://www.shadertoy.com/view/wssBzX

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

// Shader made for Everyday ATI challenge

#define PI 3.141592
#define TAU 6.2831853071
#define dt (mod(time+PI*0.5,TAU))

// reference for animation curves: https://easings.net/
float easeInOutCirc(float x)
{
    return x < 0.5
      ? (1. - sqrt(1. - pow(2. * x, 2.))) / 2.
      : (sqrt(1. - pow(-2. * x + 2., 2.)) + 1.) / 2.;
}

mat2 rot(float a)
{return mat2(cos(a),sin(a),-sin(a),cos(a));}

#define animation(time) (-1.+2.*easeInOutCirc(time))
float square (vec2 uv)
{
    float width = 0.35;
    uv.x += animation(sin(dt)*0.5+0.5);
    uv *= rot(animation(sin(dt)*0.5+0.5)*PI);
    uv = abs(uv);
    return smoothstep(width,width*1.05,max(uv.x,uv.y));
}

float sc (vec3 p, float s)
{
    p = abs(p);
    p = max(p, p.yzx);
    return min(p.x, min(p.y, p.z)) - s;
}

float cube (vec3 p)
{
    p.x += animation(sin(dt)*0.5+0.5)*2.8;    
    p.yz *= rot(-atan(1./sqrt(2.)));
    p.xz *= rot(PI/4.);
    p.xy *= rot(animation(sin(dt)*0.5+0.5)*PI);
    return max(-sc(p, 0.8),length(max(abs(p)-vec3(1.),0.)));
}

vec3 raymarch (vec2 uv)
{
    vec3 ro = vec3(uv*3.,5.),
        rd = normalize(vec3(0.,0.,-1.)),
        p = ro,
        col = vec3(0.,0.05,0.05);
    float shad;
    bool hit = false;
    
    for (float i=0.; i<32.; i++)
    {
        float d = cube(p);
        if (d<0.01)
        {
            hit = true;
            shad = i/32.;
            break;
        }
        p+=d*rd;
    }
    if (hit) col = vec3(1.-shad);
    return col;
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;    
    vec3 col =(uv.x >= 0.) ? raymarch(uv):vec3(0.,0.05,0.05)+square(uv);
    glFragColor = vec4(sqrt(col),1.0);
}
