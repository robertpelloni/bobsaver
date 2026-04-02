#version 420

// original https://neort.io/art/c3bc2i43p9f8s59bf1sg

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
    vec3 R=vec3(.1,.4,1)*t,Q;
    float d,a,b=sqrt(3.);
    for(int i=0;i<99;i++){
        Q=abs(mod(R,b*2.)-b);
        d=9.;
        a=1.;
        for(int j=0;j<6;j++){
            d=max(abs(min(d,(length(Q)-1.)/a)),.003);
            if(Q.x<-Q.y)Q.xy=-Q.yx;
            Q=Q*2.-b;
            a*=2.;
        }
        R+=normalize(vec3((FC.xy*2.-r)/r.y,2))*d;
        o.rgb+=exp(-d*1300.)*(1.5+sin(R));
    }
    o.w=1.;
}
