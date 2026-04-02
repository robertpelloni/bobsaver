#version 420

// original https://www.shadertoy.com/view/4slcRn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform vec4 date;

out vec4 glFragColor;

vec2 u;

//Created by pthextract + FabriceNeyret2 & Coyote in 2017-Feb-10 
#define d 9./length(u-length(u)*sin(vec2(0,1.57)+date.w/573.
void main(void)
{
    //core code
    vec2 u=gl_FragCoord.xy;
    u-=resolution.xy-gl_FragCoord.xy;
    glFragColor=vec4(d *60.)),d)),d /12.)),1);
}
