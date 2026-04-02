#version 420

// original https://www.shadertoy.com/view/3cVcWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Morphing Sprott–Pickover-style quadratic map fractal.
// Coefficients smoothly morph from one random set to the next over time.

// --- Small hash helper for pseudo-randomness ---
float hash1(float n) {
    return fract(sin(n) * 43758.5453123);
}

// We'll pack the 12 coefficients into three vec4s for convenience:
// ca = (a1,a2,a3,a4)
// cb = (a5,a6,a7,a8)
// cc = (a9,a10,a11,a12)
struct Coeffs {
    vec4 ca;
    vec4 cb;
    vec4 cc;
};

// Map a seed (e.g. 0.0, 1.0, 2.0, ...) to a random coefficient set in [-1.2, 1.2]
Coeffs makeCoeffs(float seed) {
    float r0  = hash1(seed * 13.0  + 0.0);
    float r1  = hash1(seed * 13.0  + 1.0);
    float r2  = hash1(seed * 13.0  + 2.0);
    float r3  = hash1(seed * 13.0  + 3.0);
    float r4  = hash1(seed * 13.0  + 4.0);
    float r5  = hash1(seed * 13.0  + 5.0);
    float r6  = hash1(seed * 13.0  + 6.0);
    float r7  = hash1(seed * 13.0  + 7.0);
    float r8  = hash1(seed * 13.0  + 8.0);
    float r9  = hash1(seed * 13.0  + 9.0);
    float r10 = hash1(seed * 13.0  + 10.0);
    float r11 = hash1(seed * 13.0  + 11.0);

    // Map 0..1 -> -1.2..1.2
    float lo = -1.2;
    float hi =  1.2;

    float a1  = mix(lo, hi, r0);
    float a2  = mix(lo, hi, r1);
    float a3  = mix(lo, hi, r2);
    float a4  = mix(lo, hi, r3);
    float a5  = mix(lo, hi, r4);
    float a6  = mix(lo, hi, r5);
    float a7  = mix(lo, hi, r6);
    float a8  = mix(lo, hi, r7);
    float a9  = mix(lo, hi, r8);
    float a10 = mix(lo, hi, r9);
    float a11 = mix(lo, hi, r10);
    float a12 = mix(lo, hi, r11);

    Coeffs c;
    c.ca = vec4(a1, a2, a3, a4);
    c.cb = vec4(a5, a6, a7, a8);
    c.cc = vec4(a9, a10, a11, a12);
    return c;
}

// Quadratic map using the packed coefficients
vec2 quadraticMap(vec2 p, Coeffs c) {
    float x = p.x;
    float y = p.y;
    float xx = x * x;
    float yy = y * y;
    float xy = x * y;

    float new_x = c.ca.x + c.ca.y*x + c.ca.z*xx + c.ca.w*xy
                + c.cb.x*y + c.cb.y*yy;

    float new_y = c.cb.z + c.cb.w*x + c.cc.x*xx + c.cc.y*xy
                + c.cc.z*y + c.cc.w*yy;

    return vec2(new_x, new_y);
}

// Simple HSV -> RGB for coloring
vec3 hsv2rgb(vec3 c) {
    vec3 p = abs(fract(c.xxx + vec3(0.0, 2.0/3.0, 1.0/3.0)) * 6.0 - 3.0);
    return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

void main(void) {
    // Normalized coords, preserve aspect
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;

    // --- Time-based morphing between seeds ---
    float segment = 8.0; // seconds per morph
    float tGlobal = time / segment;      // 0,1,2,3,...
    float seedA   = floor(tGlobal);       // current "word" id
    float seedB   = seedA + 1.0;          // next "word" id
    float f       = fract(tGlobal);       // 0..1 blend factor
    // make the morph smoother at ends
    float blend   = smoothstep(0.0, 1.0, f);

    Coeffs cA = makeCoeffs(seedA);
    Coeffs cB = makeCoeffs(seedB);

    Coeffs c;
    c.ca = mix(cA.ca, cB.ca, blend);
    c.cb = mix(cA.cb, cB.cb, blend);
    c.cc = mix(cA.cc, cB.cc, blend);

    // View window in (x,y) space
    float zoom  = 2.5;
    vec2 center = vec2(0.0, 0.0);
    vec2 z      = uv * zoom + center;

    const int   MAX_ITERS = 300;
    const float BAILOUT   = 10.0;
    float bailout2        = BAILOUT * BAILOUT;

    int escapedIter = MAX_ITERS;

    // Iterate map
    for (int i = 0; i < MAX_ITERS; i++) {
        z = quadraticMap(z, c);
        float r2 = dot(z, z);
        if (r2 > bailout2 && escapedIter == MAX_ITERS) {
            escapedIter = i;
            break;
        }
    }

    // Normalize "time to escape" (or bounded) into [0,1]
    float t = float(escapedIter) / float(MAX_ITERS);

    // Angle-based hue
    float angle = atan(z.y, z.x);
    float ang01 = (angle + 3.14159265) / (2.0 * 3.14159265);

    // Brightness: bounded orbits (never escaped) are bright
    float value = pow(t, 0.1);
    float sat   = (escapedIter < MAX_ITERS) ? 0.9 : 0.5;

    vec3 col = hsv2rgb(vec3(ang01, sat, value));

    glFragColor = vec4(col, 1.0);
}
