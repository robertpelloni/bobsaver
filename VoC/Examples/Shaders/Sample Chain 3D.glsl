#version 420

// original https://neort.io/art/c0dturc3p9f30ks5b0mg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define t time
#define r resolution
#define FC gl_FragCoord
#define o glFragColor

#define D d=min(d,length(vec2(length(Q.zx)-.3,Q.y))-.02)

void main(void) {
    vec3 R=vec3(0),Q;
    R+=t*.5;
    float c=0.,d=1.;
    for(int i=0;i<99;i++){
        if(d>1e-4){
            Q=abs(fract(R)-.5);
            Q=Q.x>Q.z?Q.zyx:Q;
            d=9.;
            D;
            Q-=.5;
            D;
            Q.x+=.5;
            Q=Q.xzy;
            D;
            Q.z+=.5;
            Q=Q.zxy;
            D;
            R+=normalize(vec3((FC.xy*2.-r)/r.y,2))*d;
            c++;
        }
    }
    o.rgb+=9./c;
    o.w=1.;
}
