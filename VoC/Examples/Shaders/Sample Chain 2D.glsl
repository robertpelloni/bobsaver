#version 420

// original https://neort.io/art/c0dtqck3p9f30ks5b0hg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define t time
#define r resolution
#define FC gl_FragCoord
#define o glFragColor

#define D(V)length(vec2(length(V.xy)-.3,V.z))-.05

void main(void) {
    vec3 R=vec3(t,t,5),Q;
    float c=0.,d=1.;
    for(int i=0;i<99;i++){
        if(d>1e-4){
            Q=R;
            Q.xy=abs(fract(Q.xy)-.5);
            Q=Q.y>Q.x?Q.yxz:Q;
            d=D(Q);
            Q.x-=.5;
            d=min(d,D(Q.xzy));
            R+=normalize(vec3((FC.xy*2.-r)/r.y,-2))*d;
            c++;
        }
    }
    o.rgb+=9./c;
    o.w=1.;
}
