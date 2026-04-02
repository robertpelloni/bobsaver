#version 420

// original https://www.shadertoy.com/view/NllXD8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//mod by LSC

// Space Gif by Martijn Steinrucken aka BigWings - 2019
// Email:countfrolic@gmail.com Twitter:@The_ArtOfCode
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Original idea from:
// https://boingboing.net/2018/12/20/bend-your-spacetime-continuum.html
//
// To see how this was done, check out this tutorial:
// https://youtu.be/cQXAbndD5CQ
//

void main(void)
{

    vec2 uv = (gl_FragCoord.xy-resolution.xy*.5)/resolution.y;
    float a=time*.5;
    float s=sin(a);
    float c=cos(a);
    uv *= mat2(c, -s, s, c);
    
    float zoomer=sin(time*0.25)*15.+15.;
    uv *= zoomer;
    
    vec2 gv = fract(uv)-.5; 
    vec2 id = floor(uv);
    
    float m = 0.;
    float t;
    for(float y=-1.; y<=1.; y++) {
        for(float x=-1.; x<=1.; x++) {
            vec2 offs = vec2(x, y);
            
            t = -time+length(id-offs)*.2;
            float r = mix(.4, 1.5, sin(t)*.5+.5);
            float c = smoothstep(r, r*.9, length(gv+offs));
            m = m*(1.-c) + c*(1.-m);
        }
    }

    glFragColor = vec4(m);
}
