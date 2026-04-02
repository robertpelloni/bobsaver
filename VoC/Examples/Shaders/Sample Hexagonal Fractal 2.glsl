#version 420

// original https://neort.io/art/c3s4uic3p9f8s59bhmc0

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
    vec3 R,Q;
    R.xy+=t*.2;
    float d=1.,a,c=0.;
    for(int i=0;i<99;i++){
        c++;
        if(d<1e-4)break;
        Q=mod(R,3.)-1.5;
        d=a=1.;
        for(int j=0;j<7;j++){
            d=min(d,(length(Q)-.5)/a);
            Q.xy*=rotate2D(ceil(atan(Q.y,Q.x)/1.05-.5)*1.05);
            Q.x-=1.;
            a*=3.;
            Q*=3.;
        }
        R+=normalize(vec3((FC.xy*2.-r)/r.y,2))*d;
    }
    o.rgb=exp(cos(R)+3.)/c;
    o.w=1.;
}
