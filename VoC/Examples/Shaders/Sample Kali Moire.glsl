#version 420

// original by Kali
// https://www.shadertoy.com/view/XdXGzB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pos 6.
#define res 70.
#define spe 20.
void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy-.5;
    uv.x*=resolution.x/resolution.y;
    uv+=.5/res;
    float d=pow(10.,pos);
    vec2 g=uv*res;
    vec2 p=floor(g)/res*(1.+time/d*spe);
    vec2 f=fract(g)-.5;
    float l=length(p);
    float c=abs(floor(l*d)-floor(l*d/10.)*10.)*.1;
    c*=1.25-length(f)*1.5;
    glFragColor = vec4(c*c,c,c*c*c,1.)*(1.5-dot(uv,uv));
}
