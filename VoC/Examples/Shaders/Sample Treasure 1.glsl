#version 420

// original https://www.shadertoy.com/view/3stSWr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Code by Flopine
// Thanks to wsmind, leon, XT95, lsdlive, lamogui, Coyhot, Alkama and YX for teaching me
// Thanks LJ for giving me the love of shadercoding :3

// Thanks to the Cookie Collective, which build a cozy and safe environment for me 
// and other to sprout :)  https://twitter.com/CookieDemoparty

#define ITER 100.
#define PI 3.141592
#define dt (time*0.3)

vec2 moda (vec2 p, float per)
{
    float a = atan(p.y, p.x);
    float l = length(p);
    a = mod(a-per/2., per)-per/2.;
    return vec2(cos(a),sin(a))*l;
}

mat2 rot (float a)
{return mat2(cos(a), sin(a), -sin(a), cos(a));}

float random (vec2 st)
{return fract(sin(dot(st.xy, vec2(12.2544, 35.1571)))*2418.56);}

float stmin(float a, float b, float k, float n)
{
    float st = k/n;
    float u = b-k;
    return min(min(a,b), 0.5 *(u+a+abs(mod(u-a+st, 2.*st)-st)));
}

float cyl (vec3 p, float r, float h)
{return max(length(p.xy)-r, abs(p.z)-h);}

float od (vec3 p, float d)
{return dot(p,normalize(sign(p)))-d;}

float sdHexPrism( vec3 p, vec2 h )
{
    const vec3 k = vec3(-0.8660254, 0.5, 0.57735);
    p = abs(p);
    p.xy -= 2.0*min(dot(k.xy, p.xy), 0.0)*k.xy;
    vec2 d = vec2(
        length(p.xy-vec2(clamp(p.x,-k.z*h.x,k.z*h.x), h.x))*sign(p.y-h.x),
        p.z-h.y );
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float g2 = 0.;
float room (vec3 p)
{
    p.y -= 3.;
    float d = -sdHexPrism(p.xzy, vec2(50.,20.));
    g2 += 0.1/(0.1+d*d);
    return d;
}

float column (vec3 p, float width)
{
    float c1 = length(p.xz)-width;

    p.xz *= rot(p.y*0.2);
    p.xz *= rot(time);
    p.xz = moda(p.xz, PI);
    p.x -= width;
    float c2 = length(p.xz)-(width*0.5);

    return min(c1, c2);
}

float columns (vec3 p)
{
    vec3 pp = p;
    p.xz = moda(p.xz, PI/3.);
    p.x -= 60.;
    float d = column(p,5.);

    return d;
}

float g1 = 0.;
float gem (vec3 p)
{
    p.xz *= rot(time*5.);
    float sp = 1.;
    float steps = 3.;
    float _od = od(vec3(p.x-sp,p.y,p.z),1.);
    float _od1 = od(vec3(p.x+sp,p.y,p.z),1.);
    float _od3 = od(vec3(p.x,p.y+sp,p.z),1.);
    float _od2 = od(vec3(p.x,p.y-sp,p.z),1.);
    float d = stmin(_od3,stmin(_od2,stmin(_od,_od1,0.5,steps),0.5,steps),0.5,steps);
    g1 += 0.1/(0.1+d*d);
    return d;
}

float pillars (vec3 p)
{ 
    vec3 pp = p;
    float c1 = mix(column(p,2.), gem(p), clamp(sin(time*0.5)*1.5+0.5,0.,1.));
    float c = 1e10;
    float aoffset = 0.;
    float offset = 0.;
    for (int i=0; i<2; i++)
    {
        p.xz *= rot(PI/(4.+aoffset));
        p.xz =  moda(p.xz, 2.*PI/5.);
        p.x -= 16.+offset;
        c = min(c, column(p,1.5));

        aoffset += 2.;
        offset ++;
    }
    return min(c1,max(-column(pp,8.),c));
}

float SDF (vec3 p)
{return stmin(room(p),min(columns(p),pillars(p)),3.,4.);}

vec3 palette (float t, vec3 a, vec3 b, vec3 c, vec3 d)
{return a+b*cos(2.0*PI*(c*t+d));}

vec3 get_cam (vec3 ro, vec3 target, vec2 uv, float fov)
{
    vec3 forward = normalize(target - ro);
    vec3 left = normalize(cross(vec3(0.,1.,0.), forward));
    vec3 up = normalize(cross (forward, left));
    return normalize(forward*fov+ left*uv.x + up*uv.y);
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;

    float dither = random(uv); 

    vec3 ro = vec3(-21.*cos(-dt),1.,-21.*sin(-dt)),
        p = ro,
        tar = vec3(0.),
        rd = get_cam(ro, tar, uv, 1.),
        col = vec3(0.);

    float shad = 0.;

    for (float i=0.; i<ITER; i++)
    {
        float d = SDF(p);
        if (d<0.001)
        {
            shad = i/ITER;
            break;
        }
        d *= 0.9+dither*0.1;
        p += d*rd;
    }

    col = vec3(shad)*0.1;
    vec3 g1_anim = mix(vec3(0.),
                       palette(length(p), vec3(0.5), vec3(0.5),vec3(0.5), vec3(0.8,0.7,0.8)), 
                       clamp(sin(time*0.5),0.,1.)
                      );
    vec3 g2_anim = mix(vec3(0.),
                       vec3(0.,length(uv)*0.5,0.7), 
                       clamp(sin(time*0.5),0.,1.)
                      );
    col += g1*g1_anim*0.3;
    col += g2*g2_anim*0.1;
    
    // Output to screen
    glFragColor = vec4(sqrt(col),1.0);
}
