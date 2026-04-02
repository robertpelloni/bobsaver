#version 420

// original https://www.shadertoy.com/view/4sjSRt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define N 10.
void main(void) {
    float t = time;
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution) / resolution.y*2.5;
    float r = length(uv), a = atan(uv.y,uv.x);
    float i = floor(r*N);
    a *= floor(pow(128.,i/N));      a += 20.*sin(.5*t)+123.34*i-100.*(r-0.*i/N)*cos(.5*t);
    r +=  (.5+.5*cos(a)) / N;    r = floor(N*r)/N;
    glFragColor = (1.-r)*vec4(.5,1.,1.5,1.);
}
