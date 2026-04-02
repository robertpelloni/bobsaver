#version 420

// original https://www.shadertoy.com/view/wdtSzr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* This shader is an experiment inspired by Edna Andrade's
   artwork Yellow Bounce:

https://woodmereartmuseum.org/explore-online/collection/yellow-bounce

It's still in development and needs some additional tweaking
(for instance, the diagonal lines are not anti-aliased properly yet).

*/

#define PI 3.14159

void main(void)
{
    vec2 uv = 9.*gl_FragCoord.xy/resolution.xy;
    uv.x /= resolution.y/resolution.x;
    uv = fract(uv);    
    uv.xy -= vec2(.5);
    float f1 = (floor((gl_FragCoord.x/(resolution.x/16.)))-8.)/8.;
    float f2 = (floor((gl_FragCoord.y/(resolution.y/9.)))-4.5)/4.5;

    float f3 = atan(f2,f1);

    float ax = (PI*max(abs(f1),abs(f2)))+PI*cos(time+f3);

    uv = mat2(cos(ax),-sin(ax),sin(ax),cos(ax))*uv;

    float d = length(uv.xy);
    float a = atan(uv.y,uv.x);
    
    vec3 col = vec3(.5);
    col -= vec3((1.-smoothstep(.3,.31,d))*(1.-smoothstep(.495,.505,(a+PI)/(2.*PI))));
    col += vec3((1.-smoothstep(.3,.31,d))*(1.-smoothstep(.505,.495,(a+PI)/(2.*PI))));

    glFragColor = vec4(col,1.0);
}
