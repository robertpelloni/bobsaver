#version 420

// original https://www.shadertoy.com/view/XlsSR4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.14159;

float rand (in vec2 seed) {
    seed = fract (seed * vec2 (5.6789, 5.4321));
    seed += dot (seed.yx, seed + vec2 (12.3456, 15.1273));
    return fract (seed.x * seed.y * 5.1337);
}

vec3 hsv2rgb (in float h, in float s, in float v) {
    return v * (1.0 + 0.5 * s * (cos (2.0 * PI * (h + vec3 (0.0, 2.0 / 3.0, 1.0 / 3.0))) - 1.0));
}

void main(void) {
    vec2 frag = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    float radius = max (length (frag), 0.3);
    frag *= 1.0 + 0.1 * cos (radius * 3.0 - time * 7.0) / radius;
    float light = smoothstep (-0.7, 0.7, cos (time * 0.4));
    vec3 colorBackground = hsv2rgb (radius * 0.4 - time * 1.5, 0.5, light);

    float angle = 2.0 * PI * cos (time * 0.2 + 0.5 * PI * cos (time * 0.1));
    float c = cos (angle);
    float s = sin (angle);
    frag = (4.0 + 1.5 * cos (time)) * mat2 (c, s, -s, c) * frag;
    frag += 5.0 * vec2 (s, c);

    float random = rand (floor (frag));
    frag = fract (frag) - 0.5;
    angle = atan (frag.y, frag.x);
    radius = length (frag);
    radius *= 1.0 + (0.3 + 0.3 * cos (angle * 5.0 + PI * cos (random * PI * 2.0 + time * 5.0))) * smoothstep (-0.5, 0.5, cos (random * PI * 2.0 + time * 2.0));

    vec3 colorShape = hsv2rgb (radius * 0.6 + random * 13.0 - time, 0.5, 1.0 - light);
    float display = smoothstep (0.5, 0.4, radius);
    display *= smoothstep (-0.5, 0.5, cos (random * PI * 2.0 + time * 1.5));

    glFragColor = vec4 (mix (colorBackground, colorShape, display), 1.0);
}
