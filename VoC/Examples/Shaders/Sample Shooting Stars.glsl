#version 420

// original https://neort.io/art/c3ikg4c3p9f8s59bg85g

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define t time
#define r resolution
#define FC gl_FragCoord
#define o glFragColor

const float PI = acos(-1.);

mat2 rotate2D(float a) {
    return mat2(cos(a), sin(a), -sin(a), cos(a));
}

void main(void) {
    vec3 R,Q;
    R+=t;
    R.z+=t;
    float d=1.,c=0.;
    for(int i=0;i<99;i++){
        c++;
        if(d<1e-4)break;
        Q=fract(R)-.5;
        d=.4*PI;
        Q.yx*=rotate2D(floor(atan(Q.x,Q.y)/d+.5)*d);
        Q.zx=abs(Q.zx);
        d=max(Q.z-.06,(Q.y*.325+Q.x+Q.z*1.5)/1.83-.05);
        R+=normalize(vec3((FC.xy*2.-r)/r.y,1))*d;
    }
    o.rgb=5./c*(2.+sin(R+ceil(t*9.)));
    o.w=1.;
}
