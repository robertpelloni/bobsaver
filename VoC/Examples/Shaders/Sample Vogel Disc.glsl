#version 420

// original https://www.shadertoy.com/view/tddXWl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.14159265f;
const float GoldenAngle = PI * (3.0 - sqrt(5.0));
const float PointRadius = 2.0 + 2.0/3.0;

const vec2 DropShadow = vec2(-0.25, 0.75);

vec2 Vogel(uint sampleIndex, uint samplesCount, float Offset)
{
  float r = sqrt(float(sampleIndex) + 0.5f) / sqrt(float(samplesCount));
  float theta = float(sampleIndex) * GoldenAngle + Offset;
  return r * vec2(cos(theta), sin(theta));
}

void main(void)
{
    float Size = resolution.y / 2.0;
    vec2 UV = gl_FragCoord.xy/resolution.xy;   
    vec3 Color = mix(vec3(0.75), vec3(0.5), distance(UV,vec2(0.5)));
    
    Color = mix(
        Color,vec3(0.0),
        smoothstep(PointRadius*2.0, -PointRadius*2.0, abs(Size * 0.90 - distance(gl_FragCoord.xy + DropShadow, resolution.xy/2.0)))
    );
    Color = mix(
        Color,vec3(1.0),
        smoothstep(PointRadius*2.0, -PointRadius*2.0, abs(Size * 0.90 - distance(gl_FragCoord.xy, resolution.xy/2.0)))
    );
    
    UV.x *= resolution.x / resolution.y;
    float Pulse = sin(time * 0.0125 * PI * 2.0);
    uint Samples = uint(1024.0 * Pulse * Pulse);
    
    for( uint i = 0u; i < Samples; ++i )
    {
        float Phase = float(i) / float(Samples - 1u);
        vec2 VogelPos =
            resolution.xy / 2.0
            + Vogel(i, Samples, time * 0.5)
            * Size * 0.85;
        Color = mix(
            Color,vec3(0.0),
            smoothstep(PointRadius + 1.0, PointRadius - 1.0, length((gl_FragCoord.xy + DropShadow) - VogelPos))
           );
        Color = mix(
            Color,vec3(1.0),
            smoothstep(PointRadius + 1.0, PointRadius - 1.0, length(gl_FragCoord.xy - VogelPos))
        );
    }
    
    glFragColor = vec4(Color, 1.0);
}
