#version 420

// original https://www.shadertoy.com/view/lsBSRd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define N 20.
void main(void) {
    float t = time;
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution) / resolution.y*2.5;
    float r = length(uv), a = atan(uv.y,uv.x);
    // r *= 1.-.1*(.5+.5*cos(2.*r*t));
    float i = floor(r*N);
    a *= floor(pow(128.,i/N));      a += 10.*t+123.34*i;
    r +=  (.5+.5*cos(a)) / N;    r = floor(N*r)/N;
    glFragColor = (1.-r)*vec4(3.,2.,1.,1.);
}
