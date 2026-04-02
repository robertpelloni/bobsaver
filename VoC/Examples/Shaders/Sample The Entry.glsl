#version 420

// original https://www.shadertoy.com/view/dlVGzh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    "Entry" by @XorDev
    
    Tweet: https://twitter.com/XorDev/status/1655584557502984192

    <300 chars playlist: shadertoy.com/playlist/fXlGDN
    
    -2 thanks to SnoopethDuckDuck
    -21 thanks to coyote
*/
void main(void) //WARNING - variables void (out vec4 o, vec2 I) need changing to glFragColor and gl_FragCoord.xy
{
    vec2 I = gl_FragCoord.xy;
    I+=I-resolution.xy;
    I*=mat2(cos(round(atan(I.y,I.x)*.95)/.955+vec4(0,11,33,0)));
    vec4 o=cos(mod(ceil(I.y/.3/I)+ceil(I=log(I)/.5-time),4.).x+vec4(6,5,2,0))+1.;
    o/=2.+max(I=fract(I)-.3,-I-I).x/.4;
    glFragColor=o;
}