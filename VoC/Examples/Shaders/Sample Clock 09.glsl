#version 420

// original https://www.shadertoy.com/view/XddSRN

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define N 1e-3 / (1.-cos(atan(i.x,i.y) 
void main(void) //WARNING - variables void (out vec4 o,vec2 i) need changing to glFragColor and gl_FragCoord
{
    vec2 i=gl_FragCoord.xy;
    i+=i-resolution.xy;
    glFragColor=N-date.w/vec4(6875,573,9.55,1)))+N*12.));
}
