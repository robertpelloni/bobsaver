#version 420

// original https://www.shadertoy.com/view/wllcDH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) //WARNING - variables void () need changing to glFragColor and gl_FragCoord.xy
{
    vec4 o;
    vec2 u=vec2(2.*gl_FragCoord.xy-resolution.xy)/resolution.y*4.;
    for(float i=1.;i<4.;i++)
        u.x+=cos(u.y*i*3.)*.1,
        u.xy+=sin(u.x*u.x+u.y*u.y-time*7.),
        u+=cos(u*5.)*.1,
        o=cos(float(u*.4)+vec4(.2,.1,.1,0));
    glFragColor=o;
}
