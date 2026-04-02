#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3llSzf

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*--------------------------------------------------------------------------------------
License CC0 - http://creativecommons.org/publicdomain/zero/1.0/
To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
----------------------------------------------------------------------------------------
-Otavio Good
*/

// Number of antialiasing samples - if your computer is fast, make it bigger.
const int numSamples = 32;
// Set to 0 or 1 for different effects
#define STYLE2 0

// ---- general helper functions / constants ----
#define saturate(a) clamp(a, 0.0, 1.0)
// Weird for loop trick so compiler doesn't unroll loop
// By making the zero a variable instead of a constant, the compiler can't unroll the loop and
// that speeds up compile times by a lot.
#define ZERO_TRICK max(0, -frames)
const float PI = 3.14159265;

vec2 Rotate(vec2 v, float rad)
{
  float cos = cos(rad);
  float sin = sin(rad);
  return vec2(cos * v.x + sin * v.y, -sin * v.x + cos * v.y);
}

// ---- Hash functions and random number generation ----
// Random 32 bit primes from this site: https://asecuritysite.com/encryption/random3?val=32
// This is the single state variable for the random number generator.
uint randomState = 4056649889u;

// 2 simple hash functions - for extra randomness, call them both
uint SmallHashIA(uint seed) {
    return (seed ^ 1057926937u) * 3812423987u;
}
uint SmallHashIB(uint seed) {
    return (seed ^ 2156034509u) * 808515863u;
}

// Returns a random float from [0..1]
float Hashf1(uint seed) {
    seed = SmallHashIA(seed);
    // 0xffffff is biggest 2^n-1 that 32 bit float does exactly.
    // Check with Math.fround(0xffffff) in javascript.
    return float(seed & 0xffffffu) / float(0xffffff);
}
// Reduced precision to 10 bits per component.
vec3 Hashf3(uint seed) {
    seed = SmallHashIA(seed);
    return vec3((seed >> 2) & 0x3ffu,
                (seed >> 12) & 0x3ffu,
                seed >> 22) / float(0x3ffu);
}

// Combine random state with hash function to get a random float [0..1]
float Randf1() {
    randomState = SmallHashIA(randomState) >> 7;
    randomState = SmallHashIB(randomState);
    // 0xffffff is biggest 2^n-1 that 32 bit float does exactly.
    // Check with Math.fround(0xffffff) in javascript.
    return float(randomState & 0xffffffu) / float(0xffffff);
}
// Reduced precision to 16 bits per component.
vec2 Randf2() {
    randomState = SmallHashIA(randomState) >> 7;
    randomState = SmallHashIB(randomState);
    return vec2(randomState & 0xffffu,
                randomState >> 16) / float(0xffff);
}
// Reduced precision to 10 bits per component.
vec3 Randf3() {
    randomState = SmallHashIA(randomState) >> 7;
    randomState = SmallHashIB(randomState);
    return vec3((randomState >> 2) & 0x3ffu,
                (randomState >> 12) & 0x3ffu,
                randomState >> 22) / float(0x3ffu);
}

// Set a unique (hopefully) random seed for each pixel and time.
// Call like this: SetRandomSeed(uint(fragCoord.x), uint(fragCoord.y), uint(iFrame));
void SetRandomSeed(uint a, uint b, uint c) {
    randomState = SmallHashIA(a)>>7;
    randomState ^= SmallHashIB(b * 3435263017u);
    randomState += c * 7u;
}

// Returns random number sampled from a circular gaussian distribution
// https://en.wikipedia.org/wiki/Box%E2%80%93Muller_transform
vec2 RandGaussianCircle() {
    vec2 u = Randf2();
    u.x = max(u.x, 0.00000003); // We don't want log() to fail because it's 0.
    float a = sqrt(-2.0 * log(u.x));
    return vec2(a * cos(2.0*PI*u.y), a * sin(2.0 * PI * u.y));
}

vec3 Fractal(vec2 p, uint seed0, float localTime)
{
    vec2 wraps = vec2(0.0);
    uint seed = SmallHashIA(uint(floor((p.x+256.0)*0.5)));
    seed ^= SmallHashIB(uint(floor((p.y+256.0)*0.5+139.0)*15467.0));
    seed ^= seed0;

    vec2 pr = p;
    // repeat -1 to 1 region, still scaled to -1 to 1
    pr = fract(pr*0.5+0.5)*2.0 - 1.0;
    // Bend to be more squareish or diamondish, oscillating over time
    pr = pow(abs(pr),vec2(1.0+sin(time*0.5)*0.3))*sign(pr);
    //if (length(fract(pr*0.5)-0.5) > 0.5) return vec4(0.005);
    for (int i = 0; i < 15; i++)
    {
        // If it's out of range and gonna be repeated, count it.
        wraps.xy = floor(pr*0.5+0.5)*1.1-0.015;
        // repeat -1 to 1 region, still scaled to -1 to 1
        pr = fract(pr*0.5+0.5)*2.0 - 1.0;
        // Bend to be more squareish
        pr = pow(abs(pr),vec2(1.2))*sign(pr);
        // Make little rings that turn into swooshy lines at higher iterations.
        float l = length(fract(pr*0.5)-0.5);
        l = sin(l*4.0/float(i+1));
        if ((l > 0.35) && (l < 0.355)) return vec3(0.025);

        // Darken regions outside a circle on higher iterations.
        if ((i > 2) && (length(fract(pr*0.5)-0.5) > 0.5)) return vec3(0.005);
        // Rotate whatever is outside the circle
        if (length(pr) > 1.0)
            pr = Rotate(pr, localTime*0.03+float(seed&0xffu));
        // length squared
        float len = dot(pr, pr);
        // sorta normalize position - divide by length SQUARED. Invert the circle.
        float inv = 1.0/len;
        pr *= inv;
        // Rotate things based on their distance from the center of the circle.
#if STYLE2
        if (length(pr) < 1.1)
#endif
            pr = mix(pr, Rotate(pr, -localTime*0.1), saturate(length(pr)));
    }
    float dist = 0.0;// length(pr*pr)*0.5;
    return vec3(dist, wraps);
}

void main(void)
{
    SetRandomSeed(uint(gl_FragCoord.x), uint(gl_FragCoord.y), uint(frames*0));
    // center and scale the UV coordinates
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv.x -= 0.2;
    uv.x *= resolution.x / resolution.y;
    uv *= 4.0;

    glFragColor = vec4(0,0,0,1);
    if (uv.x >= 4.0) return;
    if (uv.x <= 0.0) return;

    // Loop that takes many samples of the image for anti-aliasing
    vec4 totalColor = vec4(0.0);
    for (int samp = ZERO_TRICK; samp < numSamples; samp++) {
        float antialias = dFdx(uv.xy).x*1.0;
        vec2 uv2 = uv + Randf2() * antialias;
        // Do the thing!
        vec3 fr = Fractal(uv2, 1234567u, cos(time*0.25)*12.0);
        //fr.x = step(fr.x, 0.5);
        float dist = length(fr.yz);
        vec3 finalColor = vec3(-cos(dist*21.123), -cos(dist*0.77), -cos(dist*5.321))*0.5+0.5;

        // Accumulate antialiasing samples
        totalColor.xyz += finalColor;
        totalColor.w += 1.0;
    }

    glFragColor = vec4(sqrt(totalColor.xyz / totalColor.w), 1.0);
}
