#version 420

// original https://neort.io/art/c38vfu43p9f8s59belg0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define t time
#define r resolution
#define FC gl_FragCoord
#define o glFragColor

float fsnoise      (vec2 c){return fract(sin(dot(c, vec2(12.9898, 78.233))) * 43758.5453);}

vec3 hsv(float h, float s, float v){
    vec4 t = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(vec3(h) + t.xyz) * 6.0 - vec3(t.w));
    return v * mix(vec3(t.x), clamp(p - vec3(t.x), 0.0, 1.0), s);
}

void main(void) {
    vec3 R;
    R.z+=t;
    vec2 u;
    float d=1.,c=0.;
    for(float i=0.;i<99.;i++){
        d=length(fract(R)-.5)-.3;
        if(d<1e-4)break;
        R+=vec3((FC.xy-r*.5)/r.y,1)*d;
        c++;
    }
    R=fract(R)-.5;
    u=acos(vec2(R.y/.3,R.x/length(R.zx)))*5.;
    d=fsnoise(ceil(u)+ceil(t*9.)*.1);
    u=.5-abs(fract(u)-.5);
    o.rgb=hsv(d,.8,1.)*min(u.x,u.y)/c*99.;
    o.w=1.;
}
