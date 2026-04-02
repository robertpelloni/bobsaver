#version 420

// original https://www.shadertoy.com/view/slf3WB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    Returns hash in range [0.0; 1.0].
*/
float sample2DHashUI32(uint x, uint y)
{
    // Pick some enthropy source values.
    // Try different values.
    const uint enthropy0 = 123u;
    const uint enthropy1 = 456u;
    const uint enthropy2 = 789u;

    // Use linear offset method to mix coordinates.
    uint value = y * enthropy2 + x;

    // Calculate hash.
    value += enthropy1;
    value *= 445593459u;
    value ^= enthropy0;
    
    // 1.0f / 4294967295.0f = 2.32830644e-10

    return float(value * value * value) * 2.32830644e-10;
}

float valuetNoise2D(float u, float v)
{
    // Fractial part.
    float fractU = u - floor(u);
    float fractV = v - floor(v);

    // Integer part.
    u = floor(u);
    v = floor(v);
    
    // Smoothstep.
    float tU = fractU * fractU * (3.0 - 2.0 * fractU);
    float tV = fractV * fractV * (3.0 - 2.0 * fractV);
    
    // Pseudorandom samples.
    float sample0 = sample2DHashUI32(uint(u),       uint(v));
    float sample1 = sample2DHashUI32(uint(u + 1.0), uint(v));
    float sample2 = sample2DHashUI32(uint(u),       uint(v + 1.0));
    float sample3 = sample2DHashUI32(uint(u + 1.0), uint(v + 1.0));

    // Bilinear interpolation.
    return 
        sample0 * (1.0 - tU) * (1.0 - tV) + 
        sample1 * tU         * (1.0 - tV) +
        sample2 * (1.0 - tU) * tV +
        sample3 * tU         * tV;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy * 6.0f;
    
    float _u = uv.x + mouse.x*resolution.xy.x * 0.1f + time * 0.1f;
    float _v = uv.y + mouse.y*resolution.xy.x * 0.1f + time * 0.1f;

    float gray = valuetNoise2D(_u, _v) * 0.25f;
    gray += valuetNoise2D(_u * 2.054f, _v * 2.354f) * 0.125f;
    gray += valuetNoise2D(_u * 4.554f, _v * 4.254f) * 0.125f;
    gray += valuetNoise2D(_u * 8.554f, _v * 8.754f) * 0.0625f;
    gray += valuetNoise2D(_u * 9.554f, _v * 9.154f) * 0.025f;
    gray += valuetNoise2D(_u * 16.554f, _v * 16.854f) * 0.025f;
    gray += valuetNoise2D(_u * 32.554f, _v * 32.354f) * 0.025f;
      
    // Output to screen
    glFragColor = vec4(vec3(gray),1.0);
}
