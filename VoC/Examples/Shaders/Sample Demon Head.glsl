#version 420

// original https://www.shadertoy.com/view/4lsfWX

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
float    mylength(vec2 p);
float    nrand( vec2 n );

float     t;            // time
vec3    ret_col;    // torus color
vec3    h;             // light amount

#define I_MAX        200.
#define E            0.00001
#define FAR            25.
#define    PI            3.14159
#define TAU            PI*2.

void main(void)
{
    vec2 f = gl_FragCoord.xy;
    t  = time*.125;
    vec3    col = vec3(0., 0., 0.);
    vec2 R = resolution.xy,
          uv  = vec2(f-R/2.) / R.y;
    vec3    dir = camera(uv);
    vec3    pos = vec3(.0, -1.0, .0);

    pos.z = 10.5+1.5*sin(t*15.);    
    h*=0.;
    vec2    inter = (march(pos, dir));
    if (inter.y <= FAR)
        col.xyz = ret_col*(1.-inter.x*.0025+inter.y*.025);
    else
        col = vec3(.1,.2,.5);
    col += h*.005125;
    glFragColor =  vec4(col,1.0);
}

/*
**    Leon's mod polar from : https://www.shadertoy.com/view/XsByWd
*/

vec2 modA (vec2 p, float count) {
    float an = TAU/count;
    float a = atan(p.y,p.x)+an*.5;
    a = mod(a, an)-an*.5;
    return vec2(cos(a),sin(a))*length(p);
}

/*
**    end mod polar
*/

float Cylinder(in vec3 p, in float r, in float h) 
{
    return max(length(p.xz) - r, abs(p.y) - h);
}

float    scene(vec3 p)
{
    float    var;
    float    mind = 1e5;
    rotate(p.xz, +.75*cos(1.*time) );
    rotate(p.yz, -3.14+.5*sin(-.5*time) );
    vec3    op = p;
    vec2 q = vec2(length(p.xy)-2.,p.z);
    var = 1.*atan(p.x,p.y);
    var = .25-abs(var);
    rotate(q, var*3.+time*2.);
    q.xy = abs(q.xy)-.251;
    var=floor(var*5.)/5.;
    ret_col = 1.-vec3(.5-.5, .5, .3+.5);
    mind = mylength(q)-.253125-.09*var;
    
    op.y -= 4.5;
    rotate(op.yz, 3.14-1.57);
    rotate(op.zx, 3.14);
    q = vec2(length(op.yz)-2., op.x);
    var = 1.*atan(op.y, op.z)*2.;
    rotate(q, var*1.+time*2.);
    q.xy = abs(q.xy)-.251;
    mind = min(mind, length(q)-.25-.09*var*1.);
    
    op = p;
    float    var2 = atan(op.x, op.y);
    var2= -3.+abs(var2);
    rotate(op.xy, time);
    float    var3 = atan(op.x, op.y);
    op.xy = modA(op.xy, 22.);
    op.x -= 2.;
    rotate(op.yz, -time*5.);
    rotate(op.zx, -time*4.);
    // 0.15915 == 1./(2. * pi)
    mind = min(mind
               ,
               (
                   mod(11.*var3*0.15915, 1.)-.5 <= 0.
               )
               ?
               max(abs(op.x), max(abs(op.y), abs(op.z) )) - .15-.1*(var2 )
               :
               length(op) - .15-.1*(var2 )
              
              );
    op = p;
    op.y -= 2.5;
    mind = min(mind, length(op) - 1.5);
    
    op = p;
    op.y -= 1.5;
    op.z -= -1.;
    float ball = length(op)-.5;
    mind = min(mind, ball);
    h += (mind == ball) ? vec3(.2, .1, .5)*.5/(ball * ball + .01) : vec3(0.);
    ret_col = (mind == ball) ? vec3(-1.0, -.2, -1.0) : ret_col;

    // this must be one of the most inneficient way to draw a pentagram
    // 18 degree = 0,314159
    const float angle = 0.314159;
    op = p;
    op.y+=.25;
    op.x += .15*2.;
    rotate(op.xy, angle);

    float    pentagram = Cylinder(op, .015, 1.);
    op = p;
    op.y+=.25;
    op.x -= .15*2.;
    rotate(op.xy, -angle);
    pentagram = min(pentagram, Cylinder(op, .015, 1.));
    op = p;
    op.y+=.25;
    op.y -= -.11*2.;
    rotate(op.xy, -5.*angle);
    pentagram = min(pentagram, Cylinder(op, .015, 1.));
    op = p;
    op.y+=.25;
    op.x -= -.1*2.;
    op.y -= .18*2.;
    rotate(op.xy, 7.*angle);
    pentagram = min(pentagram, Cylinder(op, .015, 1.));
    op = p;
    op.y+=.25;
    op.x -= .1*2.;
    op.y -= .18*2.;
    rotate(op.xy, -7.*angle);
    pentagram = min(pentagram, Cylinder(op, .015, 1.));
    mind = min(mind, pentagram);
    ret_col = (mind == pentagram) ? vec3(1.0, .82, .50) : ret_col;
    h += (mind == pentagram) ? vec3(1.,.5,.7)/(pentagram*pentagram+.1) : vec3(0.) ;
    
    
    op = p;
    op.y -= 2.;
    op.z -= -1.25;
    op.x = abs(op.x)-.55;
    float eyes = length(op)-.25;
    mind = min(mind, eyes); // eyes
    ret_col = (mind == eyes) ? vec3(.8, .1, .15) : ret_col;
    h += (mind == eyes) ? vec3(.4, .1, .1)/(eyes*eyes+.051) : vec3(0.);
    
    
    op = p;
    op.y -= 2.8;
    op.z -= -.5;
    float    mouth = length(op*vec3(.55,1.25,.5) )-.6;
    mind = max(mind, -mouth);
    ret_col = (mind == -mouth ) ? vec3(0.72) : ret_col;
    h -= (mind == -mouth ) ? vec3(.25, .55, .26)/(mouth*mouth + .251) : vec3(.0) ;

    op = p;
    op.y -= 2.8;
    op.z -= -1.1;
    op.xy = modA(op.xy*vec2(.55, 1.25), 15.);
    op.x -= .4;
    float    teeth = max(abs(op.x), max(abs(op.y), abs(op.z) ) )-.0525;
    mind = min(mind, teeth);
    ret_col = (mind == teeth) ? vec3(1., 1.0, 1.0) : ret_col;

    h -= vec3(.75,.8,.5)*.05/(.00815+mind*mind);
    
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
            if (log(dist.y*dist.y/dist.x/1e5)>0. || dist.x < E || dist.y > FAR)
            {
                break;
            }
            s.x++;
    }
    s.y = dist.y;
    return (s);
}

float    mylength(vec2 p)
{
    float    ret;
    
    p = p*p*p*p;
    p = p*p;
    ret = (p.x+p.y);
    ret = pow(ret, 1./8.);
    
    return ret;
}

// Utilities

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
