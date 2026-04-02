#version 420

// original https://neort.io/art/c3ikjlc3p9f8s59bg8b0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define t time
#define r resolution
#define FC gl_FragCoord
#define o glFragColor

const float PI2 = acos(-1.)*2.;

vec3 hsv(float h, float s, float v) {
    vec4 a = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(vec3(h) + a.xyz) * 6.0 - vec3(a.w));
    return v * mix(vec3(a.x), clamp(p - vec3(a.x), 0.0, 1.0), s);
}

float fsnoise(vec2 c) {
    return fract(sin(dot(c, vec2(12.9898, 78.233))) * 43758.5453);
}

mat2 rotate2D(float a) {
    return mat2(cos(a), sin(a), -sin(a), cos(a));
}

void main(void) {
    vec3 R,Q;
    R.y+=t;
    float d=1.,n,c=0.;
    for(int i=0;i<99;i++){
        c++;
        if(d<1e-4)break;
        Q=fract(R)-.5;
        d=PI2/(ceil(n=fsnoise(ceil(R.zx)+ceil(R.y)/9.)*6.+.1)+2.);
        Q.yx*=rotate2D(ceil(atan(Q.x,Q.y)/d-.5)*d);
        d=max(Q.y-.15,abs(Q.z)-.1);
        R+=normalize(vec3((FC.xy*2.-r)/r.y,2))*d;
    }
    o.rgb=15./c*hsv(n*2e2,.7,1.);
    o.w=1.;
}
