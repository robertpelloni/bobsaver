#version 420

// original https://neort.io/art/ca3m15k3p9fbkmo5qm10

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
    vec3 P,Q;
    float d=1.,a,c;
    for(int i=0;i<100;i++){
        c++;
        if(d<1e-4)break;
        d=min(P.y,0.)+.3;
        a=1.;
        for(float j=1.;j<10.;j++)Q=(P+vec3(9,0,t)+fract(sin(j)*1e3)*PI2)*a,Q+=sin(Q)*2.,Q=sin(Q),d+=Q.x*Q.y*Q.z/a,a*=2.;
        P+=normalize(vec3((FC.xy*2.-r)/r.y,1))*d*.3;
    }
    o+=mix(1.,1.-c/99.,exp(-dot(P,P)*.03));
    o.a=1.;
}
