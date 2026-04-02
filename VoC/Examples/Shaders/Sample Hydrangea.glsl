#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tlXcWM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) { //WARNING - variables #define (O,C){\ need changing to glFragColor and gl_FragCoord.xy
    vec4 O=vec4(0.0);
    vec2 C=gl_FragCoord.xy;
    vec3 p=vec3((300.*C.xy/resolution.y),time*9.+C.x*.5),\
    a=vec3(-1,1,0);\
    p.y+=time*40.;\
    int n=int(time*500.)+abs(int(dot(p,a.yyy))^int(dot(p,a.xyx))^int(dot(p,a.zxy))^int(dot(p,a.zxx)));\
    O.xyz+=(cos(p/80.)*.5+.5)*200./float(n%999);\
    glFragColor=O;
}
