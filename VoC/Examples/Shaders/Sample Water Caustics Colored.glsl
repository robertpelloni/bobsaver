#version 420

// original https://www.shadertoy.com/view/3slyzM

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// A simple, if a little square, water caustic effect.
// David Hoskins.
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Based on Dave_Hoskins
// https://www.shadertoy.com/view/MdKXDm

#define F length(.5-fract(k.xyw*=mat3(-2,-1,2, 3,-2,1, 1,2,2)*
#define C pow(min(min(F .4)),F .3))),F .2))), 7.)*25.
#define Q min(min(F .4)),F .3))),F .2)))

void main(void)
{
    vec2 p = gl_FragCoord.xy;
    vec4 k = glFragColor;

    float d= 5.;
    //k.xy = p*(sin(k=date*.5).w+2.)/2e2;
    //k.xy = p*(sin(k=date*.5).w+2.)/2e2;
    
    vec4 o = date;
    o.xy = p /2e2;
    
    k=date;
    k.xy = p / 100.;
    vec4 v = vec4(Q, Q, Q, 1);
    k = C * v +vec4(0,.35,.5,1);

    glFragColor = k;
}
