#version 420

// original https://www.shadertoy.com/view/MlKfWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R resolution.xy
#define T time

mat2 rotate(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
}

vec2 modPolar(vec2 uv, float n) {
    float a = atan(uv.x, uv.y);
    float l = length(uv);
    n = 6.28 / n;
    a = mod(a + n * .5, n) - n * .5;
    return l * vec2(cos(a), sin(a)) - vec2(1., 0.);
}

float fractal(vec2 uv) {
    float s = .5;
    for (int i = 0; i < 8; i++) {
        uv = abs(uv) / dot(uv, uv);
        uv -= s;
        uv *= rotate(T * .1);
        s *= .9;
    }
    return .1 / length(uv);
}

vec3 render(vec2 uv) {
    uv *= 2.;
    vec3 col = vec3(0.);
    for (int i = 0; i < 4; i++)
        uv = modPolar(uv, 8.);
    col += fractal(uv);
    return col;
}

void main(void) {
    vec2 uv = (2. * gl_FragCoord.xy - R) / R.y;
    vec3 col = render(uv);
    glFragColor = vec4(col, 1.);
}
