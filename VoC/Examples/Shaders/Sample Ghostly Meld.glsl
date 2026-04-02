#version 420

// original https://neort.io/art/bmahn743p9fd22fs7pag

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

const int minOctave = 3;
const int maxOctave = 4;
const int lacunarity = 2;
const float smoothness = 0.624;
const float remapping = 0.25;
const float displacementAngle = 4.57;
const float displacementAmount = 0.255;
const float displacementSmoothing = 0.056;
const float weightReduction = 0.152;
const float seed = 0.;
const float wrapIntensity = 0.58;
const float mapThreshold = 0.57;
const float mapSmoothness = 0.2;
const float size = 0.00045;

float hash1( vec2 n, float seed) {
    return fract(sin(dot(n + seed / 120.795,vec2(127.1 + seed/33., 311.7 + seed/35.)))*(43758.5453 + seed*101.3579));
}

float bias (const in float b, const in float t) {
    return pow(t, log(b) / log(0.5));
}

vec2 gain (const in float g, const in vec2 t) {
    vec2 nt = t;
    if (t.x < 0.5) {
        nt.x = bias(1.-g, 2.*t.x) / 2.;
    } else {
        nt.x = 1. - bias(1.-g, 2. - 2. * t.x) / 2.;
    }
    if (t.y < 0.5) {
        nt.y = bias(1.-g, 2.*t.y) / 2.;
    } else {
        nt.y = 1. - bias(1.-g, 2. - 2. * t.y) / 2.;
    }
    return nt;
}

float controllableBilinearLerp (
    const in float p00,
    const in float p10,
    const in float p01,
    const in float p11,
    const in vec2 t,
    float smoothness
) {
    vec2 pt = mix(
        t * t * t * t * (t * (t * (-20.0 * t + 70.0) - 84.0) + 35.0),
        t * t * t * (t * (t * 6. - 15.) + 10.),
        clamp(smoothness, 0., 1.)
    );
    return mix(mix(p00, p10, pt.x), mix(p01, p11, pt.x), pt.y);
}

vec2 gradientNoiseDir(vec2 p, float scale, float seed) {
    float x = hash1(p, seed) * 2. - 1.;
    return normalize(vec2(x - floor(x + 0.5), abs(x) - 0.5));
}

float gradientNoise(in vec2 uv, const in float scale, const in float seed)
{
    float iscale = float(scale) * 2.;
    float iseed = seed / 103.;
    uv = uv * iscale - vec2(-0.2, 1.) * time * (scale-13.) * 0.02;
    vec2 p = floor(uv);
    vec2 f = fract(uv);
    float d00 = dot(gradientNoiseDir(mod(p, iscale*6.), iscale, iseed), f);
    float d01 = dot(gradientNoiseDir(mod(p + vec2(0, 1), iscale*6.), iscale, iseed), f - vec2(0, 1));
    float d10 = dot(gradientNoiseDir(mod(p + vec2(1, 0), iscale*6.), iscale, iseed), f - vec2(1, 0));
    float d11 = dot(gradientNoiseDir(mod(p + vec2(1, 1), iscale*6.), iscale, iseed), f - vec2(1, 1));
    float v = (1. + controllableBilinearLerp(d00, d10, d01, d11, f, smoothness)) * 0.5;
    return clamp((v - remapping) / (1. - remapping) * (1. + remapping * 2.), 0., 1.);
}

float noise (in vec2 uv) {
    float uMin = 3.;
    float uMax = 4.;
    float f = 0.;
    float w = 0.;
    vec2 displacementDir = vec2(cos(displacementAngle),sin(displacementAngle));
    float ilacunarity = float(lacunarity);
    float iseed = seed / 103.3;
    for (float octave = 4.; octave >= 3.; octave--) {
        float weight = 1. / pow(1. / (1. - weightReduction), octave);
        f+= gradientNoise(uv - f * displacementAmount * displacementDir / mix(1., pow(ilacunarity, octave) / (uMin + 1.) * 2., displacementSmoothing), pow(ilacunarity, octave), iseed + octave) * weight;
        w+= weight;
    }
    
    return clamp(f / max(0.00001, w), 0., 1.);
}

vec2 getDir (in vec2 uv, in vec2 p) {
    float fcc = noise(uv);
    vec2 dir = vec2(0.);
    for (float i = 0.; i < 12.; i++) {
        float cangle = i / 12. * 6.2832;
        vec2 cdir = vec2(cos(cangle), sin(cangle));
        vec3 crgb = vec3(noise(uv + p * cdir * 0.5));
        float cweight = fcc - (crgb.r + crgb.g + crgb.b) / 3.;
        dir -= cdir * cweight * 2.2;
    }
    return dir;
}

vec4 process (in vec2 uv) {
    vec2 dir = getDir(uv, vec2(size));
    float value = noise(uv + dir * wrapIntensity * 0.2);
    value = smoothstep(mapThreshold - mapSmoothness, mapThreshold + mapSmoothness, value);
    return vec4(vec3(0.5 + 0.5 * pow(value, 0.5 + 0.4 * sin(time * 0.05)), pow(value, 0.75 + 0.2 * sin(time * 0.1)), 0.75 + pow(value, 8. + 3. * sin(time * 0.15)) * 0.25) * value, 1.);
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) * size;

    glFragColor = process(uv);
}
