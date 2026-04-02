#version 420

// original https://neort.io/art/ca0fbdc3p9fbkmo5pne0

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
    vec3 P,Q,R=normalize(vec3((FC.xy*2.-r)/r.y,-1)),N;
    P.z=1.5;
    float d,m=1e5,a;
    for(float i=1.;i<11.;i++){
        a=PI/5.*i+t;
        N.zx=vec2(cos(a),sin(a));
        d=-dot(P,N)/dot(R,N);
        Q=P+d*R;
        Q.zx*=rotate2D(a);
        if(d>0.&&d<m&&sin(length(Q)*10.)<sin(atan(Q.y,Q.x)*9.))m=d;
    }
    o+=exp(-m*m*.3);
    o.a=1.;
}
