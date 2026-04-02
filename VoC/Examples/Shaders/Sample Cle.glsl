#version 420

// original https://www.shadertoy.com/view/wssBDf

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

mat2 rot (float a)
{return mat2(cos(a),sin(a),-sin(a),cos(a));}

float cyl (vec3 p, float r, float h)
{return max(length(p.xy)-r,abs(p.z)-h);}

float tore (vec3 p, vec2 t)
{return length(vec2(length(p.xz)-t.x,p.y))-t.y;}

float key (vec3 p, float t)
{
    float thick = t;
    float body = cyl(p.xzy, thick,1.5);
    float encoche = tore(p.xzy+vec3(-(2.*thick),0.05,1.),vec2(thick,0.1));
    float head = max(-cyl(p-vec3(0.,2.2,0.),0.65,thick*1.5),cyl(p-vec3(0.,2.2,0.), 0.8, thick));
    p.y = abs(abs(p.y-0.45)-0.8)-0.15;
    float ts = tore(p,vec2(thick, 0.08));

    return min(encoche,min(min(body,head),ts));
}

float SDF(vec3 p)
{
    p.xy *= rot(PI/3.);
    p.xz *= rot(time*0.5);
    vec3 pp = p-vec3(0.,2.,0.);
    float small = 3.5;
    float thick = 0.25;
    float d = key(p,thick);
    for (int i=0; i<2; i++)
    {
        pp.xz *= rot(time*(float(i)+1.));
        d = min(d, key(pp*small,thick)/small);
        pp.y -= 0.55;
        small *= 4.;
    }
    return d;
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;

    vec3 ro = vec3(-1.,0.6,-4.),
        rd = normalize(vec3(uv,1.8)),
        p = ro,
        col = vec3(0.1,0.15,0.2);

    float shad,d=0.; 
    bool hit = false;

    for (float i=0.;i<64.; i++)
    {
        d = SDF(p);
        if (d<0.001)
        {
            hit = true;
            shad = i/64.;
            break;
        }
        p += d*rd;
    }

    if (hit)
    {
        col = vec3(0.8,0.74,0.75);
        col *= (1.-shad);
    }

    // vignetting (from iq)
    vec2 q = gl_FragCoord.xy / resolution.xy;
    col *= .5 + 0.5 * pow(16. * q.x * q.y * (1. - q.x) * (1. - q.y), 0.2);

    glFragColor = vec4(sqrt(col),1.0);
}
