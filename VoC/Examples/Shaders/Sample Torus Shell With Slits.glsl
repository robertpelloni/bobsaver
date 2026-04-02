#version 420

// original https://neort.io/art/c3aoqq43p9f8s59betpg

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
    R.z+=6.;
    float d=1.,e,c=0.;
    for(float i=0.;i<99.;i++){
        if(d<1e-4)break;
        e=length(vec2(length(R.zx)-2.,R.y))-1.7;
        d=max(abs(e)-.01,sin((acos(R.y/length(R))*10.+sign(R.z)*acos(R.x/length(R.zx))+t*3.)*3.)*.01);
        R+=normalize(vec3((FC.xy*2.-r)/r.y,-2))*d;
        c++;
    }
    if(e<0.)o.g=1.;
    else o.b=1.;
    o*=20./c;
    o.w=1.;
}
