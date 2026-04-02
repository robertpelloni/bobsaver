#version 420

// original https://neort.io/art/c3aojok3p9f8s59betf0

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
    vec3 R=vec3(0,0,5);
    float d=1.,c=0.;
    for(float i=0.;i<99.;i++){
        if(d<1e-4)break;
        d=max(abs(length(R)-2.),sin((acos(R.y/length(R))+sign(R.z)*acos(R.x/length(R.zx))+t)*5.)*.01);
        R+=normalize(vec3((FC.xy*2.-r)/r.y,-2))*d;
        c++;
    }
    o+=9./c;
    o.w=1.;
}
