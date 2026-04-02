#version 420

// original https://neort.io/art/c0dtlmk3p9f30ks5b0bg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define t time
#define r resolution
#define FC gl_FragCoord
#define o glFragColor

#define D(x,y,z) length(vec2(length(mod(vec2(x,y),1.)-.5)-.3,mod(z,1.)-.5))-.05

void main(void) {
    vec3 R=vec3(t,0,.2);
    float d=1.;
    for(float i=0.;i<99.;i++){
        if(d>1e-4){
            d=min(D(R.x,R.y,R.z),D(R.x-.5,R.z,R.y));
            R+=normalize(vec3((FC.xy*2.-r)/r.y,2))*d;
            o=vec4(9)/i;
        }
    }
    o.w=1.;
}
