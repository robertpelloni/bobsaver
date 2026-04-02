#version 420

// original https://www.shadertoy.com/view/7tBBRD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TURN 6.283185
#define HEX(x) vec3((ivec3(x) >> ivec3(16, 8, 0)) & 255) / 255.

float slopestep(float x, float ratio) {
    return floor(x) + min(1.0, ratio * fract(x)) - x;
}

vec2 rotate(vec2 uv, float theta) {
    return vec2(
      uv.x * cos(theta) + uv.y * sin(theta),
      uv.y * cos(theta) - uv.x * sin(theta)
    );
}

float zigzag(float x) {
    return abs(1. - fract(x) * 2.);
}

vec3 palette(float x, float invert) {
    x = floor(mod(x, 4.));
    return (
        HEX(0xfff100) * max(0., 1. - abs(x - 0.)) +
        HEX(0x009BE8) * max(0., 1. - abs(x - 1.)) +
        HEX(0xEB0072) * max(0., 1. - abs(x - (2. + invert))) +
        HEX(0x000000) * max(0., 1. - abs(x - (3. - invert)))
    );
}

#define SCALE 2.0
#define HSCALE 1.2
#define LOOPLEN 9.
#define SCROLL_MAGN 8.
#define STEPS 8.
#define STEP_RATIO 4.0
#define STEP_MAGN 8.5
#define CARET_RATIO 0.6
#define CARET_STAGGER 0.25
#define ANGLE_BASE 0.25
#define ANGLE_SWAY 0.00

void main(void)
{
    float t = fract(time / LOOPLEN);
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / length(resolution.xy);
    uv = rotate(uv, TURN * (ANGLE_BASE + 2. * t + 0.5 * slopestep(t * 4., 8.0)) + ANGLE_SWAY * sin(TURN * t));
    uv *= SCALE * vec2(HSCALE, 1.);
    
    float aa_a = fwidth(uv.y) * 2.;
    float a = smoothstep(
        -aa_a, aa_a,
        zigzag(uv.y) - 0.5
    );
    float aa_b = fwidth(uv.x) * 4.;
    float b_0 = smoothstep(
        -aa_b, aa_b,
        zigzag(
            uv.x +
            CARET_RATIO * zigzag(0.5 + uv.y) +
            STEP_MAGN * slopestep(0.5 + t * STEPS, STEP_RATIO) / STEPS +
            SCROLL_MAGN * t
        ) - 0.5
    );
    float b_1 = smoothstep(
        -aa_b, aa_b,
        zigzag(
            uv.x + CARET_STAGGER +
            CARET_RATIO * zigzag(uv.y) +
            STEP_MAGN * slopestep(t * STEPS, STEP_RATIO) / STEPS +
            SCROLL_MAGN * t
        ) - 0.5
    );
    //float b = mix(b_0, b_1, a);
    //vec3 col = vec3(a, b, 0.);
        
        
        
    vec3 col = mix(
        mix(palette(t * 4.,      step(0.5, t)), palette(t * 4. + 1., step(0.5, t)), b_0),
        mix(palette(t * 4. + 2., step(0.5, t)), palette(t * 4. + 3., step(0.5, t)), b_1),
        a
    );

    // Output to screen
    glFragColor = vec4(col,1.0);
}
