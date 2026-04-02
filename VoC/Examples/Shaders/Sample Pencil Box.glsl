#version 420

// original https://www.shadertoy.com/view/sscSD8

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
#define pal(c,t) (vec3(.6)+vec3(.4)*cos(TAU*(c*t+vec3(0.5,0.,0.8))))

#define dt(sp,off) fract((time+off)*sp)
#define anim(sp, off) easeInOutExpo(abs(-1.+2.*dt(sp,off)))
#define swi(sp,off) floor(sin(dt(sp,off)*TAU)+1.)

float easeInOutExpo(float x)
{
    return x == 0.
      ? 0.
      : x == 1.
      ? 1.
      : x < 0.5 ? exp2(20. * x - 10.) / 2.
      : (2. - exp2(-20. * x + 10.)) / 2.;
}

float box (vec3 p , vec3 c)
{
    vec3 q = abs(p)-c;
    return min(0.,max(q.x,max(q.y,q.z)))+length(max(q,0.));
}

// iq's blog 
// https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdHexPrism (vec3 p, vec2 h)
{
  const vec3 k = vec3(-0.8660254, 0.5, 0.57735);
  p = abs(p);
  p.xy -= 2.0*min(dot(k.xy, p.xy), 0.0)*k.xy;
  vec2 d = vec2(
       length(p.xy-vec2(clamp(p.x,-k.z*h.x,k.z*h.x), h.x))*sign(p.y-h.x),
       p.z-h.y );
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

vec2 edge (vec2 p)
{
    vec2 p2=abs(p);
    return (p2.x>p2.y) ? vec2((p.x<0.) ? -1. : 1., 0.) : vec2(0., (p.y<0.) ? -1. : 1.);
}

float id;
float SDF (vec3 p)
{
    p.yz *= rot(-atan(1./sqrt(2.)));
    if (swi(0.15,.0)<0.5) p.xz *= rot(PI/4.);

    vec2 center = round(p.xz);
    vec2 neighbour = center+edge(p.xz-center);
    
    vec2 pol = vec2(atan(center.y,center.x),length(center));
    id = (abs(pol.x)/PI);
    p.y += anim(0.3,sin(pol.x-pol.y));
    float me = sdHexPrism(p.xzy-vec3(center, 0.),vec2(.42,1.))-0.02;
    float ne = box(p-vec3(neighbour.x, 0., neighbour.y), vec3(.46,3.5,0.46));
    
    return min(me,ne);
}

vec3 getnorm (vec3 p)
{
    vec2 eps = vec2(0.001,0.);
    return normalize(SDF(p)-vec3(SDF(p-eps.xyy),SDF(p-eps.yxy),SDF(p-eps.yyx)));
}

float AO (float eps, vec3 p, vec3 n)
{return SDF(p+eps*n)/eps;}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    
    vec3 ro = vec3(uv*4.,-30.),rd=normalize(vec3(0.,0.02,1.)),p=ro,
    col=vec3(0.), l=normalize(vec3(-1.,2.,-3.));   
    bool hit=false;
    
    for(float i=0.; i<100.; i++)
    {
        float d = SDF(p);
        if (d<0.001)
        {hit=true;break;}
        p += d*rd;
    }

    if (hit)
    {
        vec3 n = getnorm(p);
        float light = max(dot(n,l),0.1), ao=AO(0.1,p,n)+AO(0.15,p,n)+AO(0.45,p,n);
        col = pal(id,vec3(1.))*light*ao/2.;
    }

    glFragColor = vec4(sqrt(col),1.0);
}
