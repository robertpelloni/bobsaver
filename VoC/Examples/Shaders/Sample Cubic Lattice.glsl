#version 420

// original https://www.shadertoy.com/view/XldfW2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
* License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
* Created by bal-khan
*/

float     t; // time
float    a; // angle used both for camera path and distance estimator
float    id_t; // id used for coloring
vec3 id, h;
float hit;

#define I_MAX        200
#define E            0.000001
#define FAR            30.

vec2    march(vec3 pos, vec3 dir);
vec3    camera(vec2 uv);
vec2    rot(vec2 p, vec2 ang);
void    rotate(inout vec2 v, float angle);
vec3    calcNormal( in vec3 pos, float e, vec3 dir);
float    mylength(vec3 p, vec3 id);

void main(void)
{
    h*= .0;
    t  = time*.125;
    vec3    col = vec3(0., 0., 0.);
    vec2 R = resolution.xy,
          uv  = vec2(gl_FragCoord.xy-R/2.) / R.y;
    vec3    dir = camera(uv);
    vec3    pos = vec3(.0, .0, .0);
    
    vec2    inter = (march(pos, dir));

    col.xyz = step(id_t, 0.)*inter.x*.01*vec3(.2, .2, .37);
    //col.xyz += (id_t == 1.?1.:.0)*vec3(abs(sin(id.x*1.-inter.y*2.01+1.04)), abs(sin(id.y*1.-inter.y*2.01+2.09)), abs(sin(id.z*1.-inter.y*2.01+3.14)));
    //col.xyz += (id_t == 2.?1.:.0)*(vec3(.95-inter.y*.0521))*vec3(.25053, .5027, .2501);;
    //col.xyz += (id_t == 2.?1.:.0)*h;
    col.xyz += h;
    col *= min(1.,7./inter.y); // Thanks ocb
    glFragColor =  vec4(col,1.0);
}

float    de_0(vec3 p)
{
    float    mind = 1e5;

    rotate(p.yz, time*.1);
    p.z -= .5*time;
    rotate(p.xy, time*.50);
    vec3    pr = p;

    // take the fractional part of the ray (p), 
    // and offset it to get a range from [0.,1.] to [-.5, .5]
    // this is a space partitioning trick I saw on "Data Transfer" by srtuss : https://www.shadertoy.com/view/MdXGDr
    id = floor(pr.xyz);
    pr.xyz = fract(pr.xyz);
    pr -= .5;

    id = sin(id*1.+length(id))+1.;
    float lid = length(id);// This id is used to give each cube a different size
    mind = mylength(pr.yxz, vec3(length(id))*.1*1.0)-.010; // this is the cube grid
    mind = abs(mind)-.00001; // let's give the cubes some consistance
    mind = abs(mind)+.00001; // make them transparent
    // This is the coloring of the cubes, use these kind of things with sliders parameters to ease the pain :D
    h += vec3(.2, .2, .72)/max(.001, mind*mind*100000000000.0001 + 0.0);
    id_t = mind; // id of the object touched by the ray
    mind = max(mind, max(mind, -(length(pr.xyz)-1.*length(id)*.12) ) ); // this is the hole in the cubes
    id_t = (id_t != mind)? 1. : 0. ;
    
    // magic numbers : 2.09 == 2*(3.14/3), 4.18 == 4*(3.14/3)
    // this rotate space before making spheres out of this distorded space
    pr.y *= 1.*sin(t*6.66     +(p.z+p.y-p.x)*1.0 );
    pr.x *= 1.*sin(t*6.66+2.09+(p.z+p.y-p.x)*1.0 );
    pr.z *= 1.*sin(t*6.66+4.18+(p.z+p.y-p.x)*1.0 );
    float balls = length(pr)-.051;
    mind = min(mind, balls);
    id_t = mind == balls ? 2. : id_t;

    h += vec3(.852, .2, .2)/max(.001, balls*5000.1 + 50.0); // light my balls
    
    return (mind)*.5; // return distance * fudgefactor
}

float    scene(vec3 p)
{  
    float    mind = 1e5;

    mind = de_0(p);
    
    return (mind);
}

vec2    march(vec3 pos, vec3 dir)
{
    vec2    dist = vec2(0.0, 0.0);
    vec3    p = vec3(0.0, 0.0, 0.0);
    vec2    s = vec2(0.0, 0.0);

    hit = .0;
    for (int i = -1; i < I_MAX; ++i)
    {
        p = pos + dir * dist.y;
        dist.x = scene(p);
        dist.y += dist.x;
        if (dist.x < E || dist.y > FAR)
        {
            if (dist.x < E)
                hit = 1.;
            break;
        }
        s.x++;
    }
    s.y = dist.y;
    return (s);
}

// Utilities

float mylength(vec3 p, vec3 id)
{
    return max(abs(p.x)-id.x, max(abs(p.y)-id.y, abs(p.z)-id.z));
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
