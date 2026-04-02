#version 420

// original https://www.shadertoy.com/view/llXGD4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// 2TC 15
// 280 chars or less (as counted by Shadertoy)

void main () {
    float m = 0., h;
    vec2 r = gl_FragCoord.xy / resolution.y - .8, T = r - r, P = T, N=vec2(0.0);
    ++r.y;
    for (int i = 0; i < 42; ++i) {
        h = cos (P.x * P.y + time) - 9.;
        if (h > m)
            break;
        m = min (T.x, T.y) * (r.y - 2.);
        N = h > m ? N - N : step (T, T.yx) * sign (r);
        T += N / r;
        P += N;
    }
    glFragColor = (.5 + .5 * vec4 (cos (P), sin (r))) * (1. - .5 * N.x - .25 * N.y);
}
