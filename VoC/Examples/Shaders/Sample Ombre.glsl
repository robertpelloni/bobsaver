#version 420

// original https://www.shadertoy.com/view/3slBDS

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
#define dt mod(time-PI/4.,TAU)

mat2 rot (float a)
{return mat2 (cos(a),sin(a),-sin(a),cos(a));}

// reference for animation curves: https://easings.net/
float easeInOutCirc(float x)
{
    return x < 0.5
      ? (1. - sqrt(1. - (2. * x)*(2. * x))) / 2.
      : (sqrt(1. - (-2. * x + 2.)*(-2. * x + 2.)) + 1.) / 2.;
}

float box (vec3 p, vec3 c)
{
    vec3 q = abs(p)-c;
    return min(0.,max(q.x,max(q.y,q.z))) + length(max(q,0.));
}

#define anim(freq) easeInOutCirc(sin(dt*freq)*0.5+0.5)

float SDF (vec3 p)
{
    p.yz *= rot(-atan(1./sqrt(2.)));
    p.xz *= rot(PI/4.);
    
       float b2 = box(p, vec3(5.));
    float bigper = 5.;
    p = mod(p-bigper*0.5, bigper)-bigper*0.5;
    
    float b1 = box (p, vec3(2.));    
    float per = 0.5;
    vec3 id = floor((p-per*0.5)/per);   
    p = mod(p-per*0.5, per)-per*0.5;

    return max(b2,max(b1, box(p,vec3(0.3-anim(1.)*0.2))));
}

vec3 getnorm (vec3 p)
{
    vec2 eps = vec2(0.01,0.);
    return normalize(SDF(p)-vec3(SDF(p-eps.xyy),SDF(p-eps.yxy),SDF(p-eps.yyx)));
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    
    float scale = mix(2.,9.,floor(sin(dt-2.)+1.));
    vec3 ro = vec3(uv*scale,-20.),
        rd = vec3(0.,0.,1.),
        p = ro,
        l = vec3(1.,2.,-1.),
        col = vec3(0.);
    
    float shad; bool hit = false;
    
    for (float i=0.; i<64.; i++)
    {
        float d = SDF(p);
        if (d<0.01)
        {
            hit = true;
            shad = i/64.;
            break;
        }
        p+=d*rd;
    }

    if (hit)
    {
        vec3 n = getnorm(p);
        float light = max(dot(n,normalize(l)),0.);
        col = vec3(light);
    }

    glFragColor = vec4(sqrt(col),1.0);
}
