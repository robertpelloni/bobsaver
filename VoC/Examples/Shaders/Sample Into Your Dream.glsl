#version 420

// original https://www.shadertoy.com/view/wsGBRt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 q = uv - vec2(0.5, 0.5);

    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));
    col *= 0.5 + 0.5 * cos(50.0 * 3.14 * pow(length(q), 0.15 + 0.1 * sin(time)) - 8.0 * time);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
