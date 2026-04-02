#version 420

// original https://neort.io/art/c3apdlk3p9f8s59bevv0

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
    R.z-=2.5;
    float d=1.,c=0.;
    for(float i=0.;i<99.;i++){
        if(d<1e-4)break;
        Q=R*rotate3D(t,vec3(1));
        for(float j=0.;j<5.;j++){
            Q=(abs(Q)-vec3(.4,.5,.3))*2.*rotate3D(t,vec3(3,5,9));
        }
        d=length(max(abs(Q)-1.,0.))/32.;
        R+=normalize(vec3((FC.xy*2.-r)/r.y,2))*d;
        c++;
    }
    o.rgb=(9.-sin(Q)*4.5)/c;
    o.w=1.;
}
