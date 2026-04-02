#version 420

// original https://www.shadertoy.com/view/dlXczN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// For GIF export: enable dither to reduce color count te 8
#define DITHER 0
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

const float PI_2 = acos(-1.) * .5;
#define ZIG(x) (1. - abs(1. - 2. * fract(x)))
#define ROT(x) mat2x2(cos(x + PI_2 * vec4(0, 1, -1, 0)))
#define HEX(x) vec3((ivec3(x) >> ivec3(16, 8, 0)) & 255) / 255.

float depthFunc( float depth ) {
    return smoothstep(
        0., 1., min(depth, 3. - depth)
    );
}

vec3 colormap(vec3 rgb) {
    const vec3 c000 = HEX(0x010a31);
    const vec3 c001 = HEX(0x000068);
    const vec3 c011 = HEX(0x009be8);
    const vec3 c010 = HEX(0x20a220);
    const vec3 c110 = HEX(0xfff100);
    const vec3 c100 = HEX(0xcb1018);
    const vec3 c101 = HEX(0xeb0072);
    const vec3 c111 = HEX(0xffffff);
    
    vec3 c00x = mix(c000, c001, rgb.b);
    vec3 c01x = mix(c010, c011, rgb.b);
    vec3 c10x = mix(c100, c101, rgb.b);
    vec3 c11x = mix(c110, c111, rgb.b);
    
    vec3 c0xx = mix(c00x, c01x, rgb.g);
    vec3 c1xx = mix(c10x, c11x, rgb.g);
    
    return mix(c0xx, c1xx, rgb.r);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / length(resolution.xy);

    float t = fract(time / 8.);
    
    // zoom level per layer
    const float LEVEL = 6.;
    
    uv *= exp2(10. - t * LEVEL);
    
    // Time varying pixel color
    vec4 cmyk = vec4(0);
    
    const mat2x2[] rots = mat2x2[](
        ROT(1. / 6. * PI_2),
        ROT(-1./ 6. * PI_2),
        ROT(0.),
        ROT(1. / 2. * PI_2)
    );
    
    for (int channel = 0; channel < 4; channel++) {
        for (float depth = 0.; depth < 3.; depth++) {
            vec2 thisUV = uv * rots[channel] * exp2(-depth * LEVEL);
            cmyk[channel] += smoothstep(
                0.7, 0.75,
                length(ZIG(thisUV))
            ) * depthFunc(depth + t);
        }
    }
    vec3 col = cmyk.xyz * cmyk.w;
#if DITHER == 1
    float thres = crosshatch(gl_FragCoord.xy);
    const float STEPS = 1.;
    col = (
        floor(col * STEPS) +
        step(vec3(thres), fract(col * STEPS))
    ) / STEPS;
#endif
    col = colormap(col);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
