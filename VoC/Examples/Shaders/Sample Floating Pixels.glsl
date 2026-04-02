#version 420

// original https://neort.io/art/c3bd1lc3p9f8s59bf340

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define t time
#define r resolution
#define FC gl_FragCoord
#define o glFragColor

const float PI2 = acos(-1.)*2.;

vec3 hsv(float h, float s, float v) {
    vec4 t = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(vec3(h) + t.xyz) * 6.0 - vec3(t.w));
    return v * mix(vec3(t.x), clamp(p - vec3(t.x), 0.0, 1.0), s);
}

mat2 rotate2D(float a) {
    return mat2(cos(a), sin(a), -sin(a), cos(a));
}

void main(void) {
    vec2 p=(FC.xy*2.-r)/r.y,q;
    float L,n;
    for(float i=0.;i<99.;i++){
        L=1.-fract(t)+i;
        n=fract(sin(floor(t)+i)*1e4)*PI2;
        q=p/atan(.5,L)/9.+vec2(sin(t*.5+n),sin(t*.7+n))*5.;
        q=ceil((mod(q,6.)-3.)*5.*rotate2D(t*n))/5.;
        if(o.x==0.)o.rgb=hsv(n,.7,1.)*step(length(q)+n*.15,1.)*exp(-L*.02);
    }
    o.w=1.;
}
