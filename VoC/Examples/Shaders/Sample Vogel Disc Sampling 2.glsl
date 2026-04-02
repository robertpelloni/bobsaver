#version 420

// original https://www.shadertoy.com/view/NdBGDR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 GetVogelDiskSample(int sampleIndex, int sampleCount, float phi) 
{
    const float goldenAngle = 2.399963;
    float sampleIndexF = float(sampleIndex);
    float sampleCountF = float(sampleCount);
    
    float r = sqrt(sampleIndexF + 0.5) / sqrt(sampleCountF);
    float theta = sampleIndexF * goldenAngle + phi;
    
    float sine = sin(theta);
    float cosine = cos(theta);
    
    return vec2(cosine, sine) * r;
}

#define TOTAL_SAMPLES int((sin(time * 0.2) * 0.5 + 0.5) * 120.0 + 20.0)

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    uv *= 1.3;

    vec3 col;
    
    const float phi = 1.6180;
    float minDist = 10000.0;
    
    for (int i = 0; i < TOTAL_SAMPLES; i++) 
    {
        vec2 point = GetVogelDiskSample(i, TOTAL_SAMPLES, phi); 
        float d = distance(uv, point);
        minDist = min(minDist, d);
    }
    
    // Suggested by elenzil (https://www.shadertoy.com/user/elenzil)
    float smoothEpsilon = 3.0 / resolution.y;
    col += smoothstep(0.05 + smoothEpsilon, 0.05 - smoothEpsilon, minDist);
   
    // col += step(minDist, 0.05);
   
    glFragColor = vec4(col,1.0);
}
