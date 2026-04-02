#version 420

// original https://www.shadertoy.com/view/wlySD3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float seed = 1.0;
int octaves = 8;
float octaveFalloff = 0.4;
float noiseFrequency = 0.443;
float noiseLacunarity = 1.516;
float mainFbmFrequency = 2.27;
float mainWarpGain = 1.15;
vec2 qFreq = vec2(12.0, 0.37);
vec2 qAmp = vec2(0.0, 0.0);
vec2 rFreq = vec2(0.0, 0.2);
vec3 paletteBrightness = vec3(0.5, 0.5, 0.5);
vec3 paletteContrast = vec3(0.5, 0.5, 0.4);
vec3 paletteFrequency = vec3(1.0, 1.0, 1.0);
vec3 palettePhase = vec3(0.28, 0.3, 0.3);
float contrast = 1.27;
float brightness = 0.0;

// signed hash function (-1 to 1)
float shash(vec2 p) {
    return -1.0 + 2.0*fract((1e4 + seed) * sin(17.0 * p.x + p.y * 0.1) *
                                (0.1 + abs(sin(p.y * 13.0 + p.x))));
}

// 2D noise
// https://www.shadertoy.com/view/4dS3Wd
float noise(vec2 x) {
    vec2 i = floor(x);
    vec2 f = fract(x);

    // Four corners in 2D of a tile
    float a = shash(i);
    float b = shash(i + vec2(1.0, 0.0));
    float c = shash(i + vec2(0.0, 1.0));
    float d = shash(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 x) {
    float v = 0.0;
    float a = 0.5;
    float maxAmp = a;
    float freq = noiseFrequency;
    float lac = noiseLacunarity;
    vec2 shift = vec2(100);
    // Rotate to reduce axial bias
    mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.5));

    // ridge
    for (int i = 0; i < octaves; i++) {
        v += a * abs(noise(x*freq));
        x = rot * x * 2.0 + shift;
        maxAmp += a*octaveFalloff;
        a *= octaveFalloff;
        freq *= noiseLacunarity;
    }
    v = 1.0 - v;
    v = pow(v, 5.0);
    // Normalize noise value so that maximum amplitude = 1.0
    v /= maxAmp;

    return v;
}

vec3 palette(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d)
{
    return a + b * cos(6.28318 * (c * t + d));
}

struct Result
    {
        float f;
        vec2 q;
        vec2 r;
    } result;

Result func(in vec2 uv)
{    
    vec4 var = vec4(0.1,
                    0.03,
                    time * 0.00164,
                    time * -0.00251);
    
    Result result;

    vec2 q = vec2(fbm(qFreq.x*uv + vec2(var.x, var.y)),
                                fbm(qFreq.y*uv + vec2(1.5*(atan(time*0.09)), 0.61*sin(time*0.053))));

    vec2 r = vec2(fbm(rFreq.x*uv + qAmp.x*q + uv + vec2(var.z, var.w)),
                                fbm(rFreq.y*uv + qAmp.y*q + uv + vec2(time*0.0043, time*0.0123)));

    float mainFreq = mainFbmFrequency;
    float warpGain = mainWarpGain;
    float f = fbm(mainFreq*uv + warpGain*r);
    result.f = f;
    result.q = q;
    result.r = r;
    return result;
}

// remember to include var
void main(void)
{
    vec2 scroll = vec2(0.02*sin(time*0.0001), 0.1);
    scroll *= 0.2;
    float palettePhaseSpeed = mod((time * 0.04), 1.0);
    // Normalized pixel coordinates (from 0 to 1)
    // vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 uv = gl_FragCoord.xy / resolution.y;
    uv *= 2.0;
    uv += vec2(time)*scroll;

    Result res = func(uv + scroll*time*0.1);
    //Result res = func(uv);
    float f = res.f;
    vec2 q = res.q;
    vec2 r = res.r;
    vec3 color = vec3(0.0);

    vec3 a = paletteBrightness;
    vec3 b = paletteContrast;
    vec3 c = paletteFrequency;
    vec3 d = palettePhase.xyz;
    d = mod(d + palettePhaseSpeed, vec3(1.0));
    color = palette(f, a, b, c, d);

    glFragColor = vec4(color, 1.0);
}
