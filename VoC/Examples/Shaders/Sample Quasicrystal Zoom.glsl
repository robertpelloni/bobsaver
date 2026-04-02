#version 420

// original https://www.shadertoy.com/view/MdXBzS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int numWaves = 5;
const float numStripes = 1.0;
const float numFreqs = 8.0;
const float meanFreq = 4.0;
const float stdDev = 2.0;
const float period = 3.0;
const float pi = 4.0 * atan(1.0);
const float pi2 = 2.0 * pi;
const float ln2 = log(2.0);
const float mean = meanFreq * .69314718;

float wavething(int n, float x){
    float l = ln2 * float(n) + log(x);
    l -= mean;
    return exp(-l * l / stdDev) / 2.0;
}

void main(void)
{
    float scale = exp2(-fract(time / period));
    float sum1 = 0.0;
    for(int n = 0; n < int(numFreqs); n++){
        sum1 += wavething(n, scale);
    }
    vec2 xy = pi2 * numStripes
        * (2.0 * gl_FragCoord.xy / resolution.y - vec2(resolution.x / resolution.y, 1.0));
    xy -= pi2 * numStripes * (2.0 * mouse*resolution.xy.xy / resolution.y 
                              - vec2(resolution.x / resolution.y, 1.0));
    float sum2 = 0.0;
    for(int n = 0; n < numWaves; n++){
        float theta = pi * float(n) / float(numWaves);
        vec2 waveVec = vec2(cos(theta), sin(theta));
        float phase = dot(xy, waveVec);
        for(int k = 0; k < int(numFreqs); k++){
            sum2 += cos(phase * scale * exp2(float(k))) * wavething(k, scale);
        }
    }
    glFragColor = vec4(sum2 / sum1);
    float r = length(xy);
    glFragColor.x *= .5 + .5 * sin(-time * .25 + r);
    glFragColor.y *= .5 + .5 * cos(time * .25 + r);
}
