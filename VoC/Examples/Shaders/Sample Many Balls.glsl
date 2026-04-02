#version 420

// original https://www.shadertoy.com/view/tssBRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define M(p)min((p).y,length(p+vec3(\
sin(time+Q.z),\
-abs(cos(time*7.+Q.z))-.5,\
cos(time+Q.x)\
))-.5)

void main(void) {
    vec4 O=glFragColor;
    vec3 P,Q;\
    for(float T,i=0.;i++<99.;T+=M(P)*.5)\
        P=.9-vec3((gl_FragCoord.xy-resolution.xy*.5)/-resolution.y,1)*T,\
        Q=ceil(P/4.),\
        P.xz=mod(P.xz,4.)-2.,\
        O+=M(P)<.1?M(P+.2)*.03:0.;\
    glFragColor = O;
}
