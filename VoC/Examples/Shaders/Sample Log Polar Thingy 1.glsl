#version 420

// original https://www.shadertoy.com/view/WlBcWd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
* License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
*/

#define I_MAX        400
#define E            0.0001
#define FAR            2.

#define    FUDGE        1.

vec4    march(vec3 pos, vec3 dir);
vec3    camera(vec2 uv);
vec3    calcNormal(in vec3 pos, float e, vec3 dir);
void    rotate(inout vec2 v, float angle);
float    mylength(vec2 p);
float    mylength(vec3 p);

vec3    h;
vec3    volumetric;
vec2    mous;

#define PI            3.14159
#define TAU            PI*2.

#define SCALE 2.0/PI

float sdf(in vec3 pos3d)
{
    vec2 pos2d = pos3d.xz;
    
    float r = length(pos2d);
    float ata = atan(pos2d.y, pos2d.x);
    pos2d = vec2(
        log(r)+time*-.25+sin(ata*.25+.2290035)*2.28
        ,
        time*.125+ata
        );
    pos2d *= SCALE;
    pos2d = fract(pos2d) - 0.5;
    float mul = r;///SCALE;
    float ret = 
        (
            mylength(vec2(pos2d.x, pos3d.y/mul+.0*(pos3d.y+.205)/(mul)))
            - .1252125
        ) * mul/SCALE
        ;
//    ret = max(ret, -(length(vec2(pos2d.x, (fract(pos3d.x*20./mul)-.50)/(20.)) )-.0120023));
    ret = min(ret, (mylength(vec2(pos2d.x, (fract(pos3d.x*9./mul)-.50)/(9.)) )+.055-.050023*(1.42504041+pos3d.y*1./mul))*mul/SCALE);
    
    // middle tentacles
    ret = min(ret, (mylength(vec2(
        ( fract(pos2d.x*2.-.0)-.5)/2.
        , 
                                  ( fract((pos3d.y/mul+-2.20485)*.25)-.5)/2.
                                  //(fract(pos3d.x*3./mul)-.50)/(3.)
                            ))-.005125050023*1.*(.1+pos3d.y/mul) )*mul/SCALE);

    ret = min(ret, 
              
              max(
                  -(length(pos3d.zx)-.015)
                  ,
                  (mylength(vec2(
        ( (pos2d.x*1.-.0)-.5*.0)/1.-.0
        , 
                                  (.25+ fract((pos3d.x*1./mul+-0.020485*.0+-.125*.25*.0)*9.)-.5)/9.
                                  //(fract(pos3d.x*3./mul)-.50)/(3.)
                            ))
                    +.05-.050023*-(-0.7050+pos3d.y*1./mul)*step(-.50, pos3d.y/mul))*mul/SCALE)
                    //-.02512505125050023*1. )*mul/SCALE);
              );
    ret =
        min(
            ret
            ,
        (
            mylength(vec2(pos2d.x, pos3d.y/mul+.5+.0*(pos3d.y+.205)/(mul)))
            - .025252125
        ) * mul/SCALE
            )
        ;
    ret = max(ret, pos3d.y/mul+.05+.0*-.003125*-.750);
    h += vec3(.69, .5, .34)/max(.01, ret*70000. + 40.501510);
    return ret*1.*1.;
}

void main(void)
{
    h *= 0.;
    volumetric *= 0.;
    vec3    col = vec3(0., 0., 0.);
    vec2    R = resolution.xy;
    vec2    uv  = vec2((gl_FragCoord.xy-.5*R.xy)/R);
    vec3    dir = normalize(vec3(uv*vec2(1.,-1.), 1.));//camera(uv);
    vec3    pos = vec3(-.0, -.2105017501050*.450+.033, -2.0*.0-.2525045);
    mous = (mouse*resolution.xy.xy-R*.5) / R;
    

    vec4    inter = (march(pos, dir));
//    col += volumetric;
    if (inter.y <= E*1.)
    {
        col += smoothstep(.125, .9, 1.-.750*inter.w)*vec3(0.9, .75, .524);
        /*
        
        vec3    v = pos+(inter.w-E*0.)*dir;
        vec3    n = calcNormal(v, E*.1, dir);
        vec3 ref = reflect(dir,n);
        */
        vec3    v = pos+(inter.w-E*0.)*dir;
        vec3    n = calcNormal(v, E*.5, dir);
        vec3    ev = normalize(v - pos);
        vec3    ref_ev = reflect(ev, n);
        vec3    light_pos   = vec3(-100.0, 60.0, -50.0);
        vec3    light_color = vec3(.1, .4, .7);
        vec3    vl = normalize(light_pos - v);
        float    diffuse  = max(0.0, dot(vl, n));
        float    specular = pow(max(0.0, dot(vl, ref_ev)), 5.);
        col.xyz += light_color * (specular)+ diffuse * vec3(.51,.515, .53);
        col += h*-.235025;  
    }
    glFragColor =  vec4(col, h.x);
}

vec4    march(vec3 pos, vec3 dir)
{
    vec2    dist = vec2(0.0, 0.0);
    vec3    p = vec3(0.0, 0.0, 0.0);
    vec4    ret = vec4(0.0, 0.0, 0.0, 0.0);

    for (int i = -1; i < I_MAX; ++i)
    {
        p = pos + dir * dist.y;
        dist.x = sdf(p);
        dist.y += dist.x*FUDGE;
        if ( dist.x < E || dist.y > FAR)
            break;
    }
    ret.w = dist.y;
    ret.y = dist.x;
    return (ret);
}

// Utilities

float    mylength(vec3 p)
{
    float    ret = 1e5;

    p = abs(p);
    ret = max(p.x, max(p.y, p.z));
    
    return ret;
}

float    mylength(vec2 p)
{
    float    ret = 1e5;

    p = abs(p);
    
    ret = max(p.x, p.y);

    return ret;
}

float smin( float a, float b, float k )
{
    float res = exp( -k*a ) + exp( -k*b );
    return -log( res )/k;
}

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
    float        fov = 1.;
    vec3        forw  = vec3(0.0, 0.0, -1.0);
    vec3        right = vec3(1.0, 0.0, 0.0);
    vec3        up    = vec3(0.0, 1.0, 0.0);

    return (normalize((uv.x) * right + (uv.y) * up + fov * forw));
}
