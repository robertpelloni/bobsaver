#version 420

// original https://www.shadertoy.com/view/lsBBD1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
* License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
* Created by bal-khan
*/

#define I_MAX    50
#define E        0.01

#define I 12.

float    sdHexPrism( vec3 p, vec2 h );
float    sdBox( vec3 p, vec3 b );
float    distanceToL;
void    rotate(inout vec2 v, float angle);
float    sdTorus( vec3 p, vec2 t );
vec2    march(vec3 pos, vec3 dir);
vec3    camera(vec2 uv);
vec3    blackbody(float Temp);
float    scene(vec3 p);

float    aa;
mat2    ma;

vec3    light_pos;
vec3    h;
float    t; // time

float    ii,m;

void main(void)
{
    vec4 o;
    h *= 0.;
    o.xyz *= 0.;
    t = time*.5;
    vec2 R = resolution.xy,
          uv  = vec2(gl_FragCoord.xy-R/2.) / R.y;
    vec3    dir = camera(uv);
    vec3    pos = vec3(.0, .0, 1.0);
    vec2    inter = (march(pos, dir));
    if (inter.y < 20.)
        o.xyz += vec3( abs(sin(t*1.+ii*.1+m+1.04)), abs(sin(t*1.+ii*.1+m+2.09)), abs(sin(t*1.+ii*.1+m+3.14)))*(1.-inter.x*.05);

    o.xyz += h;
    glFragColor=o;
}

float    scene(vec3 p)
{
    distanceToL = 1e3;
    float r2,k=1.;
    ii=0.;
    m = r2 = 1e5;
    aa = t*.025;
    p.z+=6.;
    rotate(p.zx, t+1.57+0.*time);
    rotate(p.zy, t+1.57+0.*time);

    for(float    i = -1.; i < I; ++i)
    {
        ++ii;
        //r2 = min(r2, sdTorus(p, vec2(.521,.12) )); // torus based variant, comment 2 next lines if using 
        r2= min(r2, sdHexPrism(p, vec2(.3,.3)) );
        distanceToL = sdHexPrism(p, vec2(.3, .0))*32.;
        aa=aa+.5/(i+2.);
        if (mod(i, 3.) == 0.)
        {
            ma = mat2(cos(aa+1.*ii*.25),sin(aa+1.*ii*.25), -sin(aa+1.*ii*.25), cos(aa+1.*ii*.25) );
            p.xy*=ma;
            p.xy = abs(p.xy)-.125;
            p.z -= .2;
        }
        else if (mod(i, 3.) == 1.)
        {
            ma = mat2(cos(aa*3.+1.04+1.*ii*.1),sin(aa*3.+1.04+1.*ii*.1), -sin(aa*3.+1.04+1.*ii*.1), cos(aa*3.+1.04+1.*ii*.1) );
            p.yz*=ma;
            p.zy = abs(p.zy)-.125;
            p.x -= .2;
        }
        else if (mod(i, 3.) == 2.)
        {
            ma = mat2(cos(aa*2.+2.08+1.*ii*.5),sin(aa*2.+2.08+1.*ii*.5), -sin(aa*2.+2.08+1.*ii*.5), cos(aa*2.+2.08+1.*ii*.5) );
            p.zx*=ma;
            p.xz = abs(p.xz)-.125;
               p.y -= .2;
        }
    m = min(m, log(sdBox(p,vec3(.0612510))/(k*k) ) );
    k *= 1.125;
    }
    return r2;
}

vec3 evaluateLight(in vec3 pos)
{
    vec3    lightCol;
    lightCol = vec3(1.,.7,.2);
    return (
            lightCol * 1.0/(distanceToL*distanceToL)
            )*(.25);
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
        dist.y += dist.x;
        h += evaluateLight(p);
        if (dist.x < E || dist.y > 20.)
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
