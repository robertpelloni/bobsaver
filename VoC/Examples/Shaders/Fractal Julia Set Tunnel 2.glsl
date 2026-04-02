#version 420

// original https://neort.io/art/c3k81tc3p9f8s59bgg3g

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

mat2 rotate2D(float a) {
    return mat2(cos(a), sin(a), -sin(a), cos(a));
}

void main(void) {
    float L;
    for(float i=1.;i<=10.;i++){
        vec2 p=(FC.xy*2.-r)/r.y/atan(.1,L=i-fract(t))/20.*rotate2D(fract(sin(i+ceil(t))*4e4)*PI2);
        L=dot(p,p)*99.+L*L;
        for(int j=0;j<200;j++){
            if(dot(p,p)>4.&&o.x==0.)o+=exp(-L*.02)*dot(p,p)*.15;
            p=vec2(p.x*p.x-p.y*p.y-.7487,2.*p.x*p.y+.05);
        }
    }
    o.w=1.;
}
