#version 420

// original https://www.shadertoy.com/view/wtKBWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Author: paperu
// Title: abstract flower

precision lowp float;
uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
#define P 3.14159265359

mat2 rot(float a){return mat2(cos(a),sin(a),-sin(a),cos(a));}

float t;
float df(vec3 p) {
    p.xz *= rot(t*.2);
    p.yz *= rot(P*-.2);
    p.xz *= rot(P*.25);
    
    float rad = 0.66*2.5;
    float d = 10e6;
    int limI = int(floor((cos(t*2.)*.5+.5)*5.));
    for(int i = 0; i < 4; i++) {
        float dt1 = abs(length(abs(p) - vec3(+1.,0.,0.)) - rad) - .0469;
        float dt2 = abs(length(abs(p) - vec3(0.,+1.,0.)) - rad) - .0469;
        float dt3 = abs(length(abs(p) - vec3(0.,0.,+1.)) - rad) - .0469;
        d = min(min(min(d,dt1),dt2),dt3);
        rad -= .2;
    }
    p = abs(p); float dshape = (p.x+p.y+p.z - 10.)*.57735027;
    return max(-d,dshape);
}

#define EPSI .0001
vec3 normal(vec3 p){
    vec2 u = vec2(0.,EPSI); float d = df(p);
    return normalize(vec3(df(p + u.yxx),df(p + u.xyx),df(p + u.xxy)) - d);
}
vec4 rm(vec3 c, vec3 r) {
    vec4 color = vec4(vec3(.1),0.);
    vec3 p = c + r*2.;
    if(df(p) < EPSI) {
        color.rgb = 1. - (normal(p)*.5 + .5);
        color.w = 1.;
        return color;
    }
    return color;
}

void main(void) {
    vec2 st = (gl_FragCoord.xy - .5*resolution.xy)/resolution.x;
    
    float mx = length(mouse*resolution.xy.xy/resolution.xy - .5)*5.;

    st *= 1. + mx;

    t = time*.125;

    vec3 c = vec3(0.,0.,-2.);
    vec3 r = normalize(vec3(st,0.8));
    vec4 color = rm(c,r);

    vec3 copyColor = color.rgb;
    color.rgb += vec3(color.r + color.b + color.g)/3.;
    color.r *= copyColor.b;
    color.g *= copyColor.g;

    glFragColor = vec4(color.grb*color.w,1.);
}
