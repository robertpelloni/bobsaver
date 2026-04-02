#version 420

// original https://www.shadertoy.com/view/NdcGzN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define M_PI 3.14159
const vec2 res = vec2(800.0, 600.0);

float psin(float x)
{
    return sin(x) * 0.5 + 0.5;
}

float pcos(float x)
{
    return cos(x) * 0.5 + 0.5;
}

float rsin(vec2 uv, vec2 c, float freq)
{
    return psin(length(uv - c) * freq);
}

float rcos(vec2 uv, vec2 c, float freq)
{
    return pcos(length(uv - c) * freq);
}
vec3 hsv2rgb(in vec3 c)
{
  vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 plasma_color(float n)
{
    return hsv2rgb(vec3(n, 0.66, 1.9));

    /* float t = n * M_PI * 2.0;
    return vec3(pcos(t), psin(t), 1.0 - pcos(t)); */
}

void main(void)
{
    float aspect = resolution.x / resolution.y;

    vec2 uv = gl_FragCoord.xy/resolution.xy * vec2(aspect, 1.0);

    float plasma = rcos(uv + psin(uv.y * 3.0 * cos(time)) * 0.3, vec2(0.2, 0.4), 8.0);
    plasma += psin(uv.x * 4.0 + pcos(uv.y * 3.0) + rsin(uv, vec2(0.8, 0.6), 8.0) * 6.0 * sin(time));
    plasma += pcos(uv.y * 6.0 + psin(uv.x * 1.5));
    plasma += psin(uv.x * uv.y * 5.0 * sin(cos(time * 0.4))) * 3.0;

    glFragColor.rgb = plasma_color(plasma);
    glFragColor.a = 1.0;
}
