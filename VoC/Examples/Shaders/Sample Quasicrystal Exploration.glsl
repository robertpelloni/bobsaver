#version 420

// original https://www.shadertoy.com/view/dsKfDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU 6.283185307
#define ZOOM 0.3
#define TIME_SCALE 0.2
#define N_OCTAVES 9
#define BASE_FREQ 1.0

#define SIGMA 0.4
#define ROT_SPEED 0.3
#define PHASE_SPEED 0.8
#define PHASE_MOD_AMP 0.1
#define ZOOM_SPEED 2.0

#define BASE_DIVISIONS 7.0
#define DIV_MULTIPLIER 1.0
#define DIV_SPEED 0.0

vec3 samplePalette( in float t, in vec3 amp, in vec3 bias, in vec3 freq, in vec3 phase)
{
    return amp*cos(TAU*(freq*t+phase)) + bias;
}

float spatialFreqFactor(int i) {
    float baseValue = 1.0;
    for (int j = 0; j < i; j++) {
        baseValue *= 2.0;
    }
    return baseValue;
}

float gaussian(float x) {
    return exp(-x * x / 2.0) / sqrt(TAU);
}

void main(void)
{
    float t = TIME_SCALE * time;
    // Normalized pixel coordinates (from -1 to 1, centered on canvas)
    vec2 uv = ((gl_FragCoord.xy * 2.0 - resolution.xy) / (resolution.y * ZOOM));

    // Number of divisions around the circle
    float numDivisions = BASE_DIVISIONS * DIV_MULTIPLIER + t*DIV_SPEED;
    float baseFrequency = BASE_FREQ;
    float mean = log(spatialFreqFactor(int(floor(float(N_OCTAVES) / 2.0))));
    
    float v = 0.0;
    
    // calculate frequencies at each octave
    float freqs[N_OCTAVES];
    float weights[N_OCTAVES];
    float weightSum = 0.0;
        
    float geomScale = 1.0 * pow(2.0, -mod(ZOOM_SPEED*t, 1.0));
        
    for (int oct=0; oct < N_OCTAVES; oct++){
        freqs[oct] = baseFrequency * spatialFreqFactor(oct) * geomScale;
        weights[oct] = gaussian((log(freqs[oct]) - mean) / SIGMA);
        weightSum += weights[oct];
    }
        
    weightSum *= numDivisions;
    
    float phaseMod = PHASE_MOD_AMP*sin(TAU + PHASE_SPEED*t);  
    
    // Iterate through each plane
    for (float i = 0.0; i < numDivisions; i += 1.0)
    {
        // Calculate the angle for the current division
        float angle = (i / numDivisions) * TAU + ROT_SPEED * t;
        float phase = (uv.x * cos(angle) + uv.y * sin(angle)) + phaseMod;
            
        // Calculate octaves of base frequency and add to accumulated wave       
        for (int oct=0; oct < N_OCTAVES; oct++){
        
            v += cos((freqs[oct]) * phase) * weights[oct] / (1.0/sqrt(TAU));
        }
    }
        

    // convert v to value between 0.0 and 1.0
    v = 0.5 * (v / weightSum + 1.0);
    
    // Mask to quantize to either 0.2 or 0.8 grayscale vals
    if (v < 0.5){
        v = 0.2;
    } else if (v >= 0.5) {
        v = 0.8;
    }
    
    vec3 col = vec3(v,v,v);  
    //col = samplePalette(v, vec3(0.23, 0.7, 0.27),
    //                            vec3(0.77, 0.3, 0.3),
    //                            (1.0/vec3(1.0, 1.0, 0.5))*0.15,
    //                            vec3(0.5, 0.5, 0.0));
    glFragColor = vec4(col, 1.0);
}
