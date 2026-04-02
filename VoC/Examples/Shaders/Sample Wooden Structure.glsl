#version 420

// original https://neort.io/art/ca2eegc3p9fbkmo5qc30

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define t time
#define r resolution
#define FC gl_FragCoord
#define o glFragColor

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
    vec3 P,Q;
    P.z=t;
    float d=1.,a,c;
    for(int i=0;i<100;i++){
        c++;
        if(d<1e-4)break;
        d=dot(sin(P),cos(P.yzx))+1.2;
        a=1.;
        for(float j=1.;j<10.;j++)Q=(P+fract(sin(j)*3e3)*9.)*a,Q+=sin(Q*1.05)*2.,Q=sin(Q),d+=Q.x*Q.y*Q.z/a*.4,a*=2.;
        P+=normalize(vec3((FC.xy*2.-r)/r.y,1))*rotate3D(t*.2,vec3(1))*d*.4;
    }
    o+=12./c;
    o.a=1.;
}
