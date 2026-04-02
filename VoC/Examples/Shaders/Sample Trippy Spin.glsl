#version 420

// original https://www.shadertoy.com/view/MdjcDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define I_MAX    150
#define E        0.001

/*
* License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
* Created by bal-khan
*/

//#define WOBBLY

float    sdTorus( vec3 p, vec2 t );
vec2    march(vec3 pos, vec3 dir);
vec3    camera(vec2 uv);
vec2    rot(vec2 p, vec2 ang);
float    t;
vec3    h;

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

#define L1 vec3(-3.,2., -5.)
const vec3    lightCol = vec3(1.,.7,.51);
vec3 evaluateLight(vec3 pos)
{
    vec3    dist = L1-pos-vec3(sin(t*8.)*3.,cos(t*8.)*3.,5. );
    dist = (dist*dist*dist*dist*dist);
    float distanceToL = pow(dist.x+dist.y*dist.z, 1./5.);
    return (
            lightCol * .250/(distanceToL*distanceToL)
            );
}

void main(void)
{
    h = vec3(0.);
    t = time;
    vec2 R = resolution.xy,
    uv  = vec2(gl_FragCoord.xy-R/2.) / R.y;
    vec3    dir = camera(uv);
    vec4    col = vec4(0.0);
    vec3    pos = vec3(.0, .0, 5.0);

    vec2    inter = (march(pos, dir));

    col.xyz = blackbody((15.-inter.y*.06125+.1*inter.x)*100.);

    glFragColor = col+inter.y*.001*vec4(.0, 1.2, 1., 1.)*2.;
}

float    scene(vec3 p)
{
    float    mind = 1e5;
    float    lit  = 1e5;
    lit = length(p-L1)-.0;

    mind = -sdTorus(p, vec2(15.5, 3.5) );

    p.y = max(
              ( (sin(+t+abs(p.y)-abs(p.x) ) +(+abs(p.x)-abs(p.y) ) ) )
              ,
              ( (sin(-t+abs(p.x)-abs(p.y) ) +(-abs(p.x)+abs(p.y) ) ) ) 
             )-30.5;

    p.x = max(60.0, abs(p.x)+20. );
    p.x= abs(p.x-.0750*p.y)+.1251*p.z+.15*p.y;

    p.yz *= mat2(cos(t*.25-p.z*.061+cos(-t*.25+p.z*.061+sin(t*1.+p.z*.1) )), sin(t*.25-p.z*.061+cos(-t*.25+p.z*.061+sin(t*1.+p.z*.1) )), -sin(t*.25-p.z*.061+cos(-t*.25+p.z*.061+sin(t*1.+p.z*.1) )), cos(t*.25-p.z*.061+cos(-t*.25+p.z*.061+sin(t*1.+p.z*.1) )) );

    mind += sdTorus(p, vec2(5., 1.75) );
    return(mind);
}

void rotate(inout vec2 v, float angle)
{
    v = vec2(cos(angle)*v.x+sin(angle)*v.y,-sin(angle)*v.x+cos(angle)*v.y);
}

vec2    march(vec3 pos, vec3 dir)
{
    vec2    dist = vec2(0.0);
    vec3    p = vec3(0.0);
    vec2    s = vec2(0.0);
    vec3    dirr;

    for (int i = -1; i < I_MAX; ++i)
    {
        dirr = dir;
        #ifdef WOBBLY
        rotate(dirr.xz, sin(t*2.+dist.y*.07)*.07);
        rotate(dirr.zy, sin(t*3.+dist.y*.07)*.07);
        #endif
        rotate(dirr.xy, (t+dist.y*.007) );
        p = pos + dirr * dist.y;
        dist.x = scene(p);
        dist.y += dist.x;
        h += evaluateLight(p);
        if (dist.x < E)
           break;
        s.x++;
    }
    s.y = dist.y;
    return (s);
}

float sdTorus( vec3 p, vec2 t )
{
    vec2 q = vec2(length(p.xy)-t.x,p.z);

    return length(q)-t.y;
}

vec3    camera(vec2 uv)
{
    float   fov = 1.;
    vec3    forw  = vec3(0.0, 0.0, -1.0);
    vec3    right = vec3(1.0, 0.0, 0.0);
    vec3    up    = vec3(0.0, 1.0, 0.0);

    return (normalize((uv.x) * right + (uv.y) * up + fov * forw));
}
