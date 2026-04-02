#version 420

// original https://www.shadertoy.com/view/ltlBDS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
* License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
*/

float     t;

#define I_MAX        100
#define E            0.00001
#define FAR            30.

vec4    march(vec3 pos, vec3 dir);
vec3    camera(vec2 uv);
vec3    calcNormal(in vec3 pos, float e, vec3 dir);
vec2    rot(vec2 p, vec2 ang);
void    rotate(inout vec2 v, float angle);
float    mylength(vec2 p);
float    mylength(vec3 p);

vec3    id;
vec3    h;

void main(void)
{
    vec2 f = gl_FragCoord.xy;
    h *= 0.;
    t = time;
    vec3    col = vec3(0., 0., 0.);
    vec2    uv  = vec2(.35+f.x/resolution.x, f.y/resolution.y);
    vec3    dir = camera(uv);
    vec3    pos = vec3(-.0, .0, 25.0-sin(time*.125)*25.*0.-21.+2.);

    vec4    inter = (march(pos, dir));

    col = .5 - h;

    glFragColor =  vec4(col, h.x);
}

float    scene(vec3 p)
{
    float    mind = 1e5;
    p.z -= -20.;
    p.z -= time*5.;

    p.y += sin(time*-1.+p.z*.5)*.5;
    p.x += cos(time*-1.+p.z*.5)*.5;
    rotate(p.xy, p.z*.25 + 1.0*sin(p.z*.125 - time*0.5) + 1.*time);
    
    float    tube = max(-(length(p.yx)-2.), (length(p.yx)-8.));
    tube = max(tube, p.z-10.-0./length(p.yx*.06125) );
    tube = max(tube, -p.z-10.-0./length(p.yx*.06125) );
    vec3    pr = p;
    
    pr.xy = fract(p.xy*.5)-.5;
    id = vec3(floor(p.xy*.5), floor(p.z*2.));
    p.z += (mod(id.x*1., 2.)-1. == 0. ? 5. : 0. );
    p.z += (mod(id.y*1., 2.)-1. == 0. ? 5. : 0. );
    rotate(pr.xy, clamp( (mod(floor(p.z*.5), 2.)-1. == 0. ? 1. : -1.)+(mod(id.x, 2.)-1. == 0. ? 1. : -1.) + (mod(id.y, 2.)-1. == 0. ? 1. : -1.), -2., 2.) * time*2.+(mod(id.x, 2.)-1. == 0. ? -1. : -1.)*p.z*2.5 + time*0. );
    
    pr.xy = abs(pr.xy)-.05-(sin(p.z*0.5+time*0.)*.15);
    pr.xy *= clamp(1./length(pr.xy), .0, 2.5);
    pr.z = (fract(pr.z*2.)-.5);
    mind = mylength(vec2(mylength(pr.xy)-.1, pr.z ))-.04;
    
    return(mind);
}

vec4    march(vec3 pos, vec3 dir)
{
    vec2    dist = vec2(0.0, 0.0);
    vec3    p = vec3(0.0, 0.0, 0.0);
    vec4    step = vec4(0.0, 0.0, 0.0, 0.0);
    vec3    dirr;

    for (int i = -1; i < I_MAX; ++i)
    {
        dirr = dir;
        rotate(dirr.zx, .025*dist.y );
        p = pos + dirr * dist.y;
        dist.x = scene(p);
        dist.y += dist.x*.5;
        vec3    s = p- 1.*vec3(.0,7.0,0.0);
        float    d = length(s.xy)-.1;
        h -= vec3(.3, .2, .0)*.1/ (d+.0);
        h += (
            .001/(dist.x*dist.x+0.01) 
            -
            1./(dist.y*dist.y+40.)
             )
            *
            vec3
        (
            abs(sin(id.z+id.x+id.y+0.00) )
            ,
            abs(sin(id.z+id.x+id.y+1.04) )
            ,
            abs(sin(id.z+id.x+id.y+2.08) )
        );
        // log trick by aiekick
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

float    mylength(vec3 p)
{
    float    ret = 1e5;
    
    p = p*p;
    p = p*p;
    p = p*p;
    
    ret = p.x + p.y + p.z;
    ret = pow(ret, 1./8.);
    
    return ret;
}

float    mylength(vec2 p)
{
    float    ret = 1e5;
    
    p = p*p;
    p = p*p;
    p = p*p;
    
    ret = p.x + p.y;
    ret = pow(ret, 1./8.);
    
    return ret;
}

void rotate(inout vec2 v, float angle)
{
    v = vec2(cos(angle)*v.x+sin(angle)*v.y,-sin(angle)*v.x+cos(angle)*v.y);
}

vec2    rot(vec2 p, vec2 ang)
{
    float    c = cos(ang.x);
    float    s = sin(ang.y);
    mat2    m = mat2(c, -s, s, c);
    
    return (p * m);
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
    float        fov = 1.;
    vec3        forw  = vec3(0.0, 0.0, -1.0);
    vec3        right = vec3(1.0, 0.0, 0.0);
    vec3        up    = vec3(0.0, 1.0, 0.0);

    return (normalize((uv.x-.85) * right + (uv.y-0.5) * up + fov * forw));
}
