#version 420

// original https://www.shadertoy.com/view/4tcfW4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
* License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
* Created by bal-khan
*/

vec2    march(vec3 pos, vec3 dir);
void    rotate(inout vec2 v, float angle);
float    mylength(vec2 p) {vec2 ap = abs(p); return max(ap.x, ap.y);}
float    mylength(vec3 p) {vec3 ap = abs(p); return max(ap.x, max(ap.y, ap.z));}
vec2    modA (vec2 p, float count);

vec3    ret_col, h;

#define I_MAX        200.
#define E            0.0001
#define FAR            15.

#define PI            3.14159
#define TAU            PI*2.

#define TRANSLUCENCY
//#define CHAOS_LINK
//#define NOGEARS // Real performance gain, no more blue gears though

void main(void)
{
    vec3    col = vec3(0., 0., 0.);
    vec2 R = resolution.xy,
    uv  = vec2(gl_FragCoord.xy-R/2.) / R.y;
    vec3    dir = vec3(uv, -1.);
    vec3    pos = vec3(.0, .0, 6.0);

    h*=0.;
    vec2    inter = (march(pos, dir));
    col += h*.005;
    glFragColor =  vec4(col,1.0);
}

float    scene(vec3 p)
{  
    float    var;
    float    mind = 1e5;
    vec3 rp =p;
    rotate(p.xz, 1.57-.125*time);
    vec2 q = vec2(length(p.xy)-2., p.z);
    var = atan(p.x,p.y) ;float id, var1;
    var1 = atan(q.x, q.y)*-3.;
    rotate(q, var*-9.+ var1 +time*-2.);
    var1 = atan(q.x, q.y)*1.;
    q = abs(q)-.25;//var;
    id = (var1*10.)/10.;
    //var = 1.*dot(q.x, p.z-0.)*10.+time*.0;
    
    #ifdef CHAOS_LINK
    q -= .25;
    rotate(q, var1*5.+time*-1.+id*.5*.0);
    q.x = abs(q.x)-.1252503;
        rotate(q, var1*-7.+time*-1.+id*.5*0.0);
    q.x = abs(q.x)-.12503;
        rotate(q, var1*7.+time*-.5+id*.5*0.0);
    q.x = abs(q.x)-.12503;
    #endif

    float var2 = sin(var*7.+id*1.+time*-0.)-1.;
    ret_col = 1.-vec3(.5-var2*.5*.0-id/30., .5+id/20., .3+var2*.5*.0+id/25.);
    ret_col = vec3(
        cos(id/2.+0.00+time)
        ,
        cos(id/2.+1.04+time)
        ,
        cos(id/2.+2.08+time)
    );
    //ret_col=abs(ret_col);
    mind = mylength(q)-.15-.1*var2;
    mind = abs(mind)-.0051;
    mind = abs(mind)-.0051;
    mind = abs(mind)-.0051;
    #ifdef TRANSLUCENCY
    mind = abs(mind)+.001;
    #endif
    ret_col = vec3(1.8, .2, .2)+ret_col;
    h += ret_col*vec3(1.)*.25/(.201+(mind-var2*0.)*(mind-var2*0.) );
    if (mind <= E*5000.)
    h += (1.-ret_col)*vec3(1.)*.005/(.0071001+(mind-var2*.0)*(mind-var2*.0)*.00051);

    #ifndef NOGEARS
    float b;
    p = rp;
    rotate(p.xz, 1.57+time*.25);
    rotate(p.xy, 1.57+time*.10);
    p.xz = modA(p.xz, 5.);
    p.yx = modA(p.yx, 8.);
    p.y -= 7.;
    p.xz = modA(p.xz, 5.);
    p.x -= 1.2;
    rotate(p.yz, 1.57+time*1.0);
    p.zy = modA(p.zy, 10.);
    p.z -= .50;
    p.xy = modA(p.xy, 20.);
    p.x -= .25;
    b = mylength(p)-.152525;
    b = abs(b)-0.001;
    b = abs(b)+0.0420751;
    mind = min(mind, b);
    h += vec3(.1, .232, .413)*.25/(.00810071001+(b)*(b)*10.);
    #endif
    return (mind);
}

vec2    march(vec3 pos, vec3 dir)
{
    vec2    dist = vec2(0.0, 0.0);
    vec3    p = vec3(0.0, 0.0, 0.0);

        for (float i = -1.; i < I_MAX; ++i)
        {
            p = pos + dir * dist.y;
            dist.x = scene(p);
            dist.y += dist.x*.2; // makes artefacts disappear
            if (dist.x < E || dist.y > FAR)
            {
                break;
            }
    }
    return dist;
}

// Utilities

void rotate(inout vec2 v, float angle)
{
    v = vec2(cos(angle)*v.x+sin(angle)*v.y,-sin(angle)*v.x+cos(angle)*v.y);
}

vec2 modA (vec2 p, float count) {
    float an = TAU/count;
    float a = atan(p.y,p.x)+an*.5;
    //idd = 3.14*floor((a-an*.5)*count)/count;
    a = mod(a, an)-an*.5;
    return vec2(cos(a),sin(a))*length(p);
}
