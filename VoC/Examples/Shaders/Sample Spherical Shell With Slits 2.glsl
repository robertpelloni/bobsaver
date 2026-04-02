#version 420

// original https://neort.io/art/c3aom043p9f8s59betk0

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
    vec3 R=vec3((FC.xy*2.-r)/r.y,3);
    float d=1.,c=0.;
    for(float i=0.;i<99.;i++){
        if(d<1e-4)break;
        d=max(abs(length(R)-.9),sin((acos(R.y/length(R))-sign(R.z)*acos(R.x/length(R.zx))*.5-t)*4.)*.01);
        R.z-=d;
        c++;
    }
    if(R.z>0.)o.rgb+=vec3(0,.6,1);
    else o.rgb+=vec3(1,.5,.1);
    o*=20./c;
    o.w=1.;
}
