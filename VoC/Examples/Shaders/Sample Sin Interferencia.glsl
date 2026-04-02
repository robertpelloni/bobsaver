#version 420

// original https://www.shadertoy.com/view/WlKGzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.x;
    vec2 center = resolution.xy / resolution.x * 0.5;
    float amplitude = 100.0;
    
    // Fade to black and white
    float p = cos(time - distance(uv, center));
    p -= sin(time * 0.5 - distance(uv, center));
    
    // Left waves
    p += sin(time - distance(uv, vec2(center.x - 0.25, center.y + 0.25)) * amplitude);
    p += sin(time - distance(uv, vec2(center - 0.25)) * amplitude);
    
    // Right waves
    p += sin(time - distance(uv, vec2(center + 0.25)) * amplitude);
    p += sin(time - distance(uv, vec2(center.x + 0.25, center.y - 0.25)) * amplitude);
    
    // Output to screen
    glFragColor = vec4(vec3(p), 1.0);
}
