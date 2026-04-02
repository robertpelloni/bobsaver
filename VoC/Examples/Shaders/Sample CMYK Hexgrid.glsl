#version 420

// original https://www.shadertoy.com/view/NlBfDR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// square root of 3 because hexagon stuff
#define SQRT3 (1.7320508)
// two pi for rotation stuff
#define TAU (6.283185307)
// converts rgb hex code to a vec3
#define HEX(x) (vec3((x >> 16) & 255, (x >> 8) & 255, x & 255) / 255.)
// calculate the distance from the center of a hexagon
float hex(vec2 uv) {
    const vec2 tileSize = vec2(1.0, SQRT3);
    vec2 tiled = abs(tileSize - mod(uv, tileSize * 2.));
    float diag = dot(tiled, tileSize / 2.);
    float thres = step(1.0, diag);
    return mix(
        max(tiled.x, diag),
        max(1. - tiled.x, 2. - diag),
    thres);
}

float hexHelper(vec2 uv, float otherOne) {
    const vec2 tileSize = vec2(1.0, SQRT3);
    uv += otherOne * vec2(3., SQRT3);
    vec2 tiled = abs(
        tileSize * vec2(3., 1.) - mod(
            uv, tileSize * vec2(6., 2.)
        )
    );
    float diag = dot(tiled, tileSize);
    
    return step(max(tiled.x, diag * 0.5), 1.0);
}

float hex2(vec2 uv) {
    return max(hexHelper(uv, 0.), hexHelper(uv, 1.));
}

// map the range [0, 1) to stripes of colors
float map(float minv, float maxv, float x) {
    if (minv == maxv) {return step(minv, x);}
    return clamp(0., 1., (x - minv) / (maxv - minv));
}

void main(void)
{
    float time = fract(time / 8.);
    // Scales coords so that the diagonals are all the same distance from the center
    float scale = length(resolution.xy);
    vec2 uv = (gl_FragCoord.xy / scale
    - (resolution.xy / scale / 2.)) * 24.;
    float turnMax = -TAU / 3.;
    uv = vec2(
        cos(time * turnMax) * uv.x + sin(time * turnMax) * uv.y,
        sin(time * turnMax) * uv.x - cos(time * turnMax) * uv.y
    );
    
    float dist = hex(uv);
    float hexCol1 = hex2(uv);
    float hexCol2 = hex2(uv + vec2(1.0, SQRT3));
    vec3 baseCol = (
        HEX(0x009BE8) * hexCol1 +
        HEX(0xEB0072) * hexCol2 +
        HEX(0xfff100) * (1. - hexCol1 - hexCol2)
    );
    
    float bright = min(
        step(
            0.5, fract(
                1.5 * dist * dist - 3. * time + 0.333 * hexCol1 - 0.333 * hexCol2
            )
        ), step(
            dist, 0.9
        )
    );
    vec3 col = baseCol * bright;

    // Output to screen
    glFragColor = vec4(col,1.0);
}
