#version 420

// original https://neort.io/art/bmkulsk3p9f7m1g01tig

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

vec2 rotate(const in vec2 v, const in float a) {
    float s = sin(a);
    float c = cos(a);
    mat2 m = mat2(c, -s, s, c);
    return m * v;
}

float gaussian (const in vec2 cuv, const in float p) {
    float n = max(0., 1. - length(cuv));
    return pow(2.718281828459045, -0.5 * pow((n - 1.) / (p * 0.5), 2.));
}

float brightnessContrast (const in float v, const in float contrast, const in float midPoint) {
    float range = min(abs(midPoint), abs(1. - midPoint));
    return mix(midPoint - range, midPoint + range, (v - 0.5) * contrast + 0.5);
}

float _processRing (const in vec2 uv, const in vec2 offset) {
    vec2 cuv = (fract(uv) - 0.5) * 2.;
    cuv = cuv * 0.5 + 0.5;
    cuv = fract(cuv);
    cuv = cuv - 0.5 + offset;
    cuv = rotate(cuv, 2.98294) * 2. / vec2(4.001, 0.583);
    
    float v = gaussian(cuv, 0.5);
    
    return v;
}

float processRing (in vec2 uv) {
    uv = (uv - 0.5) / 0.908;
    vec2 nuv = vec2(0.);
    nuv.x = fract(0.5+atan(uv.y, uv.x) / 6.2832 - 3.65 / 6.2832);
    nuv.y = clamp(length(uv) * 2. - 0.138 * 2., 0., 1.);
    
    float value = 0.;
    for (float x = -2.; x <= 2.; x++) for (float y = -1.; y <= 1.; y++) {
        value+= _processRing(nuv, vec2(x, y));
    }
    
    return clamp(brightnessContrast(value, 1.05227907, 0.4875), 0., 1.) * clamp(length(uv)*6., 0., 1.);
}

float hash1 (const in vec2 n, const in float seed) {
    return fract(sin(dot(n + seed / 120.795,vec2(127.1 + seed/33., 311.7 +seed/35.)))*(43758.5453 + seed*101.3579));
}

vec2 hash2 (in vec2 p, const in float seed) {
    p = vec2(dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)) );
    return fract(sin(p + seed) * (43758.5453 + seed));
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
        gain(0.95, t),
        t * t * t * (t * (t * 6. - 15.) + 10.),
        clamp(smoothness * 1.75 + 0.25, 0., 1.)
    );
    return mix(mix(p00, p10, pt.x), mix(p01, p11, pt.x), pt.y);
}

const float deformShape = 1.963;
const float deformAmount = 0.65;
const float smoothness = 0.312;
const float displacementAngle = 5.77013;
const float displacementAmount = 0.324;
const float displacementSmoothing = 0.01;
const float weightReduction = 0.395;

float valueNoise2d(in vec2 uv, const in float scale, const in float seed) {
    uv = uv * scale * 2.;
    vec2 p = floor(uv);
    vec2 f = fract(uv);
    float p00 = hash1(mod(p, scale * 8.), seed);
    float p01 = hash1(mod(p + vec2(0., 1.), scale * 8.), seed);
    float p10 = hash1(mod(p + vec2(1., 0.), scale * 8.), seed);
    float p11 = hash1(mod(p + vec2(1., 1.), scale * 8.), seed);
    vec2 pd = hash2(mod(p + vec2(0.5), scale * 8.), seed + p00);
    float d = clamp(pow(
        pow(pow(abs(f.x - 0.5) * 2., deformShape) + pow(abs(f.y - 0.5) * 2., deformShape), 1. / deformShape)
        , deformAmount), 0., 1.);
    return controllableBilinearLerp(p00, p10, p01, p11, mix(clamp(mix(f, pd, deformAmount), 0., 1.), f, d), smoothness);
}

float fractalValueNoise2d (const in vec2 uv) {
    float f = 0.;
    float w = 0.;
    vec2 displacementDir = vec2(cos(displacementAngle),sin(displacementAngle));
    for (float octave = 1.; octave <= 8.; octave++) {
        float weight = 1. / pow(1. / (1. - weightReduction), abs(octave - 0.224));
        f+= valueNoise2d( uv - f * displacementAmount * displacementDir / mix(1., pow(2., octave) / 2., displacementSmoothing), pow(2., octave), octave) * weight;
        w+= weight;
    }
    return clamp(f / w, 0., 1.);
}

float hardLightBlend (const in float background, const in float foreground, const in float opacity) {
    return mix(background, mix(
        (255. -  ((255. - 2. * (foreground * 255. - 128.)) * (255. - background * 255.)) / 256.) / 255.,
        2. * foreground * background * 255. / 256.,
        foreground > 128. / 255. ? 0. : 1.
    ), opacity);
}

const float angle = 6.02906;
const float intensity = -0.04;
const float angleIntensity = 0.504;

vec2 directionalWarpUv (in vec2 uv, const in float intensityMap, const in float angleMap) {
    float i = intensityMap * 2. - 1.;
    float a = angleMap * 2. - 1.;
    float iangle = angle + a * angleIntensity * 6.2831853071795;

    return uv - vec2(cos(iangle), sin(iangle)) * i * intensity;
}

void main (void) {
    vec2 uv = (gl_FragCoord.xy - vec2(resolution.x / 2., resolution.y / 2.)) / resolution.yy + 0.5;
    
    uv-= 0.6 * (uv - 0.5) * pow(clamp(1. - length(uv - 0.5) * 2.7, 0., 1.), 0.45);
    
    float f = clamp(pow(max(0., length(uv - 0.5) - 0.5) / 0.5, 2.5), 0., 1.);
    
    vec2 noiseOffset = vec2(-0.033, 0.0115) * time;
    
    float ring1 = processRing(uv);
    float noise1 = clamp(brightnessContrast(fractalValueNoise2d(uv + noiseOffset), 1.04174604140042, 0.425), 0., 1.);
    float v1 = hardLightBlend(noise1, ring1, 0.681);
    
    vec2 nuv = directionalWarpUv(uv, ring1 - f * 0.2, noise1 + f * 0.2);
    
    float ring2 = processRing(nuv);
    float noise2 = clamp(brightnessContrast(fractalValueNoise2d(nuv + noiseOffset), 1.04174604140042, 0.425), 0., 1.);
    float v2 = hardLightBlend(noise2, ring2, 0.71);
    
    float v = hardLightBlend(v2, v1, 0.82 * (0.3 + 0.7 * ring1));
   
    v = (pow(v, mix(4. - ring2 * 3., 1., clamp(uv.x * 0.4 + noise2 - 0.25, 0., 1.))) + v) * 0.525;
    
    glFragColor.rgb = mix(vec3(0.0, 0.0, 0.04), vec3(1., 0.97, 0.73), v);
    glFragColor.a = 1.;
}
