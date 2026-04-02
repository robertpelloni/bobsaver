#version 420

// original https://www.shadertoy.com/view/WtlcR7

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

// I did this shader for my friend's videogame called Gentris
// https://twitter.com/PiersBishopArt/status/1270294149200318470

#define ITER 64.
#define PI acos(-1.)
#define time(speed) fract(time*speed)
#define anim(speed) easeInOutCirc(time(speed))
#define lines(s, puv) smoothstep(s,s*lines_blur, abs(puv.y))

// SHADER PARAMETERS
#define BPM (125./60.)

#define spheres_speed 0.6
#define spheres_speedvariation .1

#define lines_frequency 5.
#define lines_thickness 0.1
#define lines_blur 1.05
#define lines_speed -(.2)

#define color1 vec3(0.5,0.05,0.1)
#define color2 vec3(0.1,0.8,0.5)
#define backgroundcolor vec3(.0,.01,.04)
#define light_position vec3(1.,1.,-2.)

float easeInOutCirc (float x)
{
    return x < 0.5
        ? (1. - sqrt(1. - (2. * x) * (2. * x))) / 2.
        : (sqrt(1. - (-2. * x + 2.) * (-2. * x + 2.)) + 1.) / 2.;
}

mat2 rot (float a)
{return mat2(cos(a),sin(a),-sin(a),cos(a));}

// polynomial smooth min (k = 0.1);
float smin( float a, float b, float k )
{
    float h = max( k-abs(a-b), 0.0 )/k;
    return min( a, b ) - h*h*k*(1.0/4.0);
}

float moda (inout vec2 p, float rep)
{
    float per = (2.*PI)/rep;
    float a = atan(p.y,p.x);
    float id = floor(a/per);
    if (id >= rep*0.5) id = abs(id);
    a = mod(a,per)-per*.5;
    p = vec2(cos(a),sin(a)) * length(p);
    return id;
}

void mo (inout vec2 p, vec2 d)
{
    p = abs(p)-d;
    if(p.y>p.x) p = p.yx;
}

float cyl (vec3 p, float r, float h)
{return max(length(p.xy)-r,abs(p.z)-h);}

float primitive1 (vec3 p, float s_speed)
{
    float per = 1.;
    float thread = cyl(p.xzy, 0.03, 10.);

    float radius = .07;
    p.y += anim(s_speed);
    p.y = mod(p.y,per)-per*.5;
    float spheres = length(p)-radius; 

    float d = smin(thread,spheres,0.1);
    return d;
}

vec3 new_p;
float scene (vec3 p) 
{
    p.yz *= rot(atan(1./sqrt(2.)));
    p.xz *= rot(PI/4.);

    mo(p.xz,vec2(1.));
    p.x -= 0.5+sin(p.y)*.5;
    mo(p.xz, vec2(.2));
    p.xz *= rot(p.y*2.);
    float pid = moda(p.xz, 4.);
    p.x -= 0.2;

    new_p = p;
    float d =  primitive1(p, (pid * spheres_speedvariation - 1.) * spheres_speed);

    return d;
}

vec3 getnorm(vec3 p)
{
    vec2 eps = vec2(0.01,0.);
    return normalize(scene(p)-vec3(scene(p-eps.xyy),scene(p-eps.yxy),scene(p-eps.yyx)));
}

float texture_threads (vec2 uv)
{
    uv.y += anim(lines_speed);
    uv *= lines_frequency;
    uv.y = fract(uv.y)-.5;
    return clamp(1.-lines(lines_thickness, uv),0.,1.);
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;

    vec3 ro = vec3(uv,-80.),
        rd = vec3(0.,0.,1.),
        p = ro,
        l = normalize(light_position),
        col = backgroundcolor;

    bool hit = false;

    for (float i=0.; i<ITER; i++)
    {
        float d = scene(p);
        if (d<0.001)
        {
            hit = true;
            break;
        }
        p += d*rd*.7;
    }

    float mask = texture_threads(vec2(atan(new_p.z,new_p.x),new_p.y));

    if (hit)
    {
        vec3 n = getnorm(p);
        col = mix(color1, color2, mask);
        col *= (dot(n,l)*.5+.5);
    }

    glFragColor = vec4(sqrt(col),1.);
}
