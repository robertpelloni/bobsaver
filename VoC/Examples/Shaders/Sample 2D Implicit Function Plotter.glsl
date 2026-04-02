#version 420

// original https://www.shadertoy.com/view/WlVcWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define CONTOUR_SPACING 1.0
#define CONTOUR_THICKNESS 2.0
#define DELTA 0.001

// Hue to RGB function from Fabrice's shadertoyunofficial blog:
#define hue2rgb(hue) 0.6 + 0.6 * cos(6.3 * hue + vec3(0.0, 23.0, 21.0))

float f(in vec2 p) {
    p *= 3.0;
    vec3 p3 = vec3(p, time);
    return dot(sin(p3), cos(p3.zxy));
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y * 4.0;
    float unit = CONTOUR_THICKNESS / resolution.y * 4.0;

    float hSpacing = 0.5 * CONTOUR_SPACING;
    float fRes = f(uv);

    #ifdef USE_HARDWARE_DERIVATIVES
    float grad = length(fwidth(fRes)) * resolution.y / 5.0;

    #else
    float grad = length(vec2(f(uv + vec2(DELTA, 0.0)) - f(uv - vec2(DELTA, 0.0)),
                             f(uv + vec2(0.0, DELTA)) - f(uv - vec2(0.0, DELTA)))) / (2.0 * DELTA);
    #endif

    float contour = abs(mod(fRes + hSpacing, CONTOUR_SPACING) - hSpacing) / grad;

    glFragColor = vec4(hue2rgb(fRes * 0.5) - smoothstep(unit, 0.0, contour), 1.0);
}
