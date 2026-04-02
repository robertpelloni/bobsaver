#version 420

// original https://neort.io/art/c3bd7r43p9f8s59bf3f0

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

float fsnoise(vec2 c) {
    return fract(sin(dot(c, vec2(12.9898, 78.233))) * 43758.5453);
}

void main(void) {
    vec2 p=(FC.xy*2.-r)/r.y,q;
    float L,n;
    for(float i=0.;i<30.;i++){
        L=1.+i-fract(t);
        q=p/atan(.005,L)/500.;
        L=dot(q,q)*3e2+L*L;
        n=fsnoise(vec2(ceil(t)+i))*PI2;
        q=ceil(q*20.+vec2(cos(n),sin(n))*2.)/20.;
        if(o.x==0.)o+=step(1.,fsnoise(q+n*.01)+dot(q,q)*2.)*exp(-L*.01);
    }
    o.w=1.;
}
