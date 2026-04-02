#version 420

// original https://www.shadertoy.com/view/fdt3WN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define PI2 6.28309265359

float n21(vec2 n) {
    return fract(sin(dot(n, vec2(12.9898 + floor(1.), 4.1414))) * 43758.5453);
}

mat2 rot2d(float a) {
    return mat2(vec2(sin(a), cos(a)), vec2(-cos(a), sin(a)));
}

vec3 wheelOfFortune(vec2 uv, float segments) {
    float angle = atan(uv.y, uv.x) + time;
    float segmentAngle = PI2 / segments;
    float wid = floor((angle + PI) / segmentAngle);
    float n = n21(vec2(wid, 3.2));
    vec3 color = vec3(n, fract(n * 10.23) + sin(time + uv.y * 6.), fract(n* 123123.342) + cos(time + uv.x*6.1));
    return color;
}

vec3 background(vec2 uv) {
    vec3 color = vec3(0.);

    vec3 c1 = wheelOfFortune(uv * rot2d(time), 8.); 
    vec3 c2 = wheelOfFortune(uv + vec2(sin(time) * .1, cos(time*.3) * .1) * rot2d(-time), 15.);
    vec3 c3 = wheelOfFortune(uv - vec2(sin(time*.6) * .2, cos(time) * .2) * rot2d(-time), 15.);
    color = (c1 * c2 / c3) / 3.;

    // color /= 3.;

    return color;
}

void main(void) {

    float _SegmentCount = 7.;

    vec2 mouse = mouse*resolution.xy.xy/resolution.xy;

    vec2 shiftUV = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    float radius = sqrt(dot(shiftUV, shiftUV));
    float angle = atan(shiftUV.y, shiftUV.x) + mouse.x;

    float segmentAngle = PI2 / _SegmentCount;

    float wid = floor((angle + PI) / segmentAngle);

    angle -= segmentAngle * floor(angle / segmentAngle);

    angle = min(angle, segmentAngle - angle);

    vec2 uv = vec2(cos(angle), sin(angle)) * radius + sin(time) * 0.1;

    vec3 color = vec3(0.);

    color += background(uv);

    glFragColor = vec4(color, 1.0);
}
