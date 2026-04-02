#version 420

// original https://www.shadertoy.com/view/cdVyWR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 c = gl_FragCoord.xy;

    float time = time*.1;
    vec3 d=vec3(c/resolution.xy-.5,.75);
    d.x *= 4./3.;
    d.x += sin(time)*.25;
    d.y *= -1.;
    d.y += cos(time)*.25;
    
    vec3 p=vec3(0,0,time);
    vec3 q;
    float td = 0.;
    for(int i=0;i<80;i++)
    {
        float nt = min(.4-dot(fract(p+.5)-.5, fract(p+.5)-.5), .25-p.y);
        td += nt;
        p+=d*nt;
        if(i==40)
        {
            q=p;
            
            p.z -= .01;
            p.y -= .01;
            
            d.x = cos(time);
            d.y = -.1;
            d.z = sin(time);
            
            td = 0.;
        }
    }
    ivec3 u=ivec3(q*1000.);
    float i=.5*float((u.x^u.y^u.z)&255)/1000.    
        + .5* .35* td * step(7.,time)
        + .5* .35* (q.z-time);
    glFragColor=vec4(i);
}