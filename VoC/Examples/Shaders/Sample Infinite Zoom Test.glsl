#version 420

// original https://www.shadertoy.com/view/XdlBzS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int numWaves = 5;
float numStripes = .3;
const float numFreqs = 10.0;
const float meanFreq = 4.0;
const float stdDev = 2.0;
const float period = .5;
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
    for(int n = 0; n < int(numFreqs); n++)
    {
        sum1 += wavething(n, scale);
    }
    
    vec2 xy = pi2 * numStripes
        * (2.0 * gl_FragCoord.xy / resolution.y - vec2(resolution.x / resolution.y, 1.0));
    //xy -= pi2 * numStripes * (2.0 * mouse*resolution.xy.xy / resolution.y - vec2(resolution.x / resolution.y, 1.0));
    
    // oscillate position offset based on time (sloppy, can be done much cleaner)
    vec2 xyCalc = pi2 * numStripes * (2.0 * vec2(0.0) / resolution.y - vec2(resolution.x / resolution.y, 1.0));
    float xCalc = xyCalc.x;
    float yCalc = xyCalc.y;
    
    float max = xCalc * -0.025;
    float min = xCalc * 0.025;
    float oscilationRange = (max - min)/2.0;
    float oscilationOffset = oscilationRange + min;
    float xVal = oscilationOffset + sin(time / 1.) * oscilationRange;
    
    max = yCalc * -0.025;
    min = yCalc * 0.025;
    oscilationRange = (max - min)/2.0;
    oscilationOffset = oscilationRange + min;
    float yVal = oscilationOffset + sin(time / .5) * oscilationRange;
    
    xy.x -= xVal;
    xy.y -= yVal;
    
    float sum2 = 0.0;
    for(int n = 0; n < numWaves; n++)
    {
        float theta = pi * float(n) / float(numWaves);
        vec2 waveVec = vec2(cos(theta), sin(theta));
        float phase = dot(xy, waveVec);
        for(int k = 0; k < int(numFreqs); k++){
            sum2 += cos(phase * scale * exp2(float(k))) * wavething(k, scale);
        }
    }
    //glFragColor = vec4(0.0, sum2 / sum1, sum2 / sum1, 1.0);
    
    /*
    float rAmt = 0.2;
    float gAmt = 0.7;
    float bAmt = 0.5;
    glFragColor = vec4(sum2 / sum1 * rAmt, sum2 / sum1 * gAmt, sum2 / sum1 * bAmt, 1.0);
    
    float rTint = 0.45;
    float gTint = 0.1;
    float bTint = 0.3;
    glFragColor += vec4(rTint, gTint, bTint, 0.0);
    */
    
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    glFragColor = vec4(sum2 / sum1 * .5 * sin(time / period), sum2 / sum1 * 0.5 * sin(time / period), sum2 / sum1 + sin(time / period), 1.0);
}
