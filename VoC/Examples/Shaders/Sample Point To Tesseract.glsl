#version 420

// original https://www.shadertoy.com/view/4dByzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
* License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
* Created by bal-khan
*/

#define I_MAX    100
#define E        0.001

#define L1    vec3(0., 0., 4.)
#define L2    vec3(st*3.,0.,4.+ct*3.)

vec3    P00;
vec3    P01;
vec3    P02;
vec3    P03;
vec3    P04;
vec3    P05;
vec3    P06;
vec3    P07;
vec3    P08;
vec3    P09;
vec3    P10;
vec3    P11;
vec3    P12;
vec3    P13;
vec3    P14;
vec3    P15;

void    rotate(inout vec2 v, float angle);
float    sdCapsule( vec3 p, vec3 a, vec3 b, float r );
vec2    march(vec3 pos, vec3 dir);
vec3    camera(vec2 uv);
vec3    blackbody(float Temp);
float    scene(vec3 p);
void    olala();

// --globals-- //
vec3    h;
float    g; //coloring id
float    t; // time
float    mine;
float    st;
float    ct;
vec3    e;
vec3    s;
// --globals-- //

const vec3    lightCol1 = vec3(.1,.3,.7);
const vec3    lightCol2 = vec3(.5,.3,.2);

// blackbody by aiekick : https://www.shadertoy.com/view/lttXDn

// -------------blackbody----------------- //

// return color from temperature 
//http://www.physics.sfasu.edu/astro/color/blackbody.html
//http://www.vendian.org/mncharity/dir3/blackbody/
//http://www.vendian.org/mncharity/dir3/blackbody/UnstableURLs/bbr_color.html

vec3 blackbody(float Temp)
{
    vec3 col = vec3(255.);
    col.x = 56100000. * pow(Temp,(-3. / 2.)) + 148.;
       col.y = 100.04 * log(Temp) - 623.6;
       if (Temp > 6500.) col.y = 35200000. * pow(Temp,(-3. / 2.)) + 184.;
       col.z = 194.18 * log(Temp) - 1448.6;
       col = clamp(col, 0., 255.)/255.;
    if (Temp < 1000.) col *= Temp/1000.;
       return col;
}

// -------------blackbody----------------- //

// sebH's volumetric light : https://www.shadertoy.com/view/XlBSRz

// ------------volumetric light----------- //

vec3 evaluateLight(in vec3 pos)
{
    float distanceToL = length(L1-pos);
    float distanceToL2 = length(L2-pos);
    return (
            lightCol2 * 1.0/(distanceToL*distanceToL)
           +lightCol1 * 1.0/(distanceToL2*distanceToL2)
            )*.5;
}

// ------------volumetric light----------- //
    
void main(void)
{
    t = time;
    P00 = vec3( -1., -1., -1. );
    e = vec3(exp(-t+2.19), exp(-t+4.57), exp(-t+8.00));
    s = vec3(step(2.19,t), step(4.57,t), step(8.00,t));
    olala();
    mine = 1e5;
    st = sin(t);
    ct = cos(t);

    vec2 R = resolution.xy,
          uv  = vec2(gl_FragCoord.xy-R/2.) / R.y;
    h = vec3(0.);
    
    vec3    dir = camera(uv);
    vec3    pos = vec3(.0, .0, 15.0);
    vec2    inter = (march(pos, dir));

    glFragColor.xyz = blackbody(((h.x+h.y+h.z) )*100.);
    glFragColor.xyz += vec3(abs(sin(t+1.04+g)), abs(sin(t+2.09+g)), abs(sin(t+3.14+g)))*(1.-inter.y*.0515);
    glFragColor.xyz *= (1.-length(uv)*1.); // vignette
    glFragColor.xyz += h*1.;
}

float    tesseract(vec3 p)
{
    float    r = 1e5;

    p.z+=-4.;

    rotate(p.yx, (t)*.25);
    rotate(p.zx, (t)*.25);

    r = min(r, sdCapsule(p, P00, P01, .1) );
    r = min(r, sdCapsule(p, P00, P02, .1) );
    r = min(r, sdCapsule(p, P01, P03, .1) );
    r = min(r, sdCapsule(p, P02, P03, .1) );

    r = min(r, sdCapsule(p, P04, P05, .1) );
    r = min(r, sdCapsule(p, P04, P06, .1) );
    r = min(r, sdCapsule(p, P05, P07, .1) );
    r = min(r, sdCapsule(p, P06, P07, .1) );

    r = min(r, sdCapsule(p, P00, P04, .1) );
    r = min(r, sdCapsule(p, P01, P05, .1) );
    r = min(r, sdCapsule(p, P02, P06, .1) );
    r = min(r, -1e5*s.y+s.x*1e5+sdCapsule(p, P03, P07, .1) );

    //

    r = min(r, sdCapsule(p, P08, P09, .1) );
    r = min(r, sdCapsule(p, P08, P10, .1) );
    r = min(r, sdCapsule(p, P09, P11, .1) );
    r = min(r, sdCapsule(p, P10, P11, .1) );

    r = min(r, sdCapsule(p, P12, P13, .1) );
    r = min(r, sdCapsule(p, P12, P14, .1) );
    r = min(r, sdCapsule(p, P13, P15, .1) );
    r = min(r, sdCapsule(p, P14, P15, .1) );

    r = min(r, sdCapsule(p, P08, P12, .1) );
    r = min(r, sdCapsule(p, P09, P13, .1) );
    r = min(r, sdCapsule(p, P10, P14, .1) );
    r = min(r, sdCapsule(p, P11, P15, .1) );

    //

    r = min(r, sdCapsule(p, P00, P08, .1) );
    r = min(r, sdCapsule(p, P01, P09, .1) );
    r = min(r, sdCapsule(p, P02, P10, .1) );
    r = min(r, 1e5*s.y+s.x*1e5-s.z*1e5*2.+sdCapsule(p, P03, P11, .1) );
    r = min(r, 1e5*s.y+s.x*1e5-s.z*1e5*2.+sdCapsule(p, P04, P12, .1) );
    r = min(r, 1e5*s.y+s.x*1e5-s.z*1e5*2.+sdCapsule(p, P05, P13, .1) );
    r = min(r, 1e5*s.y+s.x*1e5-s.z*1e5*2.+sdCapsule(p, P06, P14, .1) );
    r = min(r, 1e5*s.y+s.x*1e5-s.z*1e5*2.+sdCapsule(p, P07, P15, .1) );
    
    return (r);
}

float    scene(vec3 p)
{
    float    mind;
    mind = 1e5;

    mine = p.z+1.;
    mine = min(mine, +(p.x)+6.);
    mine = min(mine, -(p.x)+6.);
    mine = min(mine, +(p.y)+5.5);
    mine = min(mine, -(p.y)+5.5);
    mine = min(mine, length(p-L1)-.1);

    mind = tesseract(p);

    p-= L2;

    mind = min(mind, length(p)-.1);
    mind = min(mine, mind);

    return mind;
}

vec2    march(vec3 pos, vec3 dir)
{
    vec2    dist = vec2(0.0);
    vec3    p = vec3(0.0);
    vec2    s = vec2(0.0);
    
    for (int i = 1; i < I_MAX; ++i)
    {
        p = pos + dir * dist.y;
        dist.x = scene(p);
        dist.y += dist.x;
        h += evaluateLight(p)*.251125;
        if (dist.x < E || dist.y > 20.)
        {
            if(dist.x != mine)
                p=vec3(0.);
            g +=  (step(sin(20.*abs(p.y) ), .5) 
                  + step(sin(20.*abs(p.x) ), .5)
                  + step(sin(20.*abs(p.z) ), .5)
                 );
           break;
        }
        s.x++;
    }
    s.y = dist.y;
    return (s);
}

void    olala()
{
    P01 = P00+vec3(2.-2.*exp(-t), 0., 0. );
    P02 = P00+s.x*vec3(0., 2.-2.*e.x, 0. );
    P03 = P00+s.x*vec3(2., 2.-2.*e.x, 0. );
    P04 = P00+s.y*vec3(0., 0., 2.-2.*e.y );
    P05 = P00+s.y*vec3(2., 0., 2.-2.*e.y );
    P06 = P00+s.y*vec3(0., 2., 2.-2.*e.y );
    P07 = P00+s.y*vec3(2., 2., 2.-2.*e.y );
    P08 = P00+s.z*vec3(-2.+2.*e.z, -2.+2.*e.z, -2.+2.*e.z );
    P09 = P00+s.z*vec3(4.-2.*e.z, -2.+2.*e.z, -2.+2.*e.z );
    P10 = P00+s.z*vec3(-2.+2.*e.z, 4.-2.*e.z, -2.+2.*e.z );
    P11 = P00+s.z*vec3(4.-2.*e.z, 4.-2.*e.z, -2.+2.*e.z );
    P12 = P00+s.z*vec3(-2.+2.*e.z, -2.+2.*e.z, 4.-2.*e.z );
    P13 = P00+s.z*vec3(4.-2.*e.z, -2.+2.*e.z, 4.-2.*e.z );
    P14 = P00+s.z*vec3(-2.+2.*e.z, 4.-2.*e.z, 4.-2.*e.z );
    P15 = P00+s.z*vec3(4.-2.*e.z, 4.-2.*e.z, 4.-2.*e.z );
}

// Utilities

float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
    vec3 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

vec3    camera(vec2 uv)
{
    float   fov = 1.;
    vec3    forw  = vec3(0.0, 0.0, -1.0);
    vec3    right = vec3(1.0, 0.0, 0.0);
    vec3    up    = vec3(0.0, 1.0, 0.0);

    return (normalize((uv.x) * right + (uv.y) * up + fov * forw));
}

void rotate(inout vec2 v, float angle)
{
    v = vec2(cos(angle)*v.x+sin(angle)*v.y,-sin(angle)*v.x+cos(angle)*v.y);
}
