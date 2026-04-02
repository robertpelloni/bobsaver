#version 420

// original https://www.shadertoy.com/view/ddtGz8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// set to 0 to make colors buttery-smooth
// set to 1 to dither colors (for GIF export)
#define DITHER 1

// generate an ordered dithered pattern based on pixel coordinates
#if DITHER == 1
float crosshatch(vec2 xyf) {
    ivec2 xy = ivec2(xyf) & 3;
    return (float(
        + ((xy.y >> 1) & 1)
        + ((xy.x & 2) ^ (xy.y & 2))
        + ((xy.y & 1) << 2)
        + ((((xy.x) & 1) ^ (xy.y & 1)) << 3)
    ) + 0.5) / 16.;
}
#endif

const float TURN = acos(-1.) * 2.;
// rotation matrix
#define ROT(x) mat2x2(cos(TURN * (x + vec4(0, 0.25, -0.25, 0))))
// converts colors from hex code to vec3
#define HEX(x) vec3((ivec3(x) >> ivec3(16, 8, 0)) & 255) / 255.
// “zigzag” value between 0 and 1
#define ZIG(x) (1. - abs(1. - fract(x) * 2.))

// convert float in range [0, 1) to a color based on a colormap
vec3 colormap(float x){
    const int colorCount = 16;
    vec3[] c = vec3[](
        HEX(0xfaf875),
        HEX(0xfcfc26),
        HEX(0xbcde26),
        HEX(0x5CC863),
        
        HEX(0x1FA088),
        HEX(0x33638D),
        HEX(0x3D4285),
        HEX(0x1F0269),
        
        HEX(0x25024D),
        HEX(0x430787),
        HEX(0x6F00A8),
        HEX(0x9814A0),
        
        HEX(0xC23C81),
        HEX(0xF07F4F),
        HEX(0xFDB22F),
        HEX(0xFAEB20)
    );
    x *= float(colorCount);
    int lo = int(floor(x));
    
    return mix(
        c[lo],
        c[(lo + 1) % colorCount],
        fract(x)
        //smoothstep(0.0, 1., fract(x))
    );
}

/*
// spectrum for testing
vec3 spec(float x) {
    x *= 3.;
    return vec3(
        smoothstep(0., 0.5, x) - smoothstep(1.5, 2., x),
        smoothstep(1., 1.5, x) - smoothstep(2.5, 3., x),
        smoothstep(2., 2.5, x) + smoothstep(1., 0.5, x)
    );
}
*/

// generate the color based on
// the 2D vector, dithering threshold, and time
vec3 c(vec2 ab, float thres, float t) {
    float x = fract(atan(ab.x, ab.y) / TURN);
    // time offset
    x = fract(((
        1. + 6. * ZIG(x) + 8. * (
            smoothstep(0.0,0.25,t)+
            smoothstep(0.5,0.75,t)
        )) / 16.)
    );
#if DITHER == 1
    const float STEPS = 16.;
    x = fract((
        floor(x * STEPS) +
        step(thres, fract(x * STEPS))
    ) / STEPS);
#endif
    return colormap(x);
}

void main(void)
{
    float t = fract(time / 4.);
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    float r = log(length(uv));
    float theta = atan(uv.y, uv.x) / TURN;

    // calculate temporary “colors” as 2D vectors
    // then use its angle from center to map to a colormap
    
    // first calculate the angle from the center
    float z = (
        -0.4 * r +
        0.8 * sin(
            1.5 * r +
            1. * t * TURN
        ) +
        5. * theta +
        1. * t
    ) * TURN;
    
    // double pendulum kinda thing
    // go 0.45 to the right, rotate a 0.4 unit arm by z
    // then rotate the whole thing
    vec2 ab = vec2(
        0.45 + 0.4 * cos(z),
        0.0 + 0.4 * sin(z)
    ) * ROT(
        0.9 * r + 
        -1. * theta +
        -1. * t
    );
    
#if DITHER == 1
    float thres = crosshatch(gl_FragCoord.xy);
#else
    float thres = -1.;
#endif
    vec3 col = c(ab, thres, fract(t + 0.45));

    // Output to screen
    glFragColor = vec4(col,1.0);
}
