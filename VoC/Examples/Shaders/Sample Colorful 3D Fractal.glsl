#version 420

// original https://www.shadertoy.com/view/4dVGRV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Robert Schütze - trirop/2015
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

vec3 map(in vec3 p){for(int i=0;i<100;i++)p.xzy =abs(vec3(1.3,.99,.75)*(p/dot(p,p)-vec3(1,1,.05)));return p/50.;}

vec3 raymarch(vec3 ro, vec3 rd){
    float t = 5.;
    vec3 col = vec3(0.);
    for(int i=0; i<50; i++){t+=0.03;col += map(ro+t*rd);}
    return col;
}

void main(void) {
    vec2 p = (gl_FragCoord.xy-resolution.xy/2.)/(resolution.y);
    float a = time*0.3;
    vec3 r = vec3(3.)*mat3(cos(a),0,-sin(a),0,1,0,sin(a),0,cos(a));
    glFragColor.rgb = raymarch(r,normalize(p.x*normalize(cross(r,vec3(0,1,0)))+p.y*normalize(cross(normalize(cross(r,vec3(0,1,0))),r))-r*.3));
}
