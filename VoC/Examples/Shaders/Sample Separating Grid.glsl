#version 420

// original https://www.shadertoy.com/view/dtBGzV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Subdividing grid inspired by the Cantor Set

// 2π for radial grid
#define TURN (6.283185307)
// Fold range from 0 to 1
#define ZIG(x) 1. - abs(1. - 2. * fract(x))

// Eases between size 1 and size 1/3 grids
float cantor(float x, float t) {
    float zx = ZIG(x);
    // Do this to smooth out discontinuity in theta
    float dx = min(
      fwidth(x),
      fwidth(fract(x + 0.25))
    ) * .75;
    // Size 1 grid
    float s0 = smoothstep(
      -dx, dx,
      zx - 0.5
    );
    // Size 1/3 grid eased in based on t value
    float s1 = smoothstep(
      -dx, dx,
      -zx + (t / 6.)
    ) + smoothstep(
      -dx, dx,
      zx - (6. - t) / 6.
    );
    s1 *= smoothstep(0.0, 0.01, t);
    return mix(s0, 1.-s0, s1);
}

// Expanding then subdividing grid
float cantorChecker(vec2 uv, float t) {
    float scale = pow(3., -t);
    float grid = cantor(
        uv.x * scale, t
    );
    grid = mix(
        grid, 1.-grid,
        cantor(
            uv.y * scale, t
        )
    );
    return grid;
}

// Expanding radial grid
float cantorRadial(vec2 uv, float t, vec2 baseScale) {
    vec2 polar = vec2(
        log2(length(uv)) + 1.,
        atan(uv.x, uv.y) / TURN
    );
    float t_i = floor(t);
    float t_f = fract(t);
    float scaleInt = pow(3., t_i);
    float scaleFract = pow(3., t_f);
    // radial doesn’t subdivide
    float grid = cantor(baseScale.x * polar.x * scaleInt * scaleFract + t * 1., 0.);
    // circular subdivides
    grid = mix(
        grid, 1. - grid,
        cantor(
            step(1., mod(t, 2.)) * 0.5 +
            baseScale.y * polar.y * scaleInt, t_f
        )
    );
    return grid;
}

// Hex code to RGB vec3
#define HEX(x) (vec3((x >> 16) & 255, (x >> 8) & 255, x & 255) / 255.)

void main(void)
{
    // Loop every 15sec.
    float t = fract(time / 15.);
    // Center is 0, horiz is length 1
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.xx;
    // Splitscreen
    float useRadial = step(0., uv.x);
    uv.x += 0.5 - useRadial;
    
    float v = mix(
        cantorChecker(uv * 8., fract(t * 4.)),
        cantorRadial(uv, ZIG(t) * 4., vec2(2.5, 27.)),
        useRadial
    );
    // Time varying pixel color
    vec3 col = mix( HEX(0x207089), HEX(0xabcdef), v);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
