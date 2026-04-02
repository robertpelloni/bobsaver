#version 420

// original https://neort.io/art/c4oui2s3p9ffolj084vg

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

mat3 rotate3D(float angle, vec3 axis){
    vec3 a = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float r = 1.0 - c;
    return mat3(
        a.x * a.x * r + c,
        a.y * a.x * r + a.z * s,
        a.z * a.x * r - a.y * s,
        a.x * a.y * r - a.z * s,
        a.y * a.y * r + c,
        a.z * a.y * r + a.x * s,
        a.x * a.z * r + a.y * s,
        a.y * a.z * r - a.x * s,
        a.z * a.z * r + c
    );
}

void main(void) {
    vec3 P,Q,S;
    P.z=9.;
    float d=1.,a;
    for(int i=0;i<99;i++){
        if(d<1e-4)break;
        Q=S=P*rotate3D(t,vec3(1));
        a=1.;
        for(int j=0;j<9;j++){
            Q=2.*clamp(Q,-.6,.6)-Q;
            d=clamp(dot(Q,Q),.1,1.)*.5;
            Q=Q/d+S;
            a=a/d+1.;
        }
        d=(length(Q)-9.)/a;
        P+=vec3((FC.xy-r*.5)/r.y,-1)*d;
        o.rgb+=hsv(dot(P,P)*.03,.8,min(a,5e4)*4e-6);
    }
    o.a=1.;
}
