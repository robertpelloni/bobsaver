#version 420

// original https://www.shadertoy.com/view/dsfSDj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////
// helpers
////////////////////////

#define PI     3.14159265358
#define TWO_PI 6.28318530718

vec2 rotateCoord(vec2 uv, float rads) {
    uv *= mat2(cos(rads), sin(rads), -sin(rads), cos(rads));
    return uv;
}

float saw(float rads) {
    rads += PI * 0.5;
    float percent = fract(rads/PI);
    float dir = sign(sin(rads));
    return dir * (2. * percent  - 1.);
}

float oscBetween(float low, float high, float time, float offset) {
  float range = abs(high - low);
  float halfRange = range / 2.;
  float midPoint = low + halfRange;
  return midPoint + halfRange * sin(offset + time);
}

////////////////////////
// patterns
////////////////////////

vec3 drawChevronStripes(vec2 uv) {
    // rotate
    float rotate = oscBetween(-1., 1., time/2., 0.);
    uv = rotateCoord(uv, rotate * -1.);
    uv.y *= resolution.y / resolution.x;
    // build params
    float altTime = time * 0.5;
    float chevronAmp = 0.06;
    float freqAmp = oscBetween(0., 1., time/2., 0.);
    float freq = 10. + freqAmp * 20.;
    float zoom = oscBetween(0., 1., time/3., PI);
    float numLines = 20. + zoom * 100.;
    float x = uv.x;
    // lerp between saw & sin
    float sawWaveDisp = saw(x * freq);
    float sinWaveDisp = sin(x * freq);
    uv.y += chevronAmp * mix(sawWaveDisp, sinWaveDisp, 0.5 + 0.5 * sin(altTime));
    float col = 0.5 + 0.5 * sin(uv.y * numLines);
    return vec3(col);
}

vec3 drawWarpVortex(vec2 uv) {
    float rotate = oscBetween(-1., 1., time/3., 0.);
    float altTime = time * 0.05;
    float rads = atan(uv.x, uv.y) + rotate; 
    float zoom = oscBetween(0.3, 1., time/3., PI);
    float dist = length(uv) * zoom;
    float spinAmp = oscBetween(-2., 2., time/4., 0.);
    float spinFreq = oscBetween(0.3, 5., time/3., PI);;
    rads += sin(altTime + dist * spinFreq) * spinAmp * (1. - dist/8.);
    float radialStripes = 24.;
    float col = 0.5 + 0.5 * sin(rads * radialStripes);
    return vec3(col);
}

////////////////////////
// main - combine the patterns!
////////////////////////

void main(void)
{
    // Centered pixel coordinates
    vec2 uv =  (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.y;

    // oscillated pattern mix
    float drawFunc1Mix = oscBetween(0.3, 0.7, time/3., 0.);
    float drawFunc2Mix = oscBetween(0.3, 0.7, time/2., PI/2.);

    // sum of patterns
    vec3 col = vec3(0.);
    col += drawFunc1Mix * drawChevronStripes(uv);
    col += drawFunc2Mix * drawWarpVortex(uv);
    
    // test individual patterns
    // col = drawChevronStripes(uv);
    // col = drawWarpVortex(uv);

    // "threshold" combine patterns & output
    col = smoothstep(0.45, 0.55, col);
    glFragColor = vec4(col, 1.0);
}
