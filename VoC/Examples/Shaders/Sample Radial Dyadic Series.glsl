#version 420

// original https://www.shadertoy.com/view/4l2SRW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int num_samples = 4 * 3 * 5;

float FoldedRadicalInverse(int n, int base)
{
    float inv_base = 1.0 / float(base);
    float inv_base_i = inv_base;
    float val = 0.0;
    int offset = 0;

    for (int i = 0; i < 8; ++i)
    {
        int div = (n + offset) / base;
        int digit = (n + offset) - div * base;
        val += float(digit) * inv_base_i;
        inv_base_i *= inv_base;
        n /= base;
        offset++;
    }

    return val;
}

float imageFunc(vec2 p, float t)
{
    float r2 = dot(p, p);
    if (r2 >= 1.0) return 0.0;

    float pi_inv = 0.31830988618379067153776752674503;
    float offset = sin(t) * 4.0;
    float freq = exp2(1.0 + floor(r2 * 9.0));
    float a = mod(atan(p.y, p.x) * pi_inv * freq + offset, 2.0);

    float f = step(1.0, a);
    //float k = 0.005;
    //float f = smoothstep(1.0 - k * 2.0, 1.0, a - k);
    return f;
}

void main(void)
{
    const float pixel_r = 1.165;//002412;
    const float pixel_norm = 1.0 / (3.1415926535897932384626433832795 * pixel_r * pixel_r);
    float s = 0.0;
    float w_sum = 0.0;
    for (int i = 0; i < num_samples; ++i)
    {
        float a = FoldedRadicalInverse(i, 3) * 6.283185307179586476925286766559;
        float r = sqrt(FoldedRadicalInverse(i, 5)) * pixel_r;
        vec2 pixel_aa = vec2(cos(a), sin(a)) * r;
        float pixel_w = max(0.0, pixel_r - r);

        float time_aa = FoldedRadicalInverse(i, 2) * 0.03333 * 1.0;

        vec2 uv = (gl_FragCoord.xy + pixel_aa - resolution.xy * 0.5) / (resolution.x * 0.275);

        float t = time + time_aa;

        s += imageFunc(uv, t) * pixel_w;
        w_sum += pixel_w;
    }
    s *= (1.0 / w_sum); //pixel_norm;// / float(num_samples);
    s = pow(s, 1.0 / 2.2);

    glFragColor = vec4(s, s, s, 1.0);
}
