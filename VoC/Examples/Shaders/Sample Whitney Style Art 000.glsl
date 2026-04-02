#version 420

// original https://www.shadertoy.com/view/XldyRl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//-------------------------------------------------------
/*
    Whitney Style Art attempt
*/
#define TWO_PI 6.28318530718

//-------------------------------------------------------
float distLine(vec2 p, vec2 a, vec2 b) {
    vec2 ap = p - a;
    vec2 ab = b - a;
    float t = clamp(dot(ap, ab)
        / dot(ab, ab), 0., 1.);
    return length(ap - ab * t);
}

//-------------------------------------------------------
float line(vec2 p, vec2 a, vec2 b, float t) {
    return smoothstep(t, t + .025,
        distLine(p, a, b));
}

//-------------------------------------------------------
float circle(vec2 p, vec2 l, float t) {
    return smoothstep(t, t + .025, length(p - l));
}

//-------------------------------------------------------
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

//-------------------------------------------------------
void main(void) {
    vec2 I = gl_FragCoord.xy;
    vec4 O = glFragColor;
    float T = time;
    vec2  R = resolution.xy;
    vec2 uv = (2. * I - R) / R.y;
    vec2  M = .8 + mouse*resolution.xy.xy / R;
    float t = 0.;
    const float amount = 32.;
    const float stp = 1. / amount;
    vec3 color = vec3(0.);
    for (float i = 0.; i < 1.; i += stp) {
        float ampA1 = .8;
        float phaseA1 = i * TWO_PI * M.x;
        float ampA2 = .8;
        float phaseA2 = i * TWO_PI * M.y * .25;
        float ampB1 = .8;
        float phaseB1 = i * TWO_PI * M.x * .25;
        float ampB2 = .8;
        float phaseB2 = i * TWO_PI * M.y;
        vec2 a = vec2(ampA1 * cos(T + phaseA1),
            ampA2 * sin(T + phaseA2));
        vec2 b = vec2(ampB1 * cos(T + phaseB1),
            ampB2 * sin(T + phaseB2));
        t = .1 / line(uv, a, b, .004);
        color += mix(vec3(1., 0., 0.), vec3(0., .3, .9), (t / amount));
        t = .1 / circle(uv, a, .03 * i);
        color += (t / amount) * vec3(0., 0., 1.);
        t = .1 / circle(uv, b, .03 * i);
        color += (t / amount) * vec3(1., .5, 0.);
    }
    O = vec4(color, 1.);
    glFragColor = O;
}
