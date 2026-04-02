#version 420

// original https://www.shadertoy.com/view/3lVXWh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 xy = (2.0*gl_FragCoord.xy - resolution.xy)/resolution.y;

    vec3 col = 0.5 + 0.5*cos(time +
                             xy.x*vec3(4.0, -2.0, -2.0) +
                             xy.y*vec3(0.0, sqrt(12.0), -sqrt(12.0)));
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
