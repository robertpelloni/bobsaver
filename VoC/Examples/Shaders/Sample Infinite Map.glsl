#version 420

// original https://www.shadertoy.com/view/3lccD7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Hashes from "Hash without Sine" by Dave_Hoskins (https://www.shadertoy.com/view/4djSRW)
float Hash21(in vec2 p) {
    vec3 p3  = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 Hash22(in vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);

}

float SmoothNoise(in vec2 p) {
    vec2 cell = floor(p);
    vec2 local = fract(p);
    local *= local * (3.0 - 2.0 * local);

    float bl = Hash21(cell);
    float br = Hash21(cell + vec2(1.0, 0.0));
    float tl = Hash21(cell + vec2(0.0, 1.0));
    float tr = Hash21(cell + 1.0);

    return mix(mix(bl, br, local.x), mix(tl, tr, local.x), local.y);
}

float FractalNoise(in vec2 p, in float scale, in float octaves) {
    p *= scale;

    float value = 0.0;
    float nscale = 1.0;
    float tscale = 0.0;

    for (float octave=0.0; octave < octaves; octave++) {
        value += SmoothNoise(p) * nscale;
        tscale += nscale;
        nscale *= 0.5;
        p *= 2.0;
    }

    return value / tscale;
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.y;
    float unit = 2.0 / resolution.y;
    uv += 0.1 * time;

    float scale = 5.0;
    float octaves = 5.0;

    float n = FractalNoise(uv, scale, octaves);
    vec3 color = mix(vec3(0.0, 0.0, 1.0 - n), mix(vec3(0.0, 1.0, 0.0), vec3(0.8, 0.4, 0.0), n * n), smoothstep(0.5 - unit, 0.5 + unit, n));

    vec2 pinPos = floor(uv * 3.0 + 0.5) / 3.0;
    pinPos += 0.25 * Hash22(pinPos) - 0.125;
    n = FractalNoise(pinPos, scale, octaves);
    if (n > 0.5) {
        float pin = length(uv - pinPos) - 0.015;
        color = mix(color, vec3(1.0, 0.0, 0.0), smoothstep(unit, 0.0, pin));
    }

    glFragColor = vec4(color, 1.0);
}
