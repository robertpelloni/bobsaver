#version 420

// original https://www.shadertoy.com/view/Xl3yzl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.1415926535;
const float SC = 400.;
const float Q = 0.1;

mat2 rotate2d(float _angle)
{
    return mat2(cos(_angle), -sin(_angle),
                sin(_angle), cos(_angle));
}

vec3 grid(vec2 uv, vec2 pos)
{
    float v = max(sin(pos.x), cos(pos.y));
    float shade = 0.25*(2.+sin(Q*uv.x))
                    *(2.+sin(Q*uv.y));
    return vec3(v*shade, v*(shade-1.), 0.);
}

vec2 warp(vec2 pos)
{
    const float A = 5.;
    float TSC = 0.3 * time;
    vec2 T = vec2(-50.*TSC, 20.*sin(TSC));
    vec2 uwave = vec2(sin(Q*pos.y), sin(Q*pos.x));
    return pos + A*uwave + T;
}

void main(void)
{
    float mx = max(resolution.x, resolution.y);
    vec2 uv = gl_FragCoord.xy / mx;
    
    float val = 0.0;
    mat2 m = mat2(1.);
    
    vec3 rgb = grid(SC*uv, warp(SC*uv));
    glFragColor = vec4(rgb, 1.0);
}
