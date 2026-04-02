#version 420

// original https://neort.io/art/c4fj8dc3p9ffolj064n0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define t time
#define r resolution
#define FC gl_FragCoord
#define o glFragColor

#define D dot(sin(Q),cos(Q.yzx))+1.3

const float PI = acos(-1.);

mat3 rotate3D(float angle, vec3 axis) {
    vec3 n = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float r = 1.0 - c;
    return mat3(
        n.x * n.x * r + c,
        n.x * n.y * r - n.z * s,
        n.z * n.x * r + n.y * s,
        n.x * n.y * r + n.z * s,
        n.y * n.y * r + c,
        n.y * n.z * r - n.x * s,
        n.z * n.x * r - n.y * s,
        n.y * n.z * r + n.x * s,
        n.z * n.z * r + c
    );
}

void main(void) {
    vec3 P,Q;
    P.z=t*2.;
    float d=1.,c=0.;
    for(int i=0;i<99;i++){
        c++;
        if(d<5e-4)break;
        Q=P;
        d=D;
        Q.x+=PI;
        d=min(d,D);
        P+=normalize(vec3((FC.xy*2.-r)/r.y,1))*rotate3D(t*.2,vec3(5,2,3))*d*.5;
    }
    if(D<.1)o.x=.5;
    else o.b=.5;
    P.z-=t*2.;
    o+=15./c+dot(P,P)*1e-3;
    o.w=1.;
}
