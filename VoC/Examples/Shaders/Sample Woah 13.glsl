#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {
    vec2 p = gl_FragCoord.xy - resolution.xy * 0.5;
    float t = time + length(p / 8.0) / 3700. * time *mouse.x*mouse.y/100.;
    vec2 rot = vec2(cos(t) * p.x - sin(t) * p.y,
             cos(t) * p.y + sin(t) * p.x) / 0.2*cos(t*3.0)/250.0;
    if (fract(rot.x) > .5 ^^ fract(rot.y) > .5) {
    glFragColor = vec4(1.0);
    } else {
    glFragColor = vec4(sin(time),cos(time / 2.0),cos(time),0.0);
    }
}
