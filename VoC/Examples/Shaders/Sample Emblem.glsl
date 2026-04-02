#version 420

// original https://neort.io/art/c3bcg443p9f8s59bf2d0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define t time
#define r resolution
#define FC gl_FragCoord
#define o glFragColor

float fsnoise(vec2 c) {
    return fract(sin(dot(c, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 hsv(float h, float s, float v) {
    vec4 t = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(vec3(h) + t.xyz) * 6.0 - vec3(t.w));
    return v * mix(vec3(t.x), clamp(p - vec3(t.x), 0.0, 1.0), s);
}

void main(void) {
    vec2 p=FC.xy/r.y*4.+t,I=floor(p/4.);
    p=mod(p,4.)-2.;
    float c=0.;
    for(int i=0;i<9;i++){
        c++;
        p=abs(p)-1.;
        p/=dot(p,p);
        if(length(p)<1.)break;
    }
    o.rgb=hsv(fsnoise(I+c*.1),1.,1.)/abs(sin(max(p.x,p.y)*5.))/c;
    o.w=1.;
}
