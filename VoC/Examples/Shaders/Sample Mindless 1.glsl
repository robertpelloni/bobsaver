#version 420

// original https://www.shadertoy.com/view/3dVGWz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Code by Flopine
// Thanks to wsmind, leon, XT95, lsdlive, lamogui, Coyhot, Alkama and YX for teaching me
// Thanks LJ for giving me the love of shadercoding :3

// Thanks to the Cookie Collective, which build a cozy and safe environment for me 
// and others to sprout :)  https://twitter.com/CookieDemoparty

float hash21 (vec2 x)
{return fract(sin(dot(x,vec2(16.4,34.5)))*1212.4);}

float box (vec3 p, vec3 c)
{
    vec3 q = abs(p)-c;
    return min(0.,max(q.x,max(q.y,q.z)))+ length(max(q,0.));
}

float cyl (vec3 p, float r, float h)
{return max(length(p.xy)-r, abs(p.z)-h);}

float well (vec3 p)
{
    p.y = abs(p.y)-2.;
    p.xz = fract(p.xz)-0.5;
    return max(abs(p.y)-0.25,abs(cyl(p.xzy, .45,1.))-0.05);
}

vec2 s_id;
float g1 = 0.;
float spheres (vec3 p)
{ 
    s_id = floor(p.xz);
    
    float anim = (mod(s_id.x,2.) == 0.)? time*hash21(s_id)*0.5 : -time*hash21(s_id)*0.5;
    p.y -= anim;
       p.xz = fract(p.xz)-.5;
    
    p.y = fract(p.y)-.5;
    
       float d = length(p)-0.2;
    g1 += 0.01/(0.01+d*d);
    return d;
}

float SDF (vec3 p)
{
    return min(-box(p,vec3(7.,2.5,5.)),min(spheres(p),well(p)));
}

vec3 getcam (vec3 ro, vec3 tar, vec2 uv)
{
    vec3 f = normalize(tar-ro);
    vec3 l = normalize(cross(vec3(0.,1.,0.),f));
    vec3 u = normalize(cross(f,l));
    return normalize(f + l*uv.x + u*uv.y);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = 2.*(gl_FragCoord.xy/resolution.xy)-1.;
    uv.x *= resolution.x/resolution.y;
    
    float dither = hash21(uv);
    
       vec3 ro = vec3(0.8,0.3,-3.5),
        p = ro,
        rd = getcam(ro, vec3(0.),uv),
        col = vec3(0.);
    
    float shad = 0.;
    
    for (float i=0.; i<64.; i++)
    {
        float d = SDF(p);
        if (d<0.001)
        {
            shad = i/64.;
            break;
        }
        d *= 0.9+dither*0.1;
        p+=d*rd;
    }
    
    col = vec3 (shad)*0.2;
    vec3 c1 = clamp(vec3(hash21(s_id),hash21(s_id*0.2),1.),0.,1.);
    vec3 c2 = clamp(vec3(1.,hash21(s_id),hash21(s_id)*0.1),0.,1.);
    vec3 fc = mod(s_id.x, 2.) == 0. ? c1 : c2;
    col += g1*fc*0.02*exp(-fract(time));
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
