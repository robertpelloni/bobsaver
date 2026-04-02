#version 420

// original https://www.shadertoy.com/view/3dtfRr

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

// Check out the awesome talent of Bubblyfish here <3 
// https://bubblyfish.bandcamp.com/

#define PI acos(-1.)
#define TAU 6.283185
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))

#define time time
#define dt(speed, offset) fract(time*speed+offset)
#define swa(speed) floor(sin(dt(speed,0.)*TAU)+1.)
#define bouncy(speed, offset) sqrt(sin(dt(speed,offset)*PI)) 

#define od(pos,d) (dot(pos,normalize(sign(pos)))-d)
#define cyl(pos,r,h) max(length(pos.xy)-r,abs(pos.z)-h)

void mo(inout vec2 p, vec2 d)
{
    p = abs(p)-d;
    if(p.y>p.x) p = p.yx;
}

float box (vec3 p, vec3 c)
{
    vec3 q = abs(p)-c;
    return min(0.,max(q.x,max(q.y,q.z)))+length(max(q,0.));
}

float sc (vec3 p, float d)
{
    p = abs(p);
    p = max(p,p.yzx);
    return min(p.x,min(p.y,p.z))-d;
}

float g1 = 0.;
float SDF (vec3 p)
{
    p.yz *= rot(-atan(1./sqrt(2.)));
    p.xz *= rot(PI/4.);
    vec3 still = p;

    p.z += time;  
    vec3 forward = p;

    float perz = 0.5;
    float id = floor(p.z/perz);
    p.y = abs(p.y)-2.; p.x = abs(p.x)-5.; p.z = mod(p.z,perz)-perz*0.5;
    float sy = .5;//+texture(iChannel0,vec2(id*0.002,0.25)).r;
    float d = box(p,vec3(0.1,sy,0.1));  

    p.x -= 2.; p.x += sin(id+dt(0.2,0.)*TAU)*0.2;
    d = min(d,od(p,0.1));

    p = still;
    p.x = abs(p.x)-(1.+sin(p.z*0.5+dt(.5,0.)*TAU)*0.5); p.y += sin(p.z+dt(0.25,1.)*TAU)*0.2;
    d = min(d, cyl(p, 0.1,1e10));

    p = still;
    mo(p.yz, vec2(0.5));
    p.y -= bouncy(0.2,0.); p.xz *= rot(dt(0.5,0.)*PI);    
    d = min(d,max(-sc(p,0.22),box(p,vec3(0.3))));

    float obj2 = od(p,0.05);
    g1 += 0.01/(0.01+obj2*obj2);
    d = min(d,obj2);

    return d;
}

vec3 getnorm (vec3 p)
{
    vec2 eps = vec2(0.01,0.);
    return normalize(SDF(p)-vec3(SDF(p-eps.xyy),SDF(p-eps.yxy),SDF(p-eps.yyx)));
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 center_uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;

    if(swa(0.1)<0.5) mo(center_uv,vec2(0.5));

    vec3 ro = vec3(center_uv*5.,-30.), rd = vec3(0.,0.,1.);

    vec3 p = ro, col = vec3(0.), l = normalize(vec3(1.,2.,-3.));

    bool hit = false;

    for (float i=0.;i<64.;i++)
    {
        float d = SDF(p);
        if (d<0.001)
        {
            hit = true;
            break;
        }
        p += d*rd;
    }

    if (hit)
    {
        vec3 n = getnorm(p);
        float light = max(dot(n,l),0.);
        col = mix(vec3(0.3,0.1,0.5),vec3(0.05,0.9,0.5),light);
    }
    col += g1*0.1;
    glFragColor = vec4(sqrt(col),1.);
}
