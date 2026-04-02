#version 420

// original https://www.shadertoy.com/view/XsV3RD

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

// Created by Stephane Cuillerdier - @Aiekick/2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

void main(void)
{
    vec4 f = glFragColor;
    vec2 g = gl_FragCoord.xy;

    float 
        t = date.w,
        p;
    
    vec2 
        s = resolution.xy,
        u = (g+g-s)/s.y,
        ar = vec2(
            atan(u.x, u.y) * 3.18 + t*2., 
            length(u)*3. + sin(t*.5)*10.);
    
    p = floor(ar.y)/5.;
    
    ar = abs(fract(ar)-.5);
    
    f = 
        mix(
            vec4(1,.3,0,1), 
            vec4(.3,.2,.5,1), 
            vec4(p)) 
        * .1/dot(ar,ar) * .1 
        + texture2D(backbuffer, g / s) * .9;

    glFragColor=f;
}
