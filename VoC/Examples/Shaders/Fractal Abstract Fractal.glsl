#version 420

// original https://www.shadertoy.com/view/ltBcRK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
* License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
* Created by bal-khan
*/

#define I_MAX    150
#define E        0.000001

float    sdHexPrism( vec3 p, vec2 h );
float    sdBox( vec3 p, vec3 b );
void    rotate(inout vec2 v, float angle);
float    sdTorus( vec3 p, vec2 t );
vec2    march(vec3 pos, vec3 dir);
vec3    camera(vec2 uv);
vec3    blackbody(float Temp);
float    scene(vec3 p);

vec3    h;
float    t; // time

float    m, id;

void main(void)
{
    vec2 f=gl_FragCoord.xy;
    vec4 o;
    id *= 0.;
    h *= 0.;
    o.xyzw *= 0.;
    t = time*.5;
    vec2 R = resolution.xy,
          uv  = vec2(f-R/2.) / R.y;
    vec3    dir = camera(uv);
    vec3    pos = vec3(.0, .0, 10.0);
    vec2    inter = (march(pos, dir));
    o.xyz += vec3( abs(sin(t*1.+1.5+m+1.04)), abs(sin(t*1.+1.5+m+2.09)), abs(sin(t*1.+1.5+m+3.14)))*(1.-inter.x*.005);
    o.xyz -= vec3( abs(sin(id*t*1.+1.5+m+1.04)), abs(sin(id*t*1.+1.5+m+2.09)), abs(sin(id*t*1.+1.5+m+3.14)))*h*.00125;
    glFragColor=o;
}

float    scene(vec3 p)
{
    float r2,k=1.;
    float s_id;
    m = r2 = 1e5;
    p.z+=80.;
    rotate(p.zx, t+1.57);
    float   scale = 1.0625;
    for(float    i = 1.; i < 15.; ++i)
    {
        p.x = abs(p.x);
        p.z = abs(p.z-.35)-.35;
        p *= scale;
        rotate(p.zx, mix(2.3, 0., 1.+sin(time*.00251)));
        p.z -= 1.5;//(i+1.)/5.;
        p.x -= 4.5;
        rotate(p.yz, mix(.2, 7.85, 1.+sin(time*.1) ));
        p.x = -p.x;
        rotate(p.yx, .1);
        m = min(m, log(r2 )/abs(k) );
        k *= scale;
        s_id = max(abs(p.x), max(abs(p.y), abs(p.z)) )-1.5;
        r2= min(r2, max(abs(p.x), max(abs(p.y), abs(p.z)) )-1.5);
        id = (r2 == s_id) ? i : id;
        h += vec3(.5, .2,  .4)*.05/(r2*r2+.01);
    }
    h += vec3(.5, .2,  .4)*1./(r2*r2+.1);
    return r2;
}

vec2    march(vec3 pos, vec3 dir)
{
    vec2    dist = vec2(0.0);
    vec3    p = vec3(0.0);
    vec2    s = vec2(0.0);

    for (int i = 0; i < I_MAX; ++i)
    {
        p = pos + dir * dist.y;
        dist.x = scene(p);
        dist.y += dist.x*.1;
        if (log(dist.y*dist.y/dist.x/1e5)>0. || dist.x < E || dist.y > 140.)
        {
           break;
        }
        s.x++;
    }
    s.y = dist.y;
    return (s);
}

// Utilities

float    mylength(vec2 p)
{
    float    ret = 0.;
     p = p*p*p*p;
    ret = pow(p.x+p.y, 1./4.);
    
    return (ret);
}

float sdTorus( vec3 p, vec2 t )
{
    vec2 q = vec2(length(p.zy)-t.x,p.x);

    return length(q)-t.y;
}

float sdHexPrism( vec3 p, vec2 h )
{
    vec3 q = abs(p);
    return max(q.z-h.y,max((q.x*0.866025+q.y*0.5),q.y)-h.x);
}

float sdBox( vec3 p, vec3 b )
{
  return length(max(abs(p)-b,0.0));
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
