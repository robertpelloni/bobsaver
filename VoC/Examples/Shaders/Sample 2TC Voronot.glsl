#version 420

// original https://www.shadertoy.com/view/4tXGW4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {
    
    vec2  p = gl_FragCoord.xy - resolution*.5;
    float d = length(p) / resolution.y, C=1.;
    vec2  c = vec2(pow(d, .1), atan(p.x, p.y) / 6.28);
    
    for (float i = 0.; i < 3.; ++i)    
        C = min(C, length(fract(vec2(c.x - time*i*.005, fract(c.y + i*.125)*.5)*20.)*2.-1.));

    glFragColor = vec4(d+20.*C*d*d*(.6-d));
}
