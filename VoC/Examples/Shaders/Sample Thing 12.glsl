#version 420

// original https://www.shadertoy.com/view/XldBWf

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
float    mylength(vec3 p);
float    mylength(vec2 p);
vec3     cameraLookAt(vec3 target, vec3 camPos, vec3 up, vec2 uv, float camNear);

float     t;            // time
vec3    ret_col;    // torus color
vec3    h;             // light amount

#define I_MAX        200.
#define E            0.0001
#define FAR            100.
#define PI            3.14

void main(void)
{
    t  = time*.125;
    vec3    col = vec3(0., 0., 0.);
    vec2 R = resolution.xy,
          uv  = vec2(gl_FragCoord.xy-R/2.) / R.y;
    vec3    pos = vec3(.250+0.*clamp((1.-1.*exp((-time+20.))), .0, 1.), .250+0.*clamp((1.-1.*exp((-time+20.))), .0, 1.), 20.0);

    vec3    dir = camera(uv);
    //cameraLookAt(vec3(.0, .0, .0), pos, vec3(.0,  1., .0), uv, .3);

    h*=0.;
    vec2    inter = (march(pos, dir));
    col += h*.00625125;
    glFragColor =  vec4(col,1.0);
}

// iq's Capsule sdf modified
float sdThing( vec3 p, vec3 a, vec3 b, float r )
{
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    vec3 pbh = pa - ba*h;
    return max(1.5,mylength(pbh)) - r*length( pbh )*.25;
}

float    scene(vec3 p)
{  
    float    var;
    float    mind = 1e5;
    p.z -=-30.;
    rotate(p.xz, 1.57*1.0-1.05*time*1.0+.5*sin(time*2.));
    
    vec3 pp = p;
    ret_col = 1.-vec3(.5, .5, .3);
    
    rotate(p.zy, -time*.125+p.x*(.125+.105*sin(-time*.25) ));
    
    mind = sdThing(p, vec3(-10., -5.0*cos(time*1.+p.x*.5), -5.0*sin(time*1.+p.x*.5) ), vec3(10.,.0,.0), 2.5);
    mind = abs(mind)-.25;
    mind = mix(mind, max(mind, sin(p.x*3.+time*50.)+.998), .5 + .5*sin(time*.25));    
    mind = mix(abs(mind)+.01, mind, .5 + .5*sin(time*.25));

    h += vec3(2.75,.8,.5)*vec3(1.)*.0125/max(.01, (mind)*(mind) );

    return (mind)*.25;
}

vec2    march(vec3 pos, vec3 dir)
{
    vec2    dist = vec2(0.0, 0.0);
    vec3    p = vec3(0.0, 0.0, 0.0);
    vec2    s = vec2(0.0, 0.0);
    for (float i = -1.; i < I_MAX; ++i)
    {
           p = pos + dir * dist.y;
        dist.x = scene(p)*1.;
        dist.y += dist.x; // makes artefacts disappear
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

float    mylength(vec3 p) {return max(max(abs(p.x), abs(p.y)), abs(p.z));}
float    mylength(vec2 p) {return (max(abs(p.x), abs(p.y)));}

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

vec3 cameraLookAt(vec3 target, vec3 camPos, vec3 up, vec2 uv, float camNear)
{
    vec3 axisZ = normalize(target - camPos);
    vec3 axisX = cross(axisZ, up);
    vec3 axisY = cross(axisX, axisZ);
    return normalize(axisX * uv.x + axisY * uv.y + camNear * axisZ); 
}

vec3 calcNormal( in vec3 pos, float e, vec3 dir)
{
    vec3 eps = vec3(e,0.0,0.0);

    return normalize(vec3(
           march(pos+eps.xyy, dir).y - march(pos-eps.xyy, dir).y,
           march(pos+eps.yxy, dir).y - march(pos-eps.yxy, dir).y,
           march(pos+eps.yyx, dir).y - march(pos-eps.yyx, dir).y ));
}
