#version 420

// original https://neort.io/art/c3s48dc3p9f8s59bhlpg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define t time
#define r resolution
#define FC gl_FragCoord
#define o glFragColor

const float PI = acos(-1.);

mat2 rotate2D(float a) {
    return mat2(cos(a), sin(a), -sin(a), cos(a));
}

vec3 hsv(float h, float s, float v) {
    vec4 a = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(vec3(h) + a.xyz) * 6.0 - vec3(a.w));
    return v * mix(vec3(a.x), clamp(p - vec3(a.x), 0.0, 1.0), s);
}

void main(void) {
    vec2 p=(FC.xy*2.-r)/r.y*4.1,q;
    p.y+=3.;
    o+=1.;
    float i,d=1e5,T=(1.-pow(sin(t*3.)*.5+.5,3.))*PI/4.;
    for(float i=1.;i<=30.;i++){
        q=abs(p);
        d=max(q.x,q.y);
        p.x=abs(p.x);
        p-=(1.+tan(T))/2.;
        p.y-=1.;
        p*=rotate2D(-T)*cos(T)*2.;
        if(d<1.)o.rgb=hsv(i/7.,.7,1.)*(1.5-d);
    }
}
