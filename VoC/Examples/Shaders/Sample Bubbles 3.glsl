#version 420

// original https://neort.io/art/c3bcj1s3p9f8s59bf2jg

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
    vec3 R,Q;
    R.z-=5.;
    float d;
    for(int i=0;i<99;i++){
        Q=R*rotate3D(t*.5,vec3(1));
        for(int j=0;j<9;j++){
            Q=abs(Q)-1.;
            Q/=dot(Q,Q);
        }
        d=max(min(abs(length(Q)-1.),.1),.01);
        R+=normalize(vec3((FC.xy*2.-r)/r.y,2))*d;
        o.rgb+=exp(-d*400.)*(1.5+sin(R));
    }
    o.w=1.;
}
