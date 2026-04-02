#version 420

// original https://neort.io/art/c3aotts3p9f8s59beu00

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
    vec3 R;
    R.z+=2.;
    float d=1.,e,c=0.;
    for(float i=0.;i<99.;i++){
        if(d<1e-4)break;
        e=length(max(abs(R)-.5,0.))-.1;
        d=max(abs(e)-.05,sin((acos(R.y/length(R))*5.+sign(R.z)*acos(R.x/length(R.zx))+t*3.)*3.)*.01);
        R+=normalize(vec3((FC.xy*2.-r)/r.y,-2))*d;
        c++;
    }
    if(e<0.)o.rg+=1.;
    else if(e<.3)o.b=1.;
    o*=30./c;
    o.w=1.;
}
