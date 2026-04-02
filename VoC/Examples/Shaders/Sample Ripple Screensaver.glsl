#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/Wd3SWS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 hash(float n) {
    return floor(vec2(fract(sin(n)*138.5453123), fract(sin(n)*832.83037595)) * 7.) / 7.;
}

float rippleValue(float n, vec2 uv) {
    vec2 params = hash(n + 0.3859903);
    params.x = params.x * 0.1 + 0.01;
    float ripple = floor(time * params.x + 10.);
    float distance = length(uv - hash(ripple * n) * vec2(resolution.x/resolution.y, 1.0));
    float peak = fract(time * params.x) * 2.0;
    float spread = peak * 0.1;
    return pow((smoothstep(peak-spread, peak, distance) - smoothstep(peak, peak+spread, distance)), 0.2) / pow(peak, 0.8);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.yy;
    vec3 value = vec3(0.);
    for (int i = 0; i < 20; i++) {
        float v = rippleValue(float(i), uv);
        value += vec3(v, v * 0.5, 0.);
        if (i % 6 == 0) value = value.xzy;
        if (i % 6 == 1) value = value.zyx;
        if (i % 6 == 2) value = value.yxz;
        if (i % 6 == 3) value = value.zxy;
        if (i % 6 == 3) value = value.yzx;

    }
    glFragColor = vec4(vec3(value*0.1), 1.0);
}
