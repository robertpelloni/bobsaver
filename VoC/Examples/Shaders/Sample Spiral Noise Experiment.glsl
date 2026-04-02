#version 420

// original https://www.shadertoy.com/view/XsfcWj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fractal-layered rotated 2d triangle-wave noise (adapted from octaviogood's sin-noise 
// function in Duke's awesome https://www.shadertoy.com/view/lsyXDK ) with cosine color 
// palette courtesy IQ: http://www.iquilezles.org/www/articles/palettes/palettes.htm
void main(void) {
    float t, a, n, i = 2.;
    vec2 p = .6 * (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    t = .03 * time + .5;
    a = mod(t, 6.283);
    n = 1.5 + .5 * cos(9. * t);
    for (int j = 0; j < 16; j++) {
        p = p * cos(a) + vec2(-p.y, p.x) * sin(a); // rotate by a
        vec2 f = abs(-.5 + fract(p*i)) / i; // 2d triangle waves
        n -= f.x + f.y;
        i *= 1.23;
    }
    n = smoothstep(.2, 1., 1.-n);
    glFragColor.rgb = .5 + .5 * cos(6.283 * (vec3(.3, .1, 0.) + n + t));
}
