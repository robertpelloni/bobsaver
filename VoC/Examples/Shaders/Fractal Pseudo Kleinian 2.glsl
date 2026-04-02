#version 420

// original https://neort.io/art/c4a04oc3p9ffolj05e50

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define t time
#define r resolution
#define FC gl_FragCoord
#define o glFragColor

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
    vec3 P=vec3(t/4.,.38,t),Q;
    float d=1.,a,c=0.;
    for(int i=0;i<99;i++){
        c++;
        if(d<1e-4)break;
        Q=abs(mod(P,1.8)-.9);
        a=1.;
        for(int j=0;j<9;j++){
            Q=2.*clamp(Q,-.9,.9)-Q;
            d=dot(Q,Q);
            Q/=d;
            a/=d;
        }
        P+=normalize(vec3((FC.xy*2.-r)/r.y,2))*rotate3D(t*.1,vec3(1,2,5))*(d=Q.y/a/3.);
    }
    o.rg=vec2(25,20)/c;
    o.w=1.;
}
