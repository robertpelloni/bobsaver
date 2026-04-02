#version 420

// original https://neort.io/art/c41bf3s3p9ffolj04afg

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
    vec3 P,R=normalize(vec3((FC.xy*2.-r)/r.y,-2)),Q;
    P.z+=3.;
    float d,a;
    for(int i=0;i<99;i++){
        Q=P;
        Q.yz*=rotate2D(t);
        d=a=1.;
        for(int j=0;j<9;j++){
            Q=abs(Q);
            d=min(d,(length(Q)-.5)/a);
            Q.xy*=rotate2D(.5);
            Q.x-=1.;
            Q*=2.;
            a*=2.;
        }
        P+=R*min(d,P.y+1.5);
        if(i==50){
            R=vec3(.577);
            P+=R*.01;
        }
    }
    o+=P.z*.04;
    o.w=1.;
}
