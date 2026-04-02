#version 420

// original https://neort.io/art/c3s458k3p9f8s59bhljg

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
    vec2 p=(FC.xy*2.-r)/r.y*4.1,q;
    p.y+=3.;
    float d=1e5,T=(1.-pow(sin(t*3.)*.5+.5,3.))*PI/4.;
    for(int i=0;i<30;i++){
        q=abs(p);
        d=min(d,max(q.x,q.y));
        p.x=abs(p.x);
        p-=(1.+tan(T))/2.;
        p.y-=1.;
        p*=rotate2D(-T)*cos(T)*2.;
    }
    o+=step(1.,d);
    o.w=1.;
}
