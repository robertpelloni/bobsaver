#version 420

// original https://www.shadertoy.com/view/fsSSWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 f(in vec2 z, in vec2 w) { return z * mat2(w.x, -w.y, w.yx); }

void main(void) {
    vec2 x = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y * 2.0;
    float time = time * 0.25;
    glFragColor = vec4(0.0);

    float w1 = sin(time * 0.25);
    float w2 = sin(time) * 3.0;
    float w3 = sin(time) * 2.0;
    float w4 = cos(time * 0.75);
    float w5 = sin(time * 0.5);
    float w6 = 0.125 * sin(time);

    for (int n=0; n < 50; n++) {
        vec2 p = w1 * f(x, f(x, f(x, f(x, x)))) + w2 * f(x, f(x, f(x, x))) + w3 * f(x, f(x, x)) + w4 * f(x, x) + w5 * x + vec2(w6, 0.0);
        vec2 q = 5.0 * w1 * f(x, f(x, f(x, x))) + 4.0 * w2 * f(x, f(x, x)) + 3.0 * w3 * f(x, x) + 2.0 * w4 * x + vec2(w5, 0.0);
        x -= f(0.1 * p, 1.0 - q);
        glFragColor.rb += abs(x);
    }

    glFragColor /= 25.0;
}
