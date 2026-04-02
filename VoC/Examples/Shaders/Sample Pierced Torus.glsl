#version 420

// original https://www.shadertoy.com/view/4ddfz4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
* License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
* Created by bal-khan
*/

#define I_MAX    150
#define E        0.00001

float    sdTorus( vec3 p, vec2 t );
vec2    march(vec3 pos, vec3 dir);
vec3    camera(vec2 uv);
vec2    rot(vec2 p, vec2 ang);
float    mylength(vec3 p);
float    mylength(vec2 p);
void    rotate(inout vec2 v, float angle);

float    t;
vec3    h;
float    mind;

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

    col.xyz += h;
    glFragColor = vec4(col.xyz,1.0);
}

float    scene(vec3 p)
{
    mind = 1e5;
    p.z-= -30.;
    rotate(p.zy, time*.25);
    vec3    ap = p;
    
    vec2 q = vec2(length(p.xy)-25., p.z);
    float at = atan(ap.x, ap.y);

    float to = cos(at*40.);
    to = cos(time*3.+ ( atan(q.x, q.y)*8.) +at*20.);
    
    mind = length(q)-14.-to*.025;
    mind = max(mind, to);
    mind = max(mind, -(length(q)-13.998) );
    h += .00125*vec3(.8, .62, 1.1)*1./max(mind*mind*.1+0.071, .00001);
    return(mind);
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
        //rotate(dirr.xz, +dist.y*.000+.25*sin(t*.25+dist.y*.005) );
        p = pos + dirr * dist.y;
        dist.x = scene(p);
        dist.y += dist.x;
        if (dist.x < E || dist.y > 500.)
        {
           break;
        }
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

void rotate(inout vec2 v, float angle)
{
    v = vec2(cos(angle)*v.x+sin(angle)*v.y,-sin(angle)*v.x+cos(angle)*v.y);
}

float    mylength(vec2 p)
{
    return max(abs(p.x), abs(p.y));
}

float    mylength(vec3 p)
{
    return max(max(abs(p.x), abs(p.y)), abs(p.z));
}

vec3    camera(vec2 uv)
{
    float   fov = 1.;
    vec3    forw  = vec3(0.0, 0.0, -1.0);
    vec3    right = vec3(1.0, 0.0, 0.0);
    vec3    up    = vec3(0.0, 1.0, 0.0);

    return (normalize((uv.x) * right + (uv.y) * up + fov * forw));
}
