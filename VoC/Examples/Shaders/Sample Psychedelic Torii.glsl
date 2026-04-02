#version 420

// original https://www.shadertoy.com/view/tdy3Wh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 screenUV(vec2 uv) {
    uv /= resolution.xy;
    uv -= 0.5;
    uv.x *= resolution.x / resolution.y;
    return uv;
}

float csin(float x)
{
    return (sin(x) + 1.) * 0.5;
}

vec2 xy(float a)
{
    return vec2(cos(a), sin(a));
}

void main(void)
{
    vec2 uv = screenUV(gl_FragCoord.xy);

    float d1 = length(uv + 0.01 * xy(time));
    float d2 = length(uv + 0.04 * xy(time * 1.1));
    float d3 = length(uv);
    
    float c1 = csin(43. * d1 - 2.3 * time);
    float c2 = csin(47. * d2 - 5.1 * time);
    float c3 =  sin(17. * d3 - 2.3 * time);

    glFragColor = vec4(c3 * c3 * vec3(c1, c2, 1.0 - c1 * c2), 1.0);
}
