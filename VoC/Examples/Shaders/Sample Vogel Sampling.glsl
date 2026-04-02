#version 420

// original https://www.shadertoy.com/view/wtKXzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141593
#define GOLDEN_ANGLE 2.39996

#define RADIUS 0.25
#define SAMPLE_COUNT 128.0

vec2 VogelDiskSample(in float sampleIndex, in float sampleCount, in float angleOffset)
{
    float r = sqrt(sampleIndex + 0.5) / sqrt(sampleCount);
    float theta = sampleIndex * GOLDEN_ANGLE + angleOffset;

    return vec2(r * cos(theta), r * sin(theta));
}

void main(void)
{
    vec2 center = vec2(0.5);
    vec2 uv = gl_FragCoord.xy / resolution.xy;

    uv.y *= resolution.y / resolution.x;
    center.y *= resolution.y / resolution.x;

    float result = 0.0;

    float sampleCount = SAMPLE_COUNT * (0.5 * cos(time) + 0.5);

    for (float i = 0.0; i < SAMPLE_COUNT; ++i)
    {
        vec2 pos = center + VogelDiskSample(i, SAMPLE_COUNT, cos(time)) * RADIUS;

        if (i < sampleCount)
        {
            result += pow(max(1.0 - distance(uv, pos), 0.0), 3e2);
        }
    }

    glFragColor = vec4(vec3(result), 1.0);
}
