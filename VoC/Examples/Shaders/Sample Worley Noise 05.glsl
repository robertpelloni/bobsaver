#version 420

// original https://www.shadertoy.com/view/Ntf3WS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* Returns value in range [0.0f; 1.0f]. */
float sampleHashUI32(
    const uint x,
    const uint y,
    const uint z,
    const uint enthropy0,
    const uint enthropy1,
    const uint enthropy2,
    const uint enthropy3)
{
    uint value = z * enthropy3 * enthropy2 + y * enthropy2 + x;

    value += enthropy1;
    value *= 445593459u;
    value ^= enthropy0;

    // 1.0f / 4294967295.0f = 2.32830644e-10

    return float(value * value * value) * 2.32830644e-10;
}

float WorleyNoise3D(float u, float v, float w)
{
    // Fractial part.
    float fractU = u - floor(u);
    float fractV = v - floor(v);
    float fractW = w - floor(w);

    // Integer part.
    u = floor(u);
    v = floor(v);
    w = floor(w);

    float minDistance = 3.40282347e+37f; // FL_MAX = 3.40282347e+38f

    for (float z = -1.0f; z < 2.0f; z += 1.0f)
    {
        for (float y = -1.0f; y < 2.0f; y += 1.0f)
        {
            for (float x = -1.0f; x < 2.0f; x += 1.0f)
            {
                // Pseudorandom sample coordinates in corresponding cell.
                float xSample = x + sampleHashUI32(uint(u + x), uint(v + y), uint(w + z), 2347u, 3456u, 17948u, 4591u);
                float ySample = y + sampleHashUI32(uint(u + x), uint(v + y), uint(w + z), 234u, 3456u, 1948u, 9991u);
                float zSample = z + sampleHashUI32(uint(u + x), uint(v + y), uint(w + z), 2334u, 34516u, 19048u, 398u);

                // Distance from pixel to pseudorandom sample.
                float _distance = 
                    sqrt(
                        (fractU - xSample) * (fractU - xSample) +
                        (fractV - ySample) * (fractV - ySample) +
                        (fractW - zSample) * (fractW - zSample));

                // Mistance from pixel to pseudorandom sample.
                minDistance = min(minDistance, _distance);
            }
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

    float _u = uv.x;
    float _v = uv.y;
    float _w = uv.x + time * 0.2f;

    float gray = WorleyNoise3D(_u, _v, _w) * 0.5f;
    gray += WorleyNoise3D(_u * 2.054f, _v * 2.210f,  _w * 2.210f) * 0.055f;
    gray += WorleyNoise3D(_u * 4.554f, _v * 4.710f,  _w * 2.210f) * 0.0325f;

    // Output to screen
    glFragColor = vec4(vec3(gray),1.0);
}
