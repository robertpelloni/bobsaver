#version 420

// original https://neort.io/art/c3bd3lk3p9f8s59bf39g

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

float fsnoise(vec2 c) {
    return fract(sin(dot(c, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 hsv(float h, float s, float v) {
    vec4 t = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(vec3(h) + t.xyz) * 6.0 - vec3(t.w));
    return v * mix(vec3(t.x), clamp(p - vec3(t.x), 0.0, 1.0), s);
}

void main(void) {
    vec2 p=(FC.xy*2.-r)/r.y,q;
    float L,n,T=t*9.;
    for(float i=0.;i<99.;i++){
        L=1.-fract(T)+i;
        n=fsnoise(vec2(floor(T)+i))*PI2;
        q=ceil((p/atan(.5,L)/5.+vec2(cos(n),sin(n))*9.)*5.)/5.;
        if(o.x==0.)o.rgb=hsv(n,.7,1.)*step(1.3,fsnoise(q+n*.05)-sin(q.x)*sin(q.y)-length(q)*.05)*exp(-L*.02);
    }
    o.w=1.;
}
