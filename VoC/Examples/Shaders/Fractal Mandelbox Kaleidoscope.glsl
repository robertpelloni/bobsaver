#version 420

// original https://www.shadertoy.com/view/XdVGzt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 boxFold(vec2 v)
{
    v.x = v.x > 1. ? 2.-v.x : v.x < -1. ? v.x = -2.-v.x : v.x;
    v.y = v.y > 1. ? 2.-v.y : v.y < -1. ? v.y = -2.-v.y : v.y;
    return v;
}
vec2 ballFold(float r, vec2 box)
{
    float m = length(box);
    //m<r ? m /= r*r : m<1. ? m = 1./m : m = m;
    if (m<r) {
        m /= r*r;
    } else {
        if (m<1) {
            m=1/m;
        } else {
            m=m;
        }
    }
    return m*box;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = 2.-4.*uv;
    //uv *= 5.;
    vec2 v = vec2(0.);
    float s=sin(time*.5)+5.*sin(.1*time),r=cos(time*.1)*.5+.5,f=1.;
    float trap = 0.;
    float dist=0.;
    vec4 col = vec4(1.);
    
    for(int i = 0; i < 512; i++){
        if(dot(v,v)>100.*cos(time*.5)+100.){trap = float(i);break;}
        dist = min( 1e20, dot(v,v))+cos(float(i)*12.005+.001*time);
        v = s*ballFold(r, f*boxFold(v)) + uv;
    }
    dist = sqrt(dist);
    float orb = sqrt(float(trap))/64.;
    glFragColor=vec4(sin(dist+.001*time)*.5+.5,cos(dist+.1*time)*.5+.5,tan(dist*orb)*.5+.5,1.);
}
