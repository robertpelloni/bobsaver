#version 420

// original https://www.shadertoy.com/view/llsBDS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
* License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
*/

float   t;

#define I_MAX       50
#define E           0.001
#define FAR         30.

vec4    march(vec3 pos, vec3 dir);
vec3    camera(vec2 uv);
vec3    calcNormal(in vec3 pos, float e, vec3 dir);
vec2    rot(vec2 p, vec2 ang);
void    rotate(inout vec2 v, float angle);

vec3    id;
vec3    base;
vec3    h;

void main(void)
{
    vec2 uv = gl_FragCoord.xy;
    h *= 0.;
    t = time;

    vec2    u = (uv.xy - resolution.xy*.5) / resolution.y;
    
    vec3    pos = vec3(.0,.0,.0);
    vec3    dir = camera(u*3.);
    
    vec4    inter = (march(pos, dir));
    vec3    col = vec3(0, 0, 0);

    base = vec3
        (
            abs(sin(id.z+id.x+id.y+0.00) )
            ,
            abs(sin(id.z+id.x+id.y+1.04) )
            ,
            abs(sin(id.z+id.x+id.y+2.08) )
        );
    if (inter.y == 1.)
        col.xyz = base * ( -1.*inter.w*.05 + 1. -inter.x*.001 )-h;

    glFragColor =  vec4(col, 1.);
}    

float   mylength(vec3 p)
{
    float   ret = 1e5;
    
    p = p*p;
    p = p*p;
    p = p*p;
    
    ret = p.x + p.y + p.z;
    ret = pow(ret, 1./8.);
    
    return ret;
}

float   mylength(vec2 p)
{
    float   ret = 1e5;
    
    p = p*p;
    p = p*p;
    p = p*p;
    
    ret = p.x + p.y;
    ret = pow(ret, 1./8.);
    
    return ret;
}

float   scene(vec3 p)
{
    float   mind = 1e5;
    p.z -= time*2.;

    p.y += sin(time*-1.+p.z*.5)*.5;
    p.x += cos(time*-1.+p.z*.5)*.5;
    rotate(p.xy, p.z*.25 + 1.0*sin(p.z*.06125 - time*0.5) + .25*time);

    vec3    pr = p;
    
    pr.xy = fract(p.xy*.5)-.5;
    id = vec3(floor(p.xy*.5), floor(p.z*5.));
    p.z += (mod(id.x*1., 2.)-1. == 0. ? 5. : 0. );
    p.z += (mod(id.y*1., 2.)-1. == 0. ? 5. : 0. );
    rotate(pr.xy, clamp( +(mod(id.x, 2.)-1. == 0. ? 1. : -1.) + (mod(id.y, 2.)-1. == 0. ? 1. : -1.), -2., 2.) * time*2.+(mod(id.x, 2.)-1. == 0. ? -1. : -1.)*p.z*2.5 + time*1. );
    
    pr.xy = abs(pr.xy)-.05-(sin(p.z*0.5+time*0.)*.15);
    pr.xy *= clamp(1./length(pr.xy), .0, 2.5);
    pr.z = (fract(pr.z*5.)-.5);
    mind = mylength(pr.xy*(.1*pr.z+.5))-.051;
    
    return(mind);
}

vec4    march(vec3 pos, vec3 dir)
{
    vec2    dist = vec2(0.0, 0.0);
    vec3    p = vec3(0.0, 0.0, 0.0);
    vec4    step = vec4(0.0, 0.0, 0.0, 0.0);
    vec3    dirr;
    //rotate(dir.zy, .7);
    //rotate(dir.xy, 1.7);
    //rotate(dir.xz, 1.7);
    
    for (int i = -1; i < I_MAX; ++i)
    {
        dirr = dir;
        rotate(dirr.zx, .025*dist.y );
        p = pos + dirr * dist.y;
        dist.x = scene(p)*1.;
        dist.y += dist.x;
        vec3    s = p- 1.*vec3(.0,7.0,0.0); // lightpos
        float   d = length(s.xy)-.1;
        h -= vec3(.3, .2, .0)*.1/ (d+.01);    // it brightens the scene but u can see an ugly cylinder
                                            // on the top-middle when not hidden by the scene
        h += (
            .001/(dist.x*dist.x+0.01) 
            -
            1./(dist.y*dist.y+40.)
             )
        ;
        if (log(dist.y*dist.y/dist.x/1e5)>0. || dist.x < E || dist.y >= FAR)
        {
            if (dist.x < E || log(dist.y*dist.y/dist.x/1e5)>0.)
                step.y = 1.;
            break;
        }
        step.x++;
    }
    step.w = dist.y;
    return (step);
}

// Utilities

void rotate(inout vec2 v, float angle)
{
    v = vec2(cos(angle)*v.x+sin(angle)*v.y,-sin(angle)*v.x+cos(angle)*v.y);
}

vec3 calcNormal( in vec3 pos, float e, vec3 dir)
{
    vec3 eps = vec3(e,0.0,0.0);

    return normalize(vec3(
           march(pos+eps.xyy, dir).w - march(pos-eps.xyy, dir).w,
           march(pos+eps.yxy, dir).w - march(pos-eps.yxy, dir).w,
           march(pos+eps.yyx, dir).w - march(pos-eps.yyx, dir).w ));
}

vec3    camera(vec2 uv)
{
    float       fov = 1.;
    vec3        forw  = vec3(0.0, 0.0, -1.0);
    vec3        right = vec3(1.0, 0.0, 0.0);
    vec3        up    = vec3(0.0, 1.0, 0.0);

    return (normalize((uv.x-.85) * right + (uv.y-0.5) * up + fov * forw));
}
