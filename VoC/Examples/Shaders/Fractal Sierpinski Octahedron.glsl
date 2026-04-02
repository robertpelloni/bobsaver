#version 420

// original https://neort.io/art/c3bc6243p9f8s59bf220

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
    vec3 R=vec3(.2,0,2)*t,Q;
    float d=1.,b=1.73,c=0.;
    for(int i=0;i<99;i++){
        if(d<1e-4)break;
        Q=mod(R,b*2.)-b;
        for(int j=0;j<6;j++){
            Q=abs(Q);
            if(Q.y>Q.x)Q.xy=Q.yx;
            if(Q.z>Q.x)Q.zx=Q.xz;
            Q*=2.;
            Q.x-=b;
        }
        d=(dot(abs(Q),vec3(1)/b)-1.)/64.;
        R+=normalize(vec3((FC.xy*2.-r)/r.y,2))*d;
        c++;
    }
    o.rgb=(1.5+sin(R))*9./c;
    o.w=1.;
}
