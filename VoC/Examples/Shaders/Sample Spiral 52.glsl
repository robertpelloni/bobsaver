#version 420

// original https://www.shadertoy.com/view/dddGWB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
@lsdlive
CC-BY-NC-SA

Spiral #6

Log-polar coordinates with a diagonal checker.
Inspired by the figure on the right:
https://en.wikipedia.org/wiki/Log-polar_coordinates#Discrete_geometry

*/

#define bpm 120.
#define speed .5
#define tiling 4.
#define line_sz .03

#define AA 4.

#define pi 3.14159265359
#define time (speed*(bpm/60.)*time)
//#define time (mod(speed*(bpm/60.)*time, 2.)) // 2s loop with default settings

// https://lospec.com/palette-list/1bit-monitor-glow
vec3 col1 = vec3(.133, .137, .137);
vec3 col2 = vec3(.941, .965, .941);

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;

    float aa_falloff = 12. * pow(1.3 - length(uv), 2.);
    
    float angle = atan(uv.y, uv.x) / (pi * .5);
    float len = log(length(uv));
    
    float t1 = fract(time * .25);
    uv = vec2(angle, len - t1);

    //vec2 flip = step(.5, fract(uv * tiling * .5)) * 2. - 1.;
    // FabriceNeyret2 suggestion:
    uv *= tiling;
    vec2 flip = sign(mod(uv, 2.) - 1.);
    uv = fract(uv);

    float t2 = fract(time * .5);
    /*if (uv.x > uv.y) {
        uv += flip.x * flip.y * t2;
    } else {
        uv -= flip.x * flip.y * t2;
    }*/
    // FabriceNeyret2 suggestion:
    uv += flip.x * flip.y * sign(uv.x - uv.y) * t2;

    uv = fract(uv + .5) - .5;
    uv = abs(uv);
    float mask = smoothstep(0., aa_falloff * AA / resolution.x, uv.y - uv.x - line_sz);
    vec3 col = mix(col1, col2, mask);

    glFragColor = vec4(col, 1.0);
}
