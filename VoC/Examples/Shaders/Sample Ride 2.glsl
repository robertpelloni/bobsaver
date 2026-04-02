#version 420

// original https://www.shadertoy.com/view/3sdXzs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Code by Flopine
// Thanks to wsmind, leon, XT95, lsdlive, lamogui, Coyhot, Alkama and YX for teaching me
// Thanks LJ for giving me the love of shadercoding :3

// Thanks to the Cookie Collective, which build a cozy and safe environment for me 
// and other to sprout :)  https://twitter.com/CookieDemoparty

#define ITER 64.
#define PI 3.141592
#define tt (time*6.)

float hash21 (vec2 x)
{return fract(sin(dot(x,vec2(12.4,16.1)))*1245.4);}

float moda (inout vec2 p, float rep)
{
    float per = (2.*PI)/rep;
    float a = atan(p.y,p.x);
    float l = length(p);
    float id = floor(a/per);
    a = mod(a,per)-per*0.5;
    p = vec2(cos(a),sin(a))*l;
    if (abs(id)>= rep*0.5) id = abs(id);
    return id;
}

mat2 rot (float a)
{return mat2(cos(a),sin(a),-sin(a),cos(a));}

float g1 = 0.;
float box (vec3 p, vec3 c)
{
    float d = length(max(abs(p)-c,0.));
    g1 += 0.1/(0.1+d*d);
    return d;
}

float g2;
float cyl (vec2 p, float r)
{
    float d = length(p)-r;
    g2 += 0.1/(0.1+d*d);
    return d;
}

vec2 path(float t) 
{
    float a = sin(t*.2+1.5), b = sin(t*.2);
    return vec2(a, a*b);
}

float cid;
float SDF (vec3 p)
{
    p.xy -= path(p.z)*3.;
    p.xy *= rot(p.z*0.15);
    
    vec3 pp = p;
    
    p += sin(p.yzx - cos(p.zxy));
    p += sin(p.yzx/1.5 + cos(p.zxy)/2.)*.5;
    float t = -length(p.xy)+6.;
    
    p = pp;
    moda(p.xy, 6.);
    p.x -= 3.;
    float b = box(p,vec3(.2,0.2,1e10));
    
    p = pp;
    p.xy *= rot(PI/6.);
    cid = moda(p.xy, 6.);
    p.y += sin(p.z)*0.5;
    p.x -= 2.;
       float c = cyl(p.xy, 0.3);
    return min(min(c,t),b);
}

vec3 getcam (vec3 ro, vec3 tar, vec2 uv)
{
    vec3 f = normalize(tar-ro);
    vec3 l = normalize(cross(vec3(0.,1.,0.),f));
    vec3 u = normalize(cross(f,l));
    return normalize(f + l*uv.x + u*uv.y);
}

vec3 palette (float t, vec3 a, vec3 b, vec3 c, vec3 d)
{return a+b*cos(2.*PI*(c*t+d));}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;

    float dither = hash21(uv);
    
    vec3 ro = vec3(0.,0.,-5.+tt),
        ta = vec3(0.,0.,tt);
    
    ro.xy += path(ro.z)*3.;
    ta.xy += path(ta.z)*3.;
       
    vec3 rd = getcam(ro,ta, uv),
        p = ro,
        col = vec3(0.);
    
    float shad = 0.;
    
    for (float i=0.; i<ITER; i++)
    {
        float d = SDF(p);
        if (d<0.01)
        {
            shad = i/ITER;
            break;
        }
         d *= 0.6+dither*0.1;
        p += d*rd;
    }
    
    float t = length(ro-p);
    col = vec3(shad)*0.5;

   
    col += g2 * 0.09* palette(cid, 
                        vec3(0.5),
                        vec3(0.5),
                        vec3(0.1+cid), 
                        vec3(0.,0.3,0.45)); 
    col -= g1*0.25;
    
    glFragColor = vec4(pow(col,vec3(0.4545)),1.0);
}
