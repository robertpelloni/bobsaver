#version 420

// original https://www.shadertoy.com/view/flX3WS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* Returns value in range [0.0f; 1.0f]. */
float sampleHashUI32(
    const uint x,
    const uint y,
    const uint enthropy0,
    const uint enthropy1,
    const uint enthropy2)
{
    uint value = y * enthropy2 + x;

    value += enthropy1;
    value *= 445593459u;
    value ^= enthropy0;

    // 1.0f / 4294967295.0f = 2.32830644e-10

    return float(value * value * value) * 2.32830644e-10;
}

float WorleyNoise2D(float u, float v)
{
    // Fractial part.
    float fractU = u - floor(u);
    float fractV = v - floor(v);

    // Integer part.
    u = floor(u);
    v = floor(v);

    float minDistance = 3.40282347e+37f; // FL_MAX = 3.40282347e+38f

    for (float y = -1.0f; y < 2.0f; y += 1.0f)
    {
        for (float x = -1.0f; x < 2.0f; x += 1.0f)
        {
            // Pseudorandom sample coordinates in corresponding cell.
            float xSample = x + sampleHashUI32(uint(u + x), uint(v + y), 2347u, 3456u, 17948u);
            float ySample = y + sampleHashUI32(uint(u + x), uint(v + y), 234u, 3456u, 1948u);

            // Distance from pixel to pseudorandom sample.
            float _distance = 
                sqrt(
                    (fractU - xSample) * (fractU - xSample) +
                    (fractV - ySample) * (fractV - ySample));

            // Mistance from pixel to pseudorandom sample.
            minDistance = min(minDistance, _distance);
        }
    }

    return minDistance;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv;
    
    if (gl_FragCoord.xy.x < resolution.x * 0.5) { uv = gl_FragCoord.xy/resolution.xy * 6.0f; }
    else { uv = gl_FragCoord.xy/resolution.xy * 18.0f; }

    float _u = uv.x + time * 0.1f;
    float _v = uv.y + time * 0.2f;

    float gray = WorleyNoise2D(_u, _v) * 0.5f;
    gray += WorleyNoise2D(_u * 2.054f, _v * 2.210f) * 0.25f;
    gray += WorleyNoise2D(_u * 4.554f, _v * 4.710f) * 0.125f;

    // Output to screen
    glFragColor = vec4(vec3(gray),1.0);
}
