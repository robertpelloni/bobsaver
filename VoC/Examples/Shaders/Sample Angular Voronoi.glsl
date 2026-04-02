#version 420

// original https://www.shadertoy.com/view/ldjBzh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 u=gl_FragCoord.xy;
    u = u-resolution.xy*.5;
    u = vec2(abs(atan(u.x,u.y)),log(length(u)))*100.;
    #define l(i) length(fract(abs(u)*.01+fract(i*vec2(1,8))+cos(u.yx*fract(time*.01)*.2+i*8.))-.5)
    glFragColor += pow(min(l(.6),l(.1))*1.66,2.)-glFragColor;
}
