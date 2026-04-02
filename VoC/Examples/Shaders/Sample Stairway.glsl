#version 420

// original https://neort.io/art/c455n3s3p9ffolj04rl0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define t time
#define r resolution
#define FC gl_FragCoord
#define o glFragColor

#define X rotate2D

mat2 rotate2D(float a) {
    return mat2(cos(a), sin(a), -sin(a), cos(a));
}

void main(void) {
    vec3 P,Q,R;
    P.z=4.;
    P.zx*=X(t*.2);
    R=normalize(vec3((FC.xy*2.-r)/r.y,-1));
    R.zx*=X(t*.2);
    float d=1.;
    for(int i=0;i<99;i++){
        if(d<1e-4)break;
        Q=P;
        Q.yz*=X(.8);
        Q.z=fract(Q.z-t*2.)-.5;
        Q.zx=abs(Q.zx);
        d=Q.y+Q.z;
        P+=R*(d=max(Q.x-3.,(max(d,-d)-.5)/1.4))*.4;
        o+=exp(-d)*.01;
    }
    o.w=1.;
}
