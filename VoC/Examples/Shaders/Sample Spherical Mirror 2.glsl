#version 420

// original https://neort.io/art/c3h9jss3p9f8s59bg0lg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define t time
#define r resolution
#define FC gl_FragCoord
#define o glFragColor

#define T rotate3D(t,vec3(1))

mat3 rotate3D(float angle, vec3 axis){
    vec3 a = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float r = 1.0 - c;
    return mat3(
        a.x * a.x * r + c,
        a.y * a.x * r + a.z * s,
        a.z * a.x * r - a.y * s,
        a.x * a.y * r - a.z * s,
        a.y * a.y * r + c,
        a.z * a.y * r + a.x * s,
        a.x * a.z * r + a.y * s,
        a.y * a.z * r - a.x * s,
        a.z * a.z * r + c
    );
}

void main(void) {
    vec3 P,R=normalize(vec3((FC.xy*2.-r)/r.y,-2))*T;
    P.z+=5.;
    P*=T;
    float d=1.,c=0.;
    for(int i=0;i<99;i++){
        c++;
        if(d<1e-4)break;
        d=min(6.-abs(P.y),length(P)-1.);
        P+=R*d;
    }
    R-=2.*dot(P,R)*P;
    P+=(sign(P.y)*6.-P.y)/R.y*R;
    if(sin(P.z-t)*sin(P.x-t)<0.)o+=9./c*exp(-dot(P,P)*1e-3);
    o.w=1.;
}
