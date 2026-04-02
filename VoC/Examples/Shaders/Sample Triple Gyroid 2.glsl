#version 420

// original https://neort.io/art/c4oul8c3p9ffolj08570

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define t time
#define r resolution
#define FC gl_FragCoord
#define o glFragColor

#define D (dot(sin(Q),cos(Q.yzx))+1.3)

const float PI = acos(-1.);

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
    float d=1.,c;
    for(int i=0;i<150;i++){
        c++;
        if(d<1e-4)break;
        Q=P;
        d=D;
        Q.x+=PI;
        d=min(d,D);
        Q.y+=PI;
        d=min(d,D);
        Q*=30.;
        d=max(abs(d),(abs(D-1.3)-.5)/30.);
        P+=normalize(vec3((FC.xy*2.-r)/r.y,1))*rotate3D(t*.2,vec3(5,3,1))*d*.6;
    }
    o+=30./c;
    o.a=1.;
}
