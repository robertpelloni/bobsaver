#version 420

// original https://www.shadertoy.com/view/7dcSRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Code by Flopine

// Thanks to wsmind, leon, XT95, lsdlive, lamogui, 
// Coyhot, Alkama,YX, NuSan, slerpy, wwrighter 
// BigWings, FabriceNeyret and Blackle for teaching me

// Thanks LJ for giving me the spark :3

// Thanks to the Cookie Collective, which build a cozy and safe environment for me 
// and other to sprout :)  
// https://twitter.com/CookieDemoparty

// Still exploring repetition trick presenting by Blackle on Perfect Pistons <3 
// https://youtu.be/I8fmkLK1OKg
// https://www.shadertoy.com/view/WtXcWB

#define PI acos(-1.)
#define TAU (2.*PI)

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define palette(t,c) (vec3(.8)+vec3(.7)*cos(TAU*(c*t+vec3(0.8,0.1,0.2))))

#define dt(sp) fract(time*sp)

// iq's website: https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdVerticalCapsule( vec3 p, float h, float r )
{
  p.y -= clamp( p.y, 0.0, h );
  return length( p ) - r;
}

vec2 edge (vec2 p)
{
    vec2 p2 = abs(p);
    return (p2.x > p2.y) ? vec2((p.x<0.)?-1.:1., 0.) : vec2(0., (p.y<0.)?-1.:1.);
}

float palt;
float SDF (vec3 p)
{
    p.yz *= rot(-atan(1./sqrt(2.)));
    p.xz *= rot(PI/4.);
    
    vec2 center = floor(p.xz)+.5,
    neighbour = center + edge(p.xz-center);
    palt = atan(center.y,center.x);
    
    float a = palt-(dt(.5)*TAU), 
    radius = length(center),
    
    py = sin(length(center)+dt(.25)*TAU)*.5+.5, 
    size = clamp(sin(a+radius)*.5+.5,0.08,0.4),

    me = length(p-vec3(center.x,py,center.y))-size,
    // has to be the sum of all possible spheres
    next = sdVerticalCapsule(p-vec3(neighbour.x,0.,neighbour.y),1.,0.4); 

    return min(me,next);
}

vec3 getnorm (vec3 p)
{
    vec2 eps = vec2(0.01,0.);
    return normalize(SDF(p)-vec3(SDF(p-eps.xyy),SDF(p-eps.yxy),SDF(p-eps.yyx)));
}

float AO (float eps, vec3 p, vec3 n)
{return clamp(SDF(p+eps*n)/eps,0.,1.);}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    
    vec3 ro = vec3(uv*4.,-30.), rd=vec3(0.,0.04,1.),p=ro,
    col=vec3(0.), l=normalize(vec3(1.,2.,-2.));

    bool hit=false;
    for(float i=0.;i<100.;i++)
    {
        float d = SDF(p);
        if (d<0.001)
        {
            hit=true;break;
        }
        p += d*rd;
    }

    if (hit)
    {
        vec3 n = getnorm(p);
        float light = max(dot(n,l),0.15),
        ao = AO(0.1,p,n)+AO(0.25,p,n)+AO(0.8,p,n);
        
        col = palette(abs(palt)/PI,1.)*light*ao/3.;
    }

    glFragColor = vec4(sqrt(col),1.0);
}
