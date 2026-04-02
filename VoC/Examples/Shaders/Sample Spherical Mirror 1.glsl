#version 420

// original https://neort.io/art/c3h9gec3p9f8s59bg0g0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define t time
#define r resolution
#define FC gl_FragCoord
#define o glFragColor

const float PI2 = acos(-1.)*2.;

void main(void) {
    vec3 P,R=normalize(vec3((FC.xy*2.-r)/r.y,-2));
    P.z+=5.;
    float d=1.;//,c=0.;
    for(int i=0;i<99;i++){
        //c++;
        if(d<1e-4)break;
        d=min(3.-abs(P.y),length(P)-1.);
        P+=R*d;
    }
    R=R-2.*dot(P,R)*P;
    if(abs(P.y)<1.1)P+=(sign(P.y)*3.-P.y)/R.y*R;
    //P-=t*PI2;if(sin(P.z)*sin(P.x)<0.)o+=9./c;
    if(sin(P.z-t*PI2)*sin(P.x-t*PI2)<0.)o+=exp(-dot(P,P)*.001);
    o.w=1.;
}
