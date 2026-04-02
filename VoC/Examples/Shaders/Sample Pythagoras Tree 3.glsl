#version 420

// original https://neort.io/art/c4558a43p9ffolj04r20

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
    vec3 P,Q;
    P.z+=t;
    float d=1.,a;
    for(int i=0;i<99;i++){
        if(d<1e-4)break;
        Q=mod(P,8.)-4.;
        Q.y+=1.5;
        d=a=2.;
        for(int j=0;j<15;j++){
            Q.x=abs(Q.x);
            d=min(d,length(max(abs(Q)-.5,0.))/a);
            Q.xy=(Q.xy-vec2(.5,1))*rotate2D(-.785);
            Q*=1.41;
            a*=1.41;
        }
        P+=vec3((FC.xy-r)/r.y,1)*d;
        o.rgb+=exp(-d)*.01*(2.+cos(P));
    }
    o.w=1.;
}
