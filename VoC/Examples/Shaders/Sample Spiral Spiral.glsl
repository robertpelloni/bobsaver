#version 420

// original https://www.shadertoy.com/view/Nd3SDH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU (6.283185307)
#define SCALE_ANGLE 12.
#define SCALE_DIST 1.
#define TILE_X 0.
#define TILE_Y 1.
#define HEX(x) (vec3((x >> 16) & 255, (x >> 8) & 255, x & 255) / 255.)

float spiral(float x) {
    return step( 0.5, 1. - abs(1. - 2. * fract(x)));
}

vec3 colorize(float x) {
    return mix(
        HEX(0xc02030),
        mix(
            HEX(0xffd010),
            mix(
                HEX(0x30a040),
                HEX(0x2060a0),
                step(0.75, x)
            ),
            step(0.5, x)
        ),
        step(0.25, x)
    );
}

vec2 rotate(vec2 uv, float rotateBy) {
    return vec2(
        uv.x * cos(rotateBy) + uv.y * sin(rotateBy),
        -uv.x * sin(rotateBy) + uv.y * cos(rotateBy)
    );
}

void main(void)
{
    // Make sure this loops
    float time = fract(time / 2.0);
    // Normalized pixel coordinates
    vec2 uv = ( 2.* gl_FragCoord.xy - resolution.xy ) / length(resolution.xy);
    // use log distance for perspective/tunnel effect
    float dist = log(uv.x * uv.x + uv.y * uv.y);
    float angle = atan(uv.y, uv.x) / TAU;
    
    // arrow texture
    float distS = dist * SCALE_DIST + 0.1 * cos(time * TAU);
    float distSign = sign(mod(distS, 2.) - 1.);
    vec2 uv_ = fract(vec2(
        distS,
        angle * SCALE_ANGLE + time * 3. * distSign
    )) - 0.5;
    
    float smallDist = log(uv_.x*uv_.x+uv_.y*uv_.y);
    float smallSpirals = spiral(
        time * 3. * distSign +
        smallDist * 0.5 +
        (atan(uv_.y, uv_.x) / TAU) * -1.
    );
    
    // spiral
    float spiral = fract(
        time * 1. +
        cos(-time * TAU + 1.1) * 0.02 +
        dist * 0.2 +
        angle * 1.
    );
    
    // blend
    vec3 col = colorize(spiral) * (0.5 + 0.8 * smallSpirals);
    col *= step(smallDist, -1.5);
    
    // Output to screen
    glFragColor = vec4(
        col, 1.0
    );
}
