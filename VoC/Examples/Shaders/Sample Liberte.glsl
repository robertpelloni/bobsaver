#version 420

// original https://www.shadertoy.com/view/ts2fzK

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

#define PI acos(-1.)
#define time fract(time*0.3)

float easeInOutExpo(float x)
{
    return x == 0.
        ? 0.
        : x == 1.
            ? 1.
            : x < 0.5 ? pow(2., 20. * x - 10.) / 2.
                : (2. - pow(2., -20. * x + 10.)) / 2.;
}

mat2 rot (float a)
{return mat2(cos(a),sin(a),-sin(a),cos(a));}

float box (vec3 p, vec3 c)
{
    vec3 q = abs(p)-c;
    return min(0.,max(q.x,max(q.y,q.z)))+length(max(q,0.));
}

float sc (vec3 p, float d)
{
    p = abs(p);
    p = max(p.xyz,p.yzx);
    return min(p.x,min(p.y,p.z))-d;
}

float cage (vec3 p)
{
    float per = 15.;
    p.y -= easeInOutExpo(time*PI/3.)*per;
    p.y = mod(p.y-per*0.5,per)-per*0.5;
    vec3 pp = p;
    float size = 1.8;
    float cube = max(-sc(p,size*0.8),box(p,vec3(size)));

    p.z = abs(p.z)-size*0.9;
    p.x = abs(abs(p.x)-0.65)-0.3;
    float b1 = box(p,vec3(0.12,size,0.1));

    p = pp;
    p.xz *= rot(PI/2.);
    p.z = abs(p.z)-size*0.9;
    p.x = abs(abs(p.x)-0.65)-0.3;
    float b2 = box(p,vec3(0.12,size,0.1));

    return min(min(b2,b1),cube);
}

float gem (vec3 p)
{
    float d = dot(p,normalize(sign(p)))-(.2+sqrt(sin(time*PI)*0.5));
    return d;
}

float SDF (vec3 p)
{
    vec3 pp = p;    
    pp.yz *= rot(-atan(1./sqrt(2.)));
    pp .xz *= rot(PI/4.);
    p = mix(p,pp,easeInOutExpo(clamp(sin(time*PI)*3.-1.,0.,1.)));
    return min(gem(p),cage(p));
}

vec3 getnorm (vec3 p)
{
    vec2 eps = vec2(0.001,0.);
    return normalize(SDF(p)-vec3(SDF(p-eps.xyy),SDF(p-eps.yxy),SDF(p-eps.yyx)));
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;

    vec3 ro = vec3(uv*3.5,-30.),
        rd = vec3(0.,0.,1.),
        p = ro,
        l = normalize(vec3(1.,2.,-4.)),
        col = vec3(0.4,0.55,0.5);

    float d=0.;
    bool hit = false;
    for (float i=0.; i<100.;i++)
    {
        d = SDF(p);
        if (d < 0.001)
        {
            hit = true;
            break;
        }
        p += d*rd*0.8;
    }

    if (hit)
    {
        vec3 n = getnorm(p);
        col = vec3(max(dot(n,l),0.));
    }

    glFragColor = vec4(col,1.0);
}
