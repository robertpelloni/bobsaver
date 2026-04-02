#version 420

// original https://neort.io/art/c3cto843p9f8s59bfdt0

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
    vec3 R=vec3(t*.5,t,0),Q;
    float d=1.,c=0.;
    for(int i=0;i<99;i++){
        c++;
        if(d<1e-4)break;
        Q=mod(R,6.)-3.;
        for(int j=0;j<5;j++){
            Q.xy=abs(Q.xy)-1.;
            Q.xy=Q.y<-Q.x?-Q.yx:Q.xy;
            Q.xy=abs(Q.xy-1.)*3.;
        }
        d=max(2.-Q.z,length(max(abs(Q)-3.,0.))/243.);
        R+=normalize(vec3((FC.xy*2.-r)/r.y,2))*d;
    }
    o.rgb+=7./c*(2.+cos(R));
    o.w=1.;
}
