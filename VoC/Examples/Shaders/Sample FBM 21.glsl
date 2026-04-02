#version 420

// original https://www.shadertoy.com/view/4c2Gzm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float random (in vec2 _st) {
    return fract(sin(dot(_st.xy,
                         vec2(12.9898,78.233)))*
        314159.5453123);
}

// Based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise (in vec2 _st) {
    vec2 i = floor(_st);
    vec2 f = fract(_st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

#define NUM_OCTAVES 8

float fbm ( in vec2 _st) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    // Rotate to reduce axial bias
    mat2 rot = mat2(cos(0.5), sin(0.5),
                    -sin(0.5), cos(0.50));
    for (int i = 0; i < NUM_OCTAVES; ++i) {
        v += a * noise(_st);
        _st = rot * _st * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

void main(void)
{
    vec2 st = gl_FragCoord.xy/resolution.xy*3.0;
    //st+=mouse*resolution.xy.xy/-resolution.xy*3.;

    // Increased complexity for a more intricate fractal structure
    vec2 q = vec2(fbm(st + 0.01 * time) + fbm(st + vec2(1.0)));
    vec2 r = vec2(fbm(st + 1.5 * q + vec2(1.7, 9.2) + 0.1 * time)) +
             vec2(fbm(st + 1.5 * q + vec2(8.3, 2.8) + 0.05 * time));
    float f = fbm(st + r);

    // Earth tone color palette
    vec3 color = mix(vec3(0.545, 0.271, 0.075),  // Dark brown
                     vec3(0.965, 0.765, 0.463),  // Light tan
                     clamp((f * f) * 4.752, 0.0, 1.568));

    color = mix(color,
                 vec3(0.753, 0.561, 0.357),  // Golden brown
                 clamp(length(q), 0.0, 1.0));

    color = mix(color,
                 vec3(0.467, 0.533, 0.251),  // Dark olive green
                 clamp(length(r.x), 0.0, 1.0));

    glFragColor = vec4((f * f * f + 0.6 * f * f + 0.5 * f) * color, 1.0);
}