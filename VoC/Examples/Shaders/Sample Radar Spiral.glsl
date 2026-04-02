#version 420

// original https://www.shadertoy.com/view/stV3R3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// take that tauists
#define TAU (3.14159265 * 2.)
// converts hex code to vec3 representation
#define HEX(x) vec3((ivec3(x) >> ivec3(16, 8, 0)) & 255)/255.
// makes triangle wave of amplitude 1 period 2
#define ZIGZAG(x) (1. - abs(1. - mod(x, 2.)))

// draws a square grid
float grid(vec2 uv, float thickness){
    uv = ZIGZAG(uv);
    return (1.-step(0., -thickness)) * smoothstep(thickness * 1.5, thickness, min(uv.x, uv.y));
}

void main(void)
{
    // loops after 2 seconds, start is offset by 0.5
    float time = fract(0.5 + time / 2.);
    
    // Scales pixel coordinates, so that
    // the center is distance 0 and
    // diagonals are distance 1
    vec2 uvR = 2. * gl_FragCoord.xy - resolution.xy;
    vec2 uv = uvR / length(resolution.xy);

    // log-polar coordinates
    float lenSq = log(uv.x * uv.x + uv.y * uv.y);
    float angle = atan(uv.y, uv.x);
    // get the angle for the sweeping needle
    float needleAngle = (0.125 + time) * TAU;
    // affects the width of each spiral stripe at the current angle
    float angleDiff = 1. - fract((0.77 + needleAngle + angle) / TAU);
    
    float spiral = ZIGZAG(2. * (
         lenSq * 0.8
       + angle / TAU
       + time * 1.
       + 0.5
    ));
    spiral = step(
        1.02 - angleDiff * angleDiff * angleDiff,
        spiral
    );
    
    // the needle is basically a square but with one side extending to infinity
    // vec2 for needle direction
    vec2 needleVec = vec2(
        sin(needleAngle) + cos(needleAngle),
        cos(needleAngle) - sin(needleAngle)
    );
    // brightness of needle at current point
    float needle = smoothstep(
        0.02, 0.018, max(
            // width of needle, capped on both ends
            abs(
                dot(uv, needleVec)
            ),
            // length of needle, capped on one end but not the other
            dot(
                vec2(uv.y, -uv.x), needleVec
            )
        )
    );
    
    // draw the grid in the background
    float grid = min(
        // coarse grid
        grid(
            uv * 10., 1. / 20.
        )
        // fine grid
        + 0.5 * grid(
            uv * 50., 1. / 8.
        ),
        // cap the brightness at 1 so the overlapping grid lines don't overexpose
        1.
    );
    
    // the circle rings from the center
    float circles = step(
        -0.02 * lenSq + 0.8
    , fract(
        0.2 * lenSq + time * 3.
    ));
    
    // Time varying pixel color
    vec3 col = mix(
        HEX(0x003000),
        HEX(0x008010),
        // mask the spiral behind the needle
        min(spiral, 1. - needle)
    )
    + HEX(0x002000) * grid
    + HEX(0xAFCF60) * needle
    + HEX(0x806060) * grid * circles;

    // Output to screen
    glFragColor = vec4(col,1.0);
}
