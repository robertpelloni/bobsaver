#version 420

// original https://www.shadertoy.com/view/3syBDc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Engage Warp by Logan Apple (Twitter: @loganapple540)
// https://www.shadertoy.com/view/3syBDc
// MIT License

#define TIME_DELAY 0.1
#define DISPLACEMENT 0.5

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy / resolution.xy - DISPLACEMENT;

    // Pixel color
    vec3 col;
    
    // Length of normalized and translated frag coord
    float len;
    for (int i = 0; i < 3; ++i) {
        len = length(uv);
        uv *= 1.0 + 2.0 / len * (cos(time) + 1.0) * abs(cos(0.5 * len - time));
        len *= mix(1.0, TIME_DELAY * sin(time * len), cos(time));
        
        col = vec3(
            i == 0 ? 0.1 / length(mod(uv, 1.0) - DISPLACEMENT) : col.r, 
            i == 1 ? 0.1 / length(mod(uv, 1.0) - DISPLACEMENT) : col.g, 
            i == 2 ? 0.1 / length(mod(uv, 1.0) - DISPLACEMENT) : col.b);
    }

    // Output to screen
    glFragColor = vec4(col, 1.0);
}
