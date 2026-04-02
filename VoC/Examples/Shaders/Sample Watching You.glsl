#version 420

// original https://www.shadertoy.com/view/wsVXzD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Best viewed full screen

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    float t = sin(time * .075) * 10.0;
    vec2 uv = gl_FragCoord.xy/resolution.xy * 2.0 - 1.0;
    uv.x = sin(uv.x * t) + cos(uv.y * t);
    uv.y = sin(uv.y * t) + cos(uv.x * t);
    
    // Variation
    uv.x = sin(uv.x * t) + cos(uv.y * t);
    
    // Output to screen
    glFragColor = vec4(sin(uv.x * uv.y));
}
