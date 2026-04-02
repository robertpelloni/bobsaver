#version 420

// original https://www.shadertoy.com/view/7tf3WB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*  
    Returns hash in range [0.0; 1.0].
*/
float sample1DHashUI32(uint value)
{
    // Pick some enthropy source values.
    // Try different values.
    const uint enthropy0 = 12345u;
    const uint enthropy1 = 67890u;

    // Calculate hash.
    value += enthropy1;
    value *= 445593459u;
    value ^= enthropy0;

    // 1.0f / 4294967295.0f = 2.32830644e-10
    
    return float(value * value * value) * 2.32830644e-10;
}

float valuetNoise1D(float u)
{
    // Fractial part.
    float fractU = u - floor(u);

    // Integer part.
    u = floor(u);
    
    // Smoothstep.
    float tU = fractU * fractU * (3.0 - 2.0 * fractU);
    
    // Pseudorandom samples.
    float sample0 = sample1DHashUI32(uint(u));
    float sample1 = sample1DHashUI32(uint(u + 1.0));

    // Linear interpolation.
    return sample0 * (1.0 - tU) + sample1 * (tU);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy * 6.0f;
    
    float _u = uv.x + mouse.x*resolution.xy.x * 0.1f + time * 0.1f;

    float gray = valuetNoise1D(_u) * 1.0f;
    gray += valuetNoise1D(_u * 2.054f) * 0.65f;
    gray += valuetNoise1D(_u * 4.554f) * 0.225f;
    gray += valuetNoise1D(_u * 8.554f) * 0.125f;
    gray += valuetNoise1D(_u * 9.554f) * 0.325f;
    gray += valuetNoise1D(_u * 32.554f) * 0.125f;
      
    float lineWidth = 16.0/resolution.y;
    gray = smoothstep(0.0, lineWidth, abs(uv.y - gray - 1.5));
    
    // Output to screen
    glFragColor = vec4(vec3(gray),1.0);
}
