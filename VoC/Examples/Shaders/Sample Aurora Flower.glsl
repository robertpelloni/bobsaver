#version 420

// original https://www.shadertoy.com/view/wdfSWr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float flower(float t, float a, float b, float c, float d, float f)
{   
    return (a + (b * cos(c * t)) / (d + abs(sin(f * t))));   
}

float sigma_delta(float a, float b)
{
    return 1.0 - 1.0 / (1.0 + exp(1.0 * (-abs(a - b) + 4.0)));
}

void main(void)
{
    const float flower_scale = 4.72;
    const float flower_amp = 2.0;
    const float flower_count = 20.0;
    const float flower_amp_in = 0.284;
    const float flower_count_in = 6.84;
    
    
    float k_time = sin(time * 0.5) * 0.5 + 0.5;

    vec2 pos = gl_FragCoord.xy/resolution.xy * 2.0 - 1.0;
    pos.x *= resolution.x / resolution.y;
    pos *= 32.0;
    float t = atan(pos.x, pos.y);
    float r0 = length(pos);
    float rn = 4.0;
    float rf = flower(t,
                      14.0,
                      -2.0,
                      rn * k_time,
                      0.1,
                      2.0 * rn * (1.0 - k_time));
    float gn = 6.0;
    float gf = flower(t,
                      10.0,
                      2.0,
                      gn * k_time,
                      0.2,
                      2.0 * gn * (1.0 - k_time));
    float bn = 8.0;
    float bf = flower(t,
                      6.0,
                      -3.0,
                      bn * k_time,
                      0.3,
                      2.0 * bn * (1.0 - k_time));
    vec3 clr = (sigma_delta(r0, rf) * vec3(0.75, 0.1, 0.3) +
                sigma_delta(r0, gf) * vec3(0.15, 0.5, 0.1) +
                sigma_delta(r0, bf) * vec3(0.1, 0.5, 0.4));
    glFragColor = vec4(clamp(clr, 0.0, 1.0), 1.0);
}
