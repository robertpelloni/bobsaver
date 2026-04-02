#version 420

// original https://www.shadertoy.com/view/wdffWr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) {
    for(float n,g,e,j,i;i++<50.;){\
        vec3 p=g*vec3((gl_FragCoord.xy*2.-resolution.xy)/resolution.y,1);\
        p.z+=time;\
        n=ceil(p.z);\
        p=fract(p)-.5;\
        for(j=0.;j++<3.+mod(n,2.);)\
            p.xy=abs(p.xy)-.05,\
            p.xy=vec2(p.x+p.y,p.x-p.y)*.7;\
        g+=e=.5*length(p.yz)-.001;\
        e<.01?glFragColor.xyz+=abs(sin(vec3(1,2,3)+n))*.6/i:p;\
    }\
}
