#version 420

// original https://neort.io/art/c41b7js3p9ffolj04a10

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
    vec3 R=vec3(0,-1.4,3),Q;
    float d=1.,a;
    for(int i=0;i<99;i++){
        if(d<1e-4)break;
        Q=R;
        Q.zx*=X(t*.1);
        d=a=1.5;
        for(int j=0;j<9;j++){
            Q.xz=abs(Q.xz)*X(.785);
            d=min(d,(Q.x+Q.y*.5)/1.12/a);
            Q*=2.;
            Q.x-=3.;
            Q.y+=1.5;
            Q.yx*=X(.3);
            a*=2.;
        }
        R+=vec3((FC.xy-r*.5)/r.y,-1)*d;
        o+=exp(-d)*.02;
    }
    o.w=1.;
}
