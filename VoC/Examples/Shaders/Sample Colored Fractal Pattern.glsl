#version 420

// original https://www.shadertoy.com/view/Nl3SWM

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// magicBox by dgreensp o_O => https://www.shadertoy.com/view/4ljGDd

#define time (time*0.19 + date.w*0.21)
#define seed floor(time)
#define magic (Hash(seed) * 0.5 + inversesqrt(fract(time))*0.002 + 0.5)
#define super (Hash(seed + 1.0) + 1.5)
#define amaze (Hash(seed + 2.0)*0.7 + 0.3)

float Hash(float h) {
    return fract(sin(h) * 43758.5453);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy - 0.5;
    uv.x *= resolution.x/resolution.y;
    uv *= 1.4;
    vec3 col;

    uv = 0.5 - fract(uv);
    float lL = length(uv);
    
    for (float i=0.0; i<5.0; i++) {
        uv = abs(uv) / pow(lL, super) - magic;
        float nL = length(clamp(uv, - amaze, 1.0));
        col = max(col, abs(nL - lL));
        col *= 1.0 - vec3( Hash(seed+0.1+i), Hash(seed+0.2+i), Hash(seed+0.3)) * 0.25;
        lL = nL;
    }

    glFragColor = vec4(col, 1.0);
}
