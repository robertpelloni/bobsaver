#version 420

// original https://www.shadertoy.com/view/wlKBWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Author: paperu
// Title: minimalist starfield

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

#define P 6.28318530717958

float b(in vec2 p, in float s, in float r) { return length(abs(p) - s) - r; }
mat2 rot(in float a){ return mat2(cos(a),sin(a),-sin(a),cos(a)); }
float asympt(float x, float sp) { return x/(sp + x); }

void main(void) {
    vec2 st = (gl_FragCoord.xy - .5*resolution.xy)/resolution.y;
    float t = time*.25;
    vec2 m = ((mouse*resolution.xy.xy - resolution.xy*.5)/resolution.y) + vec2(cos(.5*t),sin(.5*t))*.5;
    float sz = 8.*(1. - m.y*.5);
    float aa = sz/resolution.y;
    float tB = clamp(asympt(time - 1., 3.),0.,1.);

    vec2 p = st + m*.5;
    p *= rot(P*.125 + m.y*P*.125);
    vec2 pF = floor(p*sz);
    p = fract(p*sz) - .5;
    p *= rot(pF.x*P*.333);
    p = abs(p) - .042;
    float d = b(p,.4*tB - (.5+.5*cos(length(pF)*10.5 - t))*.5,.05);
    d = smoothstep(-aa,aa,abs(d) - aa*.25);
    
    glFragColor = vec4(mix(vec3(0.023),vec3(1.),1.-d),1.);
}
