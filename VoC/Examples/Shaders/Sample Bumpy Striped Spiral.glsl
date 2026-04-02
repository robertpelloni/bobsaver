#version 420

// original https://www.shadertoy.com/view/7sc3Wr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI (3.14159265358979)
#define STRIPECOUNT 6.0
#define DENSITY 0.5

vec3 getColor(float r) {
    r = fract(r);
    float mix0 = smoothstep(0.00, 0.01, r);
    float mix1 = smoothstep(0.25, 0.26, r);
    float mix2 = smoothstep(0.50, 0.51, r);
    float mix3 = smoothstep(0.75, 0.76, r);
    
    vec3 color0 = vec3(1.0, 0.2, 0.2);
    vec3 color1 = vec3(1.0, 0.8, 0.2);
    vec3 color2 = vec3(0.1, 0.8, 0.3);
    vec3 color3 = vec3(0.0, 0.3, 0.9);
    
    return (
        color0 * (mix0 - mix1) +
        color1 * (mix1 - mix2) +
        color2 * (mix2 - mix3) +
        color3 * (mix3 - mix0 + 1.)
    );
}

void main(void)
{
    float time = fract(time / 6.);
    // Scales coords so that the diagonals are all dist 1 from center
    float scale = length(resolution.xy);
    vec2 uv = (gl_FragCoord.xy / scale
    - (resolution.xy / scale / 2.)) * 2.;
    
    // for wormhole or perspective effect
    float r = log(length(uv)) + (1.0 + 0.2 * sin(time * 2. * PI));
    
    
    // if you want the angle in range [0, 1) and not (-π, π]
    // divide angle by 2pi and mod1 it
    float theta = fract(atan(uv.y, uv.x) / 6.2831853071795);
    
    float ofs = floor((-time + 0.5 * r + theta) * STRIPECOUNT) / STRIPECOUNT;
    float rings = r * DENSITY;

    // Time varying pixel color
    vec3 col = getColor(ofs + rings);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
