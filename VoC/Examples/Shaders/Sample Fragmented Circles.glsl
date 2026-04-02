#version 420

// original https://www.shadertoy.com/view/wttXWn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// https://creativecommons.org/licenses/by-sa/4.0/
// by Denis H.

#define DIV 30.
#define MAX_CIRCLES 4.

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    float a = sin(time / 10.);
    vec2 id = floor(uv * DIV) + .25;
    vec2 gv = fract(uv * DIV) - .5 - sin(id + .01 * time) * .5;
    
    float gdist = length(id);
    float dist = length(gv) - sin(a * gdist) * gdist * .05;
    dist *= a * a * MAX_CIRCLES;
    dist = fract(dist);
    
    float mask = smoothstep(.2, .199, dist);
    vec3 col = vec3(mask);

    col *= 1. - length(uv);
    col.r *= fract(sin(id.x)*219.38 * sin(id.y)*419.38);
    col.g *= fract(sin(id.x)*129.43 * sin(id.y)*829.43) * .7;
    col.b *= fract(sin(id.x)*519.12 * sin(id.y)*599.12) * .5;

    glFragColor = vec4(col,1.0);
}
