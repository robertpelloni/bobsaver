#version 420

// original https://neort.io/art/c001e7k3p9f30ks587k0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define r resolution
#define t time
#define o glFragColor

void main(void) {
    vec2 p=(gl_FragCoord.xy*2.-r)/r.y,q;
    p.y=abs(p.y);
    for(float i=4.;i<99.;i++){
        float L=i-fract(t*2.);
        q=p/atan(.5,L)/5.;
        o+=smoothstep(.1,.0,abs(q.y-sin(q.x)*sin((ceil(t*2.)+i)*.3+t*3.)*.5-2.))*exp(-L*.05);
        o.w=1.;
    }
}
