#version 420

// original https://neort.io/art/c3bbtss3p9f8s59bf1ng

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define t time
#define r resolution
#define FC gl_FragCoord
#define o glFragColor

void main(void) {
    vec3 R=vec3(.1,0,.5)*t,Q;
    float d=1.,a,b=7./3.,c=0.;
    for(float i=0.;i<99.;i++){
        if(d<1e-4)break;
        Q=mod(R,b*2.)-b;
        d=1e5,a=1.;
        for(float j=0.;j<6.;j++){
            d=min(d,length(max(abs(Q)-1.,0.))/a);
            Q=(abs(Q)-1.4)/.4;
            a/=.4;
        }
        R+=normalize(vec3((FC.xy*2.-r)/r.y,2))*d;
        c++;
    }
    o.rgb=(1.5+sin(R))*9./c;
    o.w=1.;
}
