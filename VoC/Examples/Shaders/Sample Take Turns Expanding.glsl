#version 420

// original https://www.shadertoy.com/view/NlSfR1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// I don't call it "TAU" because it's actually just 2 pi
#define TURN 6.283185
// Converts a color hex code into vec3 representation
// e.g. if you want pure magenta, HEX(0xFF00FF) results in vec3(1., 0., 1.)
#define HEX(x) vec3((ivec3(x) >> ivec3(16, 8, 0)) & 255) / 255.

// Converts a saw wave [0, 1) into a triangle wave [0, 1].
// 0 -> 0, 0.5 -> 1, 1 -> 0
float zigzag(float x) {
    return 1. - (abs(1. - 2. * x));
}

// Smooth interpolation I used back when I did perlin noise stuff.
float fade(float t) {
    return t * t * t * (t * (t * 6. - 15.) + 10.);
}

// Smooth stepping effect. Used for the expanding parts of the rings.
// From 0.0 to FADE_THRES:
//   fade(x^2), where fade() is defined above, and
//   x is t / FADE_THRES (i.e. it goes from 0 to 1).
// From FADE_THRES to 1.0:
//   constant.

// default 0.65
#define FADE_THRES 0.65
float steppedFade(float t) {
    return mix(
        fade(t/FADE_THRES * t/FADE_THRES), 0.0,
        step(FADE_THRES, t)
    );
}

// Returns one of three predefined colors based on the fractional portion of x.
// It does some smoothing, but since it's used after the angle value is stepped,
// it results in jaggies here. I used this for making a .GIF file, so this was ideal anyway.
#define COLOR_SMOOTHING 0.25
vec3 colorize(float x) {
    float factor = fract(x) * 3.0;
    float f0 = smoothstep(0., COLOR_SMOOTHING, factor);
    float f1 = smoothstep(0., COLOR_SMOOTHING, factor - 1.);
    float f2 = smoothstep(0., COLOR_SMOOTHING, factor - 2.);
    return (
        HEX(0x009BE8) * (f0 - f1) +
        HEX(0xEB0072) * (f1 - f2) +
        HEX(0xfff100) * (f2 - f0 + 1.)
    );
}

// The "zoom level" of the entire thing. Smaller is more spaced out.
// default 1.5
#define SCALE 1.5
// The number of slices in the circle. Should be a multiple of 3,
// or else the left edge will have the wrong color
// default 30.
#define SLICES (10. * 3.)

void main(void)
{
    // time loops every 2.0 seconds
    float t = fract(time / 2.0);
    
    // Normalized pixel coordinates (0 at center, 1 at edges)
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy);
    
    // convert to log-polar coordinates,
    // the angle in (-0.5, 0.5]
    vec2 rt = vec2(
        log(length(uv)) * SCALE,
        atan(uv.y, uv.x) / TURN
    );
    
    // find the closest angle slice
    float angleStep = floor(rt.y * SLICES - 0.5);
    
    // get the time offset for the current angle slice
    float fadeFactor = steppedFade(
        fract(-t - angleStep / SLICES)
    );
    
    // get the brightness of the current angle slice,
    // based on the time offset, distance, and time
    float stripeLevel = zigzag(
        fract(
            3. * fadeFactor
            + rt.x + 1. * t
        )
    );
    
    // threshold without antialias
    stripeLevel = step(0.5, stripeLevel);
    // buggy antialiased threshold (comment out line above to test)
//    stripeLevel = smoothstep(0.5 - fwidth(stripeLevel), 0.5 + fwidth(stripeLevel), stripeLevel);
    
    // get the color of the current slice, or pure black if stripeLevel is 0
    vec3 sliceColor = colorize(angleStep / 3.0) * stripeLevel;
    
    // radar-like bright ray (commented out by default)
//    sliceColor = sliceColor * (1. + 0.15 * fadeFactor) + 0.25 * max(0.0, 1.0 - 3.0 * (1.0 - fadeFactor));

    // Output to screen
    glFragColor = vec4(sliceColor, 1.0);
}
