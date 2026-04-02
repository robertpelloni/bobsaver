#version 420

// original https://www.shadertoy.com/view/3slczX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    float ramp1 = length(uv - vec2(0.25, 0.5));
    float ramp2 = length(uv - vec2(0.75, 0.5));
    float period = 100.0;
    
    float wave1 = 0.5 + 0.5 * cos(ramp1 * period - 10.0*time);
    float wave2 = 0.5 + 0.5 * cos(ramp2 * period - 10.0*time);
    
    vec3 base = vec3(0, 1, 1);

    // Time varying pixel color
    vec3 col = base * (wave1 + wave2) / 2.0;

    // Output to screen
    glFragColor = vec4(col,1.0);
}
