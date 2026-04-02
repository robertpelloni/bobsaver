#version 420

// original https://neort.io/art/ca0f3ks3p9fbkmo5pmr0

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

float fsnoise(vec2 c) {
    return fract(sin(dot(c, vec2(12.9898, 78.233))) * 43758.5453);
}

void main(void) {
    vec3 P=vec3(cos(t*.2),sin(t*.2),t*.3),R=normalize(vec3((FC.xy*2.-r)/r.y,1)),Q,N;
    float d,m=1e5,a;
    for(float i=1.;i<21.;i++){
        a=PI/10.*i;
        N.xy=vec2(cos(a),sin(a));
        d=(.5-dot(P,N))/dot(R,N);
        Q=P+d*R;
        Q.y+=t*.2+Q.x;
        if(d>0.&&d<m&&fsnoise(ceil(Q.yz*15.)+i/20.)>.7)m=d;
    }
    o+=exp(-m*m);
    o.a=1.;
}
