#version 420

// original https://www.shadertoy.com/view/sslSRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Settings
#define ra  2.0
#define rb -3.0
#define rc  2.0

#define plotMin 0.0
#define plotMax 8.0

// Utilities
#define drawSDF(dist, col) color = mix(color, col, smoothstep(unit, 0.0, dist))

// SDFs
float sdLine(in vec2 p, in vec2 a, in vec2 b) {
    vec2 pa = p - a, ba = b - a;
    return length(pa - ba * clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0));
}

float sdDisc(in vec2 p, in vec2 o, in float r) {
    return length(p - o) - r;
}

void main(void) {
    vec2 center = 0.5 * resolution.xy;
    vec2 mouse = (mouse*resolution.xy.xy - center) / resolution.y * 2.0;
    vec2 uv = (gl_FragCoord.xy - center) / resolution.y * 2.0;
    float unit = 4.0 / resolution.y;
    vec3 color = vec3(1.0);

    // Offset
    uv.y += 0.15;

    // Default before interaction
    if (ivec2(mouse*resolution.xy.xy) == ivec2(0)) mouse.xy = vec2(0.0);

    // Positions
    vec2 v1 = vec2(-0.5, -sqrt(1.0 / 12.0));
    vec2 v2 = vec2(0.5, v1.y);
    vec2 v3 = vec2(0.0, -2.0 * v1.y);

    drawSDF(sdDisc(uv, v1, 0.03), vec3(1.0, 0.0, 0.0));
    drawSDF(sdDisc(uv, v2, 0.03), vec3(1.0, 0.0, 0.0));
    drawSDF(sdDisc(uv, v3, 0.03), vec3(1.0, 0.0, 0.0));

    // Rings
    drawSDF(abs(sdDisc(uv, v1, 0.5)), vec3(0.0, 0.0, 1.0));
    drawSDF(abs(sdDisc(uv, v2, 0.5)), vec3(0.0, 0.0, 1.0));
    drawSDF(abs(sdDisc(uv, v3, 0.5)), vec3(0.0, 0.0, 1.0));

    // Brute force parametric plot
    float tStep = 0.075;
    vec2 prev; bool init;
    for (float t=plotMin; t < plotMax + tStep; t += tStep) {
        float t1 = t * ra, t2 = t * rb, t3 = t * rc;

        vec2 rp1 = vec2(cos(t1), sin(t1)) * 0.5 + v1;
        vec2 rp2 = vec2(cos(t2), sin(t2)) * 0.5 + v2;
        vec2 rp3 = vec2(cos(t3), sin(t3)) * 0.5 + v3;

        vec2 cur = (rp1 + rp2 + rp3) / 3.0;
        if (init) drawSDF(sdLine(uv, prev, cur), vec3(0.5, 0.0, 0.0));
        init = true;

        prev = cur;
    }

    // Rotating triangle corners
    float t1 = time * ra;
    vec2 r1 = vec2(cos(t1), sin(t1)) * 0.5 + v1;

    float t2 = time * rb;
    vec2 r2 = vec2(cos(t2), sin(t2)) * 0.5 + v2;

    float t3 = time * rc;
    vec2 r3 = vec2(cos(t3), sin(t3)) * 0.5 + v3;

    drawSDF(sdDisc(uv, r1, 0.03), vec3(0.0));
    drawSDF(sdDisc(uv, r2, 0.03), vec3(0.0));
    drawSDF(sdDisc(uv, r3, 0.03), vec3(0.0));

    // Triangle anatomy
    drawSDF(sdLine(uv, r1, r2), vec3(0.0));
    drawSDF(sdLine(uv, r2, r3), vec3(0.0));
    drawSDF(sdLine(uv, r3, r1), vec3(0.0));

    vec2 c = (r1 + r2 + r3) / 3.0;
    drawSDF(sdDisc(uv, c, 0.03), vec3(0.0));

    drawSDF(sdLine(uv, r1, c), vec3(0.0));
    drawSDF(sdLine(uv, r2, c), vec3(0.0));
    drawSDF(sdLine(uv, r3, c), vec3(0.0));

    // Vignette (kinda)
    uv *= 0.5;
    float dd = dot(uv, uv);
    color -= 0.5 * dd * dd;

    glFragColor = vec4(color, 1.0);
}
