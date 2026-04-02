#version 420

// original https://www.shadertoy.com/view/ltsGD4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// [2TC 15] Hologram
// 133 chars (without white space and comments)
// by Andrew Baldwin.
// This work is licensed under a Creative Commons Attribution 4.0 International License.

void main()
{
    vec4 c = gl_FragCoord,d=c*.0,e;
    for (int i=9;i>0;i--) {
        e=floor(c);
        d+=(sin(e*e.yxyx+sin(e+time)));
           c*=.5;
    }
    glFragColor = d/9.;
}
