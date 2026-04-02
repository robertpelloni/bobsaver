#version 420

// original https://www.shadertoy.com/view/stXGDB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    Returns hash in range [0.0; 1.0].
*/
float sample3DHashUI32(uint x, uint y, uint z)
{
    // Pick some enthropy source values.
    // Try different values.
    const uint enthropy0 = 1200u;
    const uint enthropy1 = 4500u;
    const uint enthropy2 = 6700u;
    const uint enthropy3 = 8900u;

    // Use linear offset method to mix coordinates.
    uint value = 
        z * enthropy3 * enthropy2 +
        y * enthropy2 +
        x;

    // Calculate hash.
    value += enthropy1;
    value *= 445593459u;
    value ^= enthropy0;

    // 1.0f / 4294967295.0f = 2.32830644e-10

    return float(value * value * value) * 2.32830644e-10;
}

float valuetNoise3D(float u, float v, float w)
{
    // Fractial part.
    float fractU = u - floor(u);
    float fractV = v - floor(v);
    float fractW = w - floor(w);

    // Integer part.
    u = floor(u);
    v = floor(v);
    w = floor(w);
    
    // Pseudorandom samples.
    float sample0 = sample3DHashUI32(uint(u),       uint(v),       uint(w));
    float sample1 = sample3DHashUI32(uint(u + 1.0), uint(v),       uint(w));
    float sample2 = sample3DHashUI32(uint(u),       uint(v + 1.0), uint(w));
    float sample3 = sample3DHashUI32(uint(u + 1.0), uint(v + 1.0), uint(w));
    float sample4 = sample3DHashUI32(uint(u),       uint(v),       uint(w + 1.0));
    float sample5 = sample3DHashUI32(uint(u + 1.0), uint(v),       uint(w + 1.0));
    float sample6 = sample3DHashUI32(uint(u),       uint(v + 1.0), uint(w + 1.0));
    float sample7 = sample3DHashUI32(uint(u + 1.0), uint(v + 1.0), uint(w + 1.0));

    // Smoothstep.
    float tU = fractU * fractU * (3.0 - 2.0 * fractU);
    float tV = fractV * fractV * (3.0 - 2.0 * fractV);
    float tW = fractW * fractW * (3.0 - 2.0 * fractW);

    // Trilinear interpolation.
    return 
        sample0 * (1.0 - tU) * (1.0 - tV) * (1.0 - tW) + 
        sample1 * tU         * (1.0 - tV) * (1.0 - tW) +
        sample2 * (1.0 - tU) * tV         * (1.0 - tW) +
        sample3 * tU         * tV         * (1.0 - tW) +
        sample4 * (1.0 - tU) * (1.0 - tV) * tW + 
        sample5 * tU         * (1.0 - tV) * tW +
        sample6 * (1.0 - tU) * tV         * tW +
        sample7 * tU         * tV         * tW;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy * 6.0f;
    
    float _u = uv.x + mouse.x*resolution.xy.x * 0.1f;
    float _v = uv.y + mouse.y*resolution.xy.x * 0.1f;
    float _w = uv.x + time * 0.4f;

    float gray = valuetNoise3D(_u, _v, _w) * 0.35f;
    gray += valuetNoise3D(_u * 2.054f, _v * 2.354f, _w * 2.754f) * 0.125f;
    gray += valuetNoise3D(_u * 4.554f, _v * 4.254f, _w * 4.154f) * 0.025f;
    gray += valuetNoise3D(_u * 32.554f, _v * 32.354f, _w * 32.430f) * 0.025f;
      
    // Output to screen
    glFragColor = vec4(vec3(gray),1.0);
}
