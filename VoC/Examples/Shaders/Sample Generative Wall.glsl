#version 420

// original https://neort.io/art/c4fis1c3p9ffolj0642g

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define t time
#define r resolution
#define FC gl_FragCoord
#define o glFragColor

mat2 rotate2D(float a) {
    return mat2(cos(a), sin(a), -sin(a), cos(a));
}

void main(void) {
    vec3 P,Q,S;
    float d=1.,T=floor(t)+smoothstep(.2,.8,fract(t)),c=0.;
    for(int i=0;i<99;i++){
        c++;
        if(d<1e-4)break;
        Q=P;
        S=vec3(2,2,1);
        for(int j=0;j<9;j++){
            Q=abs(Q)-abs(S);
            if(Q.y>Q.x)Q.xy=Q.yx;
            S.xy*=rotate2D(T*.1)*.7;
        }
        P+=normalize(vec3((FC.xy*2.-r)/r.y,1))*(d=length(max(abs(Q)-.1,0.)));
    }
    o+=9./c;
    o.w=1.;
}
