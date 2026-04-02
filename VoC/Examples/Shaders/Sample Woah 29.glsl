#version 420

// original https://www.shadertoy.com/view/3dSGRd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Different mouse controls. Possible values: 0, 1, 2
#define MOUSE 1

#define PI 3.14159265359

vec2 ToPolar(in vec2 uv)
{
    float x = atan(uv.x, uv.y);
    float y = length(uv);
    return vec2(x, y);
}

vec3 Pal(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d)
{
    return a + b*cos( PI*2.0*(c*t+d) );
}

vec3 Palette(in float x)
{
    return Pal(x, vec3(0.5, 0.5, 0.5), vec3(0.5, 0.5, 0.5), vec3(1.0, 1.0, 1.0), vec3(0.0, 0.10, 0.20));
}

void main(void)
{
    // Mobile friendly UVs
    vec2 uv = gl_FragCoord.xy/resolution.xy * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;

    vec2 pol = ToPolar(uv);
    vec2 mouse = mouse*resolution.xy.xy/resolution.xy;

    float count            = 6.0;
    float zoom            = 16.0;
    float dent_strength    = 1.1;
    float offset        = 0.85;

#if MOUSE == 1
        count            = ceil(mouse.x * 50.0) / (PI*2.0);
        zoom            = 25.0 * mouse.y;
#elif MOUSE == 2
        dent_strength     = 2.0 * (mouse.y * 2.0 - 1.0);
        offset             = 2.0 * (mouse.x * 2.0 - 1.0);
#endif
    float dent = pow(fract(count * pol.x) - 0.5, 2.0) * dent_strength;

    // Attenuate the effect over distance
    float p = (offset-dent / (pol.y + offset));

    float s = zoom * pol.y * p;

    glFragColor = vec4(Palette(s),1.0);
}
