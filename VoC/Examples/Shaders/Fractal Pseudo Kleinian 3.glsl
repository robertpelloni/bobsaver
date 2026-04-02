#version 420

// original https://neort.io/art/c4a0iuc3p9ffolj05ebg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define t time
#define r resolution
#define FC gl_FragCoord
#define o glFragColor

mat2 rotate2D(float a) {
    return mat2(cos(a), sin(a), -sin(a), cos(a));
}

void main(void) {
    vec3 P,Q,R=normalize(vec3((FC.xy*2.-r)/r.y,-2));
    P.z+=1.5;
    P.zx*=rotate2D(t*.1);
    R.zx*=rotate2D(t*.1);
    P.y+=.5;
    float d=1.,a;
    for(int i=0;i<99;i++){
        if(d<1e-4)break;
        Q=abs(P);
        a=1.;
        for(int j=0;j<9;j++){
            Q=2.*clamp(Q,-.9,.9)-Q;
            d=dot(Q,Q);
            Q/=d;
            a/=d;
        }
        P+=R*(d=(Q.x+Q.z-.6)/a/3.);
        o+=exp(-d)*.015;
    }
    o.w=1.;
}
