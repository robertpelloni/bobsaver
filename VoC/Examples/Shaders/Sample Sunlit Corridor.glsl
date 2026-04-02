#version 420

// original https://neort.io/art/c455c0s3p9ffolj04r8g

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
    vec3 P,Q,R=normalize(vec3((FC.xy*2.-r)/r.y,1)),S;
    P.z+=t;
    for(int i=0;i<99;i++){
        Q=P;
        Q.xy=vec2(atan(Q.x,Q.y)/.157,length(Q.xy)-3.);
        Q.zx=fract(Q.zx)-.5;
        P+=R*min(min(length(Q.xy),length(Q.yz))-.2,P.y+.5);
        if(i==50)S=P,R=vec3(.577),P+=R*.01;
    }
    o+=length(S-P)*.12+(P.z-t)*.05;
    o.w=1.;
}
