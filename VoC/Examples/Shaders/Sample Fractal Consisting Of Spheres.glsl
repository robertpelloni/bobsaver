#version 420

// original https://neort.io/art/c3bcais3p9f8s59bf280

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define t time
#define r resolution
#define FC gl_FragCoord
#define o glFragColor

#define F(V)V=V.x<-V.y?-V.yx:V;

void main(void) {
    vec3 R=vec3(0,.1,1)*t,Q;
    float d=1.,a,b=1.73,c=0.;
    for(int i=0;i<99;i++){
        if(d<1e-4)break;
        Q=abs(mod(R,b*2.)-b);
        d=9.;
        a=1.;
        for(int j=0;j<9;j++){
            d=min(d,(length(Q)-1.)/a);
            F(Q.xy)
            F(Q.yz)
            F(Q.zx)
            Q=Q*2.-b;
            a*=2.;
        }
        R+=normalize(vec3((FC.xy*2.-r)/r.y,2))*d;
        c++;
    }
    o.rgb=(1.5+cos(R*2.))*5./c;
    o.w=1.;
}
