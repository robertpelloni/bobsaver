#version 420

// original https://neort.io/art/c3h9aqs3p9f8s59bg0b0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define t time
#define r resolution
#define FC gl_FragCoord
#define o glFragColor

vec3 hsv(float h, float s, float v) {
    vec4 a = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(vec3(h) + a.xyz) * 6.0 - vec3(a.w));
    return v * mix(vec3(a.x), clamp(p - vec3(a.x), 0.0, 1.0), s);
}

float fsnoise(vec2 c) {
    return fract(sin(dot(c, vec2(12.9898, 78.233))) * 43758.5453);
}

void main(void) {
    vec3 R;
    R.xz-=t;
    R.z+=.5;
    float d=1.,c=0.;
    for(int i=0;i<99;i++){
        c++;
        if(d<1e-4)break;
        d=min(.3-abs(R.y),length(fract(R.zx)-.5)-.15);
        R+=normalize(vec3((FC.xy*2.-r)/r.y,1))*d;
    }
    R*=9.;
    o.rgb=hsv(fsnoise(ceil(R.y)-ceil(R.zx)+ceil(t*9.)),.7,1.);
    R=.5-abs(fract(R)-.5);
    o*=min(min(R.x,R.z),R.y)/c*70.;
    o.w=1.;
}
