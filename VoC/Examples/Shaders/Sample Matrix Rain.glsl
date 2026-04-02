#version 420

// original https://www.shadertoy.com/view/XlGBzV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R fract(23.*sin(p.x*7.+p.y*8.))

void main(void) {
    vec2 i = gl_FragCoord.xy;
    vec4 o = glFragColor;
    vec2 j = fract(i*=.21), 
         p = vec2(92,int(time*(7.+8.*sin(i-=j).x)))+i;
    o-=o; o.g=R; p*=j; o*=R>.5&&j.x<.6&&j.y<.8?1.:0.;
    glFragColor = o;
}
