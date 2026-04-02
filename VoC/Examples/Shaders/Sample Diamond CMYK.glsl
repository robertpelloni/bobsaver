#version 420

// original https://www.shadertoy.com/view/flVSRz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI (3.14159265358979)
#define HEX(x) (vec3((ivec3(x) >> ivec3(16, 8, 0)) & 255)/255.)

#define SMOOTHNESS 0.02
vec3 getColor(float r) {
    r = fract(r);
    float mix0 = smoothstep(0.00, 0.00 + SMOOTHNESS, r);
    float mix1 = smoothstep(0.25, 0.25 + SMOOTHNESS, r);
    float mix2 = smoothstep(0.50, 0.50 + SMOOTHNESS, r);
    float mix3 = smoothstep(0.75, 0.75 + SMOOTHNESS, r);
    
    // works better with hex codes this way
    vec3 color0 = HEX(0x18C0FF);
    vec3 color1 = HEX(0xFF189C);
    vec3 color2 = HEX(0xFFD418);
    vec3 color3 = HEX(0x000000);
    
    return (
        color0 * (mix0 - mix1) +
        color1 * (mix1 - mix2) +
        color2 * (mix2 - mix3) +
        color3 * (mix3 - mix0 + 1.)
    );
}

float zigzag(float x) {
    return 1. - abs(1. - fract(x) * 2.);
}

#define SPOKES 8.
#define COLORSCALE 0.4
void main(void)
{
    float time = fract(time / 2.);
    // Scales coords so that the diagonals are all dist 1 from center
    float scale = length(resolution.xy);
    vec2 uv = (gl_FragCoord.xy / scale
    - (resolution.xy / scale / 2.)) * 2.;
    
    // for wormhole or perspective effect
    float r = log(length(uv)) + (1.0 + 0.02 * sin(time * 2. * PI));
    
    float theta = fract(atan(uv.y, uv.x) / (2. * PI));
    
    float val = fract(
      COLORSCALE * (
        zigzag(r + 2. * time + 0.3 *  sin(time * PI * 2.)) +
        zigzag(0.2 * r + SPOKES * theta + 1. * time)
      ) +
      -0.1 * r + time
    );
    
    vec3 col = getColor(val);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
