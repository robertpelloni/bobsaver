#version 420

// original https://www.shadertoy.com/view/3ls3Wr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// All credit goes to https://www.shadertoy.com/view/3sXXD4
// This is just me cleaning up the code while trying to figure out what was going on

#define PI 3.14159265359

const int RAMP_STEPS = 5;

/** 
 * Noise
 * @src https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83#perlin-noise
 */

// Noise: Random
float rand(vec2 c){
    return fract(sin(dot(c.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

// Noise: Basic noise
float noise(vec2 p, float freq){
    float unit = resolution.x / freq;
    vec2 ij = floor(p / unit);
    vec2 xy = .5 * (1. - cos(PI * mod(p, unit) / unit));
    float a = rand((ij + vec2(0., 0.)));
    float b = rand((ij + vec2(1., 0.)));
    float c = rand((ij + vec2(0., 1.)));
    float d = rand((ij + vec2(1., 1.)));
    float x1 = mix(a,b,xy.x);
    float x2 = mix(c,d,xy.x);
    return mix(x1,x2,xy.y);
}

// Noise: Perlin noise
float perlinNoise(vec2 p, int res, float scale, float lacunarity) {
    float persistance = .5;
    float n = 0.;
    float normK = 0.;
    float f = scale;
    float amp = 1.;
    int count = 0;
    for(int i = 0; i < 50; i++) {
        n += amp * noise(p + time,f);
        f *= lacunarity;
        normK += amp;
        amp *= persistance;
        if (count == res) break;
        count++;
    }
    float nf = n / normK;
    return nf * nf * nf * nf * 3.;
}

/**
 * Animation
 * @src https://www.shadertoy.com/view/3sXXD4
 */
float noiseTextureScalar(vec2 position, float distortion, float scale, int detail) {
    float distortionTheta = perlinNoise(position, detail, scale, 2.) * 2. * PI;
    vec2 distortionOffset = distortion * vec2(cos(distortionTheta), sin(distortionTheta));
    return abs(perlinNoise(position + distortionOffset, detail, scale, 2.));
}

vec4 noiseTexture(vec2 position, float distortion, float scale, int detail) {
    return vec4(
        noiseTextureScalar(position + 10000., distortion, scale, detail),
        noiseTextureScalar(position + 20000., distortion, scale, detail),
        noiseTextureScalar(position, distortion, scale, detail),
        1.
    );
}

vec3 colorRamp(float position, vec4 steps[RAMP_STEPS]) {
    vec3 color = mix(steps[0].rgb, steps[1].rgb, smoothstep(steps[0].a, steps[1].a, position));
    color = mix(color, steps[2].rgb, smoothstep(steps[1].a, steps[2].a, position));
    color = mix(color, steps[3].rgb, smoothstep(steps[2].a, steps[3].a, position));
    color = mix(color, steps[4].rgb, smoothstep(steps[3].a, steps[4].a, position));
    return color;
}

void main(void) {
    vec4 rampColors[RAMP_STEPS];
    
    // Fourth parameter is not really alpha,
    // but where the color will map to on the ramp
    rampColors[0] = vec4(0.000, 0.240, 0.500, 0.100);
    rampColors[1] = vec4(0.003, 0.300, 0.297, 0.);
    rampColors[2] = vec4(0.336, 0.800, 0.792, 0.200);
    rampColors[3] = vec4(0.459, 1.000, 0.825, 0.700);
    rampColors[4] = vec4(0.325, 0.700, 0.646, 1.000);
    
    vec4 n1 = noiseTexture(gl_FragCoord.xy, 10., 1. + .0005 * time, 16);
    vec4 n2 = noiseTexture(n1.xy * resolution.xy, 5., 8., 16);

    glFragColor = vec4(colorRamp(n2.x, rampColors), 1.);
}
