#version 420

// original https://www.shadertoy.com/view/7dG3RW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float fold(float x) {
    return 2.0 * abs(0.5 - fract(x));
}

void main(void)
{
    float time = fract(time / 2.);
    // Scales coords so that the diagonals are all dist 1 from center
    float scale = length(resolution.xy);
    vec2 uv = (gl_FragCoord.xy / scale
    - (resolution.xy / scale / 2.)) * 15.;
    
    // diagonal grid
    vec2 slantUV = vec2(uv.x + uv.y, uv.x - uv.y);
    vec2 slantRnd = floor(slantUV);
    slantUV = fract(slantUV + 0.5) - 0.5;
    
    // spiral
    float r = length(slantRnd);
    float angle = atan(slantRnd.y, slantRnd.x) / 2.0 / 3.14159265358979;
    float spiral = fold(r * 0.15 + angle + time - cos(time * 3.1415927));

    float thres = 
        min(abs(slantUV.x), abs(slantUV.y));
        float zig = step(1., 1.5 * fract(time * 1. + abs(floor(0.25 + slantRnd.y - slantRnd.x)) / 6.));

    vec3 col = mix(
        mix(vec3(0.3, 0.1, 0.1), vec3(0.5, 0.2, 0.0), zig),
        mix(vec3(0.1, 0.5, 0.8), vec3(0.0, 0.8, 1.0), zig),
        
        smoothstep(
            0.7, 0.8,
            spiral + thres
        )
    );

    // Output to screen
    glFragColor = vec4(col,1.0);
}
