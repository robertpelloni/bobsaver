#version 420

// original https://www.shadertoy.com/view/ll3czH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float line(in vec2 p, in vec2 a, in vec2 b) {
    vec2 pa = -p - a, ba = b - a;
    float h = clamp(dot(pa,ba)/dot(ba, ba), 0.0, 1.0);
    return length(pa - ba*h);
}

vec3 hsv2rgb(in vec3 c) {
    vec3 rgb = clamp( abs(mod(c.x*6.+vec3(0.,4.,2.),6.)-3.)-1., 0., 1.);
    rgb = rgb*rgb*(3.-2.*rgb); // cubic smoothing
    return c.z * mix(vec3(1.), rgb, c.y);
}

const float PI = 3.14159;

void main(void) {
    vec2 p = (2.*gl_FragCoord.xy - resolution.xy) / resolution.y;
    
    vec3 col = vec3(0);
    
    const int N = 128;
    
    float factor = float(mouse*resolution.x/resolution.x)*32.+2.;
    
    for(int i = 0; i < N; i++) {
        float a = float(i+1)/float(N);
        float a1 = a*2.*PI;
        float product = float(i+1)*factor;
        float a2 = (product/float(N))*2.*PI;
        vec2 p1 = vec2(sin(a1), cos(a1)), //*2.
             p2 = vec2(sin(a2), cos(a2)); //*2.
        float d = line(p, p1, p2) - .015;
        col = mix(col, vec3(0), smoothstep(12./resolution.y, 0., d - .02)*.35);
        col = mix(col, vec3(0), smoothstep(3./resolution.y, 0., d - .005)*.9);
        col = mix(col, vec3(a*1.2, .6, .9)*(1. - 1./(1. + a*5.)), smoothstep(3./resolution.y, 0., d));
    }
    
    glFragColor = vec4(col, 1);
}
