#version 420

// original https://neort.io/art/c41bb0k3p9ffolj04a70

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

const float PI = acos(-1.);

mat2 rotate2D(float a) {
    return mat2(cos(a), sin(a), -sin(a), cos(a));
}

void main(void) {
    vec3 R=vec3(0,3,9),Q;
    float d=1.,a,c=0.;
    for(int i=0;i<99;i++){
        c++;
        if(d<1e-4)break;
        Q=R;
        Q.zx*=X(t*.5);
        d=a=1.;
        for(int j=0;j<9;j++){
            Q.xz=abs(Q.xz)*X(PI/4.);
            d=min(d,max(length(Q.zx)-.3,Q.y-.4)/a);
            Q.yx*=X(.5);
            Q.y-=3.;
            Q*=1.8;
            a*=1.8;
        }
        R+=vec3((FC.xy-r*.5)/r.y,-1)*d;
    }
    o+=20./c;
    o.w=1.;
}
