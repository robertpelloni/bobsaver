#version 420

// original https://www.shadertoy.com/view/WlBcWc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    fractal configurations
    202 stb
    free code is free

    Update: removed vestiges from previous code, cleaned up some other things.
*/

#define PI 3.14159265
#define RPT(a) vec2(sin(a), cos(a))
#define T .33 * time

vec2 cInvMir(vec2 p, vec2 o, float r) {
    return length(p-o)<r ? (p-o) * r * r / dot(p-o, p-o) + o : p;
}

vec3 map(vec2 p) {
    return
        .5 + .5 * vec3(
            cos(dot(p, RPT(T))),
            cos(dot(p, RPT(T+PI/3.))),
            cos(dot(p, RPT(T-PI/3.)))
       );
}

// hash without sine
// https://www.shadertoy.com/view/4djSRW
#define MOD3 vec3(443.8975, 397.2973, 491.1871) // uv range
vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * MOD3);
    p3 += dot(p3, p3.yzx+19.19);
    return fract(vec2((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y));
}

void main(void) {
    vec2 res = resolution.xy;
    vec2 p = .5 * (gl_FragCoord.xy-res/2.) / res.y;
    
    float ball = 1. - dot(p, p);
    p /= ball;
    p += RPT(.77*T);
    
    // fractal stuff
    for(float i=0.; i<32.; i++) {
        vec2 h = mix( hash22(vec2(i, floor(T))), hash22(vec2(i, floor(T+1.))), pow(smoothstep(0., 1., fract(T)), 8.));
        p = cInvMir(.8*p, .5-h, .37);
    }
    
    glFragColor = vec4((ball*4.7-3.3) * (map(p*3.)-length(p)/4.), 1.);
}
