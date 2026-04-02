#version 420

// original https://www.shadertoy.com/view/MtVcWR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
* License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
* Created by bal-khan
*/

vec2    march(vec3 pos, vec3 dir);
vec3    camera(vec2 uv);
void    rotate(inout vec2 v, float angle);
vec3    calcNormal( in vec3 pos, float e, vec3 dir);
float    loop_circle(vec3 p);
float    circle(vec3 p, float phase);
float    sdTorus( vec3 p, vec2 t, float phase );
float    llength(vec2 p);
float    mylength(vec2 p);
float    mylength(vec3 p);
float    nrand( vec2 n );

float     t;            // time
vec3    bgd_col;    // bgd color
vec3    h;             // volumetric light
vec3    rc;         // light color

#define I_MAX        150.
#define E            0.0001
#define FAR            150.
#define PI            3.14159
#define TAU            PI*2.

void main(void)
{
    vec2 f = gl_FragCoord.xy;
    t  = time*.125;
    vec3    col = vec3(0., 0., 0.);
    vec2 R = resolution.xy,
          uv  = vec2(f-R/2.) / R.y;
    vec3    dir = camera(uv);
    vec3    pos = vec3(.0, .0, 60.0);

    h*=0.;
    rc = vec3(
        abs(sin(time*.25+0.00) )
           ,
        abs(sin(time*.25+1.04) )
        ,
        abs(sin(time*.30+2.08) )
    );
    vec2    inter = (march(pos, dir));
    bgd_col = vec3(.90, .82, .70);
    col.xyz = bgd_col*(1.-inter.x*.005)*.5;
    col += h*.1005*-.5;
    glFragColor =  vec4(col,1.0);
}

/*
* Leon's mod polar from : https://www.shadertoy.com/view/XsByWd
*/

vec2 modA (vec2 p, float count) {
    float an = TAU/count;
    float a = atan(p.y,p.x)+an*.5;
    a = mod(a, an)-an*.5;
    return vec2(cos(a),sin(a))*length(p);
}

/*
* end mod polar
*/

float sdTorus( vec3 p, vec2 t )
{
    vec2 q = vec2(length(p.xy)-t.x,p.z);

    return length(q)-t.y;
}

vec3    floorify(vec3 rp) 
{
    float var = 4000.+.0*atan((rp.x)-0., rp.y - 0.);
    return floor(var*rp)/var;//floor(rp*mod(cos(var*1.+time*.1)*.0+.0+max(time*.0251+.5, .5), 10.))/mod(+max(time*.0251+.5, .5), 10.)-.0;
}

vec2    floorify(vec2 rp) 
{
    float var = 10.+.0*atan((rp.x)-0., rp.y - 0.);
    return floor(var*rp)/var;//floor(rp*mod(cos(var*1.+time*.1)*.0+.0+max(time*.0251+.5, .5), 10.))/mod(+max(time*.0251+.5, .5), 10.)-.0;
}

float    scene(vec3 p)
{  
    float    mind = 1e5;
    float    toris = 1e5;
    p.z -= -15.;
    rotate(p.xz, 4.-1.*.35*time );
    rotate(p.yz, .0*1.57-.05*time );
    rotate(p.xy, time*.5);
    vec2 q;
    float ata = atan(p.x, p.z);
    float sata = sin(ata*20.);
    q = vec2( llength(p.xz)-40., p.y );
    rotate(q, -time*3.0*.125);//+0.*cos(.0*atan(p.x, p.z)+0.*atan(q.x, q.y)-time*1.*.0)*3.14/12. );

    float ata2 = atan(q.x, q.y);
        rotate(q, -time*1.+ata*.5);
    q.xy = modA(q.xy, 2.);q.x-=10.;
        rotate(q, -time*1.5+ata*1.);
    q.xy = abs(q.xy)-1.25;//-1.*sin(ata2*1.-time*2.+ata);
    q.x = max(abs(q.x), abs(q.y) )-2.;
    toris = mylength( q )-.50-.5*min(1.5, -.5+max(.5+-.5*sin(ata*20.+time*5.)*0.25, 1.+10.*sata));
    mind = toris;
    mind = mix(mind, abs(mind)+.005, .5 + .5*sin(-time+ata2+ata));

    h += (1.)*1./max(.01, toris*toris*1000.+ 2.25);
    h -= vec3(.5, .2,.15)*1./max(.01, mind*mind*1. + 2.001);
    
    return (mind);
}

vec2    march(vec3 pos, vec3 dir)
{
    vec2    dist = vec2(0.0, 0.0);
    vec3    p = vec3(0.0, 0.0, 0.0);
    vec2    s = vec2(0.0, 0.0);

        for (float i = -1.; i < I_MAX; ++i)
        {
            p = pos + dir * dist.y;
            dist.x = scene(p);
            dist.y += dist.x*.5; // makes artefacts disappear
            if (dist.x < E || dist.y > FAR)
            {
                break;
            }
            s.x++;
    }
    s.y = dist.y;
    return (s);
}

// Utilities

float llength(vec2 p)
{
    float ret;
    
    ret = max(
    abs(p.x)+.5*abs(p.y)
    ,
    abs(p.y)+.5*abs(p.x)
    );
    return ret;
}

float    mylength(vec2 p)
{
    float    ret;

    ret = max(abs(p.x), abs(p.y));
    
    return ret;
}

float    mylength(vec3 p)
{
    float    ret;

    ret = max(max(abs(p.x), abs(p.y)), abs(p.z));

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

vec3    camera(vec2 uv)
{
    float        fov = 1.;
    vec3        forw  = vec3(0.0, 0.0, -1.0);
    vec3        right = vec3(1.0, 0.0, 0.0);
    vec3        up    = vec3(0.0, 1.0, 0.0);

    return (normalize((uv.x) * right + (uv.y) * up + fov * forw));
}

vec3 calcNormal( in vec3 pos, float e, vec3 dir)
{
    vec3 eps = vec3(e,0.0,0.0);

    return normalize(vec3(
           march(pos+eps.xyy, dir).y - march(pos-eps.xyy, dir).y,
           march(pos+eps.yxy, dir).y - march(pos-eps.yxy, dir).y,
           march(pos+eps.yyx, dir).y - march(pos-eps.yyx, dir).y ));
}
