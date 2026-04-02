#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define BITS 10

float xor(float a, float b) {
    float mask = pow(2.0, float(BITS));
    float c = 0.0;

    if (a < 0.0) a = mask - a;
    if (b < 0.0) b = mask - b;

    for (int i = 0; i < BITS; i++) {
        mask *= 0.5;
        c *= 2.0;
        c += mod(floor(a / mask) + floor(b / mask), 2.0);
    }

    return c;
}

void main( void ) {
    vec2 p = gl_FragCoord.xy / resolution;
    vec2 p2 = (gl_FragCoord.xy + vec2(0, -1)) / resolution;

    vec3 color = texture2D(backbuffer, p2).rgb;

    if (gl_FragCoord.y < 1.0) {
        float x = floor(gl_FragCoord.x);
        float t = floor(time * 60.0);
        float a = xor(x - t, x + t);
        float c = (mod(abs(t + a*a*a), 997.0) < 97.0) ? 1.0 : 0.25;
        color = vec3(0, c, 0);
    }

    glFragColor = vec4(color, 1);
}
