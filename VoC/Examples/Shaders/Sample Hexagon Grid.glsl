#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/ssVGRy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// square root of 3 because hexagon stuff
#define SQRT3 (1.7320508)
// converts rgb hex code to a vec3
#define HEX(x) (vec3((x >> 16) & 255, (x >> 8) & 255, x & 255) / 255.)
// calculate the distance from the center of a hexagon
float hex(vec2 uv) {
    // loop around to tile
    uv = abs(
        mod(
            uv + vec2(1.0, SQRT3),
            vec2(2., SQRT3 * 2.)
        ) - vec2(1.0, SQRT3)
    );
    // vector from the center to the midpoint of the top right side
    const vec2 s = vec2(1, SQRT3) * 0.5;
    // return whichever is closer:
    // distance towards the top right side,
    // or distance towards the right side
    // (i.e. absolute value of x coordinate)
    return max(
        dot(uv, s),
        uv.x
    );
}

// map the range [0, 1) to stripes of colors
#define COLOR_COUNT 4
// uniforms can't be declared inside a function
// so sadly it is out here
const vec3 color[COLOR_COUNT] = vec3[](
    HEX(0x000000),
    HEX(0x300060),
    HEX(0x8000C0),
    HEX(0xFF66FF)
);
const float thres[COLOR_COUNT] = float[](
    0.0, // ignored
    0.4,
    0.7,
    0.9
);
vec3 colorize(float value) {
    value = fract(value);
    vec3 color_out = color[0];
    for (int i = 1; i < COLOR_COUNT; i++) {
        if (value > thres[i]) {
            color_out = color[i];
        } else {
            return color_out;
        }
    }
    return color_out;
}

void main(void)
{
    float time = fract(time / 2.);
    // Scales coords so that the diagonals are all dist 1 from center
    float scale = length(resolution.xy);
    vec2 uv = (gl_FragCoord.xy / scale
    - (resolution.xy / scale / 2.)) * 8.;
    
    float dist = 
        min(
            // grid with a hexagon centered at the screen
            hex(uv),
            // grid with 4 hexagons surrounding the center
            hex(uv + vec2(1.0, SQRT3))
        );
    vec3 col = colorize(
        dist * dist - time
    );

    // Output to screen
    glFragColor = vec4(col,1.0);
}
