#version 420

// original https://www.shadertoy.com/view/XtjfWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2     cmult(vec2 a, vec2 b)
{
    return (vec2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x));
}

/*
** arthursw's line : https://www.shadertoy.com/view/MdB3zK
*/

vec2 rotate(vec2 v, float alpha)
{
    float vx = v.x*cos(alpha)-v.y*sin(alpha);
    float vy = v.x*sin(alpha)+v.y*cos(alpha);
    v.x = vx;
    v.y = vy;
    return v;
}

float line(vec2 p1, vec2 p2, vec2 p, float thickness)
{
    p -= p1;
    vec2 lineVector = p2-p1;
        
    float angle = -atan(lineVector.y,lineVector.x);
    p = rotate(p,angle);
    
    float dx = 0.0;
    if(p.x<0.0)
        dx = abs(p.x);
    else if(p.x>length(lineVector))
        dx = abs(p.x) - length(lineVector);
        
    return ( thickness/(dx+abs(p.y)) );
}

/*
**    end line
*/

void main(void)
{
    vec2 f = gl_FragCoord.xy;
    vec4 o = glFragColor;
    o = vec4(.0,.0,.0,1.);
    vec2 R = resolution.xy, u = (f.xy-R*.5) / R.yy;
    
    float    power = 2.+time*.5+5.+300.;
    float    modul = 151.+50.*sin(time*.0151);
    float    dist = 0.;
    float    old_dist = 0.;
    bool    hit;
    float rampsize = 1.0 / min(R.x, R.y);
    vec3    col = vec3(0.);
    float    s = u.x < 0. ? -1. : 1.;
    dist = step(.0, length(u-vec2(-.5,.0))-.5 )*step(length(u-vec2(-.5,.0))-.5, .0025 );
    o.xyz += vec3(1.)*dist;
    u.x = abs(u.x)-.5;
    u *=2.;
    
    for (float i = .0; i <= modul; i++)
    {
        if (s == 1.)
        u = (cmult(u,u) + vec2(-.5, -.55)+vec2(cos(.6215), sin(.6215)) );
        if (i > 3.)
        dist = max(old_dist,
                   line(
                       vec2(cos(6.28*i/ modul ), sin(6.28*i/modul ) )
                       ,
                       vec2(cos(6.28*mod(i*power, modul)/modul ), sin(6.28*mod(i*power, modul)/modul ))
                       ,
                       u
                       ,
                       rampsize + .01
                   )
                  );
            if (dist > 0. && dist > old_dist )
                col = vec3(
                    sin(6.28*i/modul+0.00)
                    ,
                    sin(6.28*i/modul+1.04)
                    ,
                    sin(6.28*i/modul+2.08)
                );
        old_dist = dist;
        col = abs(col);
    }
    col *= vec3(.125);
    o.xyz += (dist)*col;
    //o = o * o * (3. - 2. * o);
    glFragColor = o;
}
