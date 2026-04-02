#version 420

// original https://www.shadertoy.com/view/WsBcWV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Alex Kluchikov

vec2 rot(vec2 p,float a)
{
    float c=cos(a*11.83);
    float s=sin(a*11.83);
    return p*mat2(s,c,c,-s);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy;
    uv/=resolution.xy;
    uv=.5+(uv-.5)*.05;
    float T=time*.15;

    vec3 c = clamp(1.-.7*vec3(
        length(uv-vec2(.1,0)),
        length(uv-vec2(.9,0)),
        length(uv-vec2(.5,1))
        ),0.,1.)*2.-1.;

    vec3 c0=vec3(0);
    float w0=0.;
    for(float i=0.;i<12.;i++)
    {
        float wt=0.1+i*0.1;
        float wp=0.5+(i+2.)*(i+5.)*0.005;
        c.zx=rot(c.zx,1.6+T*0.65*wt+(uv.x+.7)*23.*wp);
        c.xy=rot(c.xy,1.7+T*wt+(uv.y+1.1)*15.*wp);
        c.yz=rot(c.yz,2.4-T*0.79*wt+(uv.x+uv.y*(fract(i/2.)-0.25)*4.)*17.*wp);
        float w=(1.15-i/17.);
        c0+=c*w;
        w0+=w;
    }
    c0=c0/w0*(1.-pow(uv.y-.5,2.)*2.)*2.+.5;
    
    glFragColor=vec4(c0,1.0);
}
