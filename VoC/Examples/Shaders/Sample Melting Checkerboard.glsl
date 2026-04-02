#version 420

// original https://www.shadertoy.com/view/wlG3WR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    // Time varying pixel color
    float h = sin(50.0 * uv.x + 20.0 * sin(12.0 * uv.x + time));

    
    float jiggle = smoothstep(-0.1, 0.1, sin(80.0 * uv.y));
    h = mix(h, - h, jiggle);
    vec3 col = mix(vec3(0.8, 0.0, 0.0), vec3(0.0), smoothstep(-0.1, 0.1, h));
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
