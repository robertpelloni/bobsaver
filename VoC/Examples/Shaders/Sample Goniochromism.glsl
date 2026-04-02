#version 420

// original https://www.shadertoy.com/view/wlj3Dc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Alex Kluchikov

vec2 rot(vec2 p,float a)
{
    float c=cos(a*1.3);
    float s=sin(a*1.3);
    return p*mat2(s,c,c,-s);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy;

    uv/=resolution.xy;

    vec3 c = clamp(1.-.7*vec3(
        length(uv-vec2(.1,0)),
        length(uv-vec2(.9,0)),
        length(uv-vec2(.5,1))
        ),0.,1.)*2.-1.;

    for(float i=0.;i<11.;i++)
    {
        float wt=0.1+i*0.1;
        float wp=0.5+i*i*0.005;
        c.zx=rot(c.zx,time*0.65*wt+uv.x*23.*wp);
        c.xy=rot(c.xy,.7+time*wt+uv.y*15.*wp);
        c.yz=rot(c.yz,.4-time*0.79*wt+(uv.x+uv.y*(fract(i/2.)-0.25)*4.)*17.*wp);
    }
    c=mix(vec3(.9,.95,1),vec3(.2,.3,.7),sqrt(dot(c,c)))*(1.-c*.5);
    
    glFragColor=vec4(c,1.0);
}
