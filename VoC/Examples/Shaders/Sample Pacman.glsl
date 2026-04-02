#version 420

// original https://www.shadertoy.com/view/MdsyWr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) //WARNING - variables void ( out vec4 c, in vec2 f ) need changing to glFragColor and gl_FragCoord
{
    vec2 f=gl_FragCoord.xy;
    f /= resolution.xx; f.y -= .281; // make pixels square
    
    vec2 p = f - vec2(mod(time / 2., 1.4) - .2, 0.); // move origin
    
    glFragColor = vec4(
        length (p) < .16 // body
        &&
        length (p - vec2(0., .08)) > .02 // eye
        &&
        abs(atan(p.y, p.x)) > abs(cos(time * 10.)) * .8 // jaw
        ||
        length(vec2(mod(f.x, .125) - .062, f.y)) < .018 // dots
        && p.x > 0. // not eaten
        ?
        1. : 0.); // paint
    
    glFragColor.b = .2; // color correction
}
