#version 420

// original https://www.shadertoy.com/view/43y3zd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define r(a) mat2 (cos(a + vec4(0,33, 11,0)));
#define R(p, T) p.yx *= r(round((atan(p.y, p.x) + T) * 1.91) / 1.91 - T)
void main(void) {
    float i, t = 0.0, d, k = time / 8.0;
    vec2 F = gl_FragCoord.xy;
    vec4 O = vec4(0.0);
    vec2 R = resolution.xy;
    vec3 p;

    for (i = 0.0; i < 30.0; i++) {
        p = vec3(F + F - R, R.y);
        p = normalize(p) * t;
        p.z -= 3.0;
        p.xz *= r(k + 0.1);
        p.zy *= r(k + k);
        d = length(p)- sin(k + k) * .5 - 0.4;

        p.y += sin(p.x * cos(k + k) + k * 4.0) * sin(k) * 0.3;
        R(p.xy, 0.0);
        R(p.xz, k);
        p.x = mod(p.x + k * 8.0, 2.0) - 1.0;
        t += d = min(d, length(p.yz) - 0.03) * 0.5;

        O += 0.01 * (cos(t - k + vec4(0, 1, 3, 0))) / (length(p) - 0.02) + (0.025 + sin(k) * 0.01) / (0.8 + d * 24.0);
    }
    
    glFragColor=O;
}