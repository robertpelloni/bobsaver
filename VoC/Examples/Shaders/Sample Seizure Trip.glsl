#version 420

// original https://www.shadertoy.com/view/tdsfDl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    // Time varying pixel color
    vec3 col = vec3(sin(gl_FragCoord.xy.x * (time + 0.0)), sin(gl_FragCoord.xy.x * (time + 0.1)), sin(gl_FragCoord.xy.x * (time + 0.2)));

    // Output to screen
    glFragColor = vec4(col,1.0);
}
