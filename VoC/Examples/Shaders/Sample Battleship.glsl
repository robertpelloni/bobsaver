#version 420

// original https://neort.io/art/c4oud543p9ffolj084o0

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
    vec3 P=vec3(vec2(1.4)*rotate2D(t*.2),t),Q,S;
    float d=1.,a;
    for(int i=0;i<99;i++){
        if(d<1e-4)break;
        Q=S=mod(P,10.)-5.;
        a=1.;
        for(int j=0;j<9;j++){
            Q=2.*clamp(Q,-1.,1.)-Q;
            d=max(3./dot(Q,Q),1.);
            Q=2.*Q*d+S,a=2.*a*d+1.;
        }
        d=(length(Q)-9.)/a;
        P+=normalize(vec3((FC.xy*2.-r)/r.y,1))*d;
        o.g+=a/1e6;
    }
    o.a=1.;
}
