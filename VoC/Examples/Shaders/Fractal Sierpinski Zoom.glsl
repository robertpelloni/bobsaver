#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;
#define r3 1.7320508

void main (void) {
    vec2 p = (gl_FragCoord.xy) / min(resolution.x, resolution.y);
    p = mat2(1., 0, -r3 / 3., 1. /(0.5 * r3)) * p;
    float u = 2. / r3;
    p /= u * pow(2., fract(time));

    float c = 1.;
    float z = 1.;
    for (int i = 0; i < 9; i++) {
        p = mod(p, z);
        c *= (1. - step(z, p.x +p.y));
        z *= 0.5;
    }

    c *= step(0., p.x);

    glFragColor = vec4(c, c, c, 1.0);
}
