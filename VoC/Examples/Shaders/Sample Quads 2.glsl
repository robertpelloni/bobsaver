#version 420

// original https://neort.io/art/ca0fqc43p9fbkmo5pnvg

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

vec3 hsv(float h, float s, float v) {
    vec4 a = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(vec3(h) + a.xyz) * 6.0 - vec3(a.w));
    return v * mix(vec3(a.x), clamp(p - vec3(a.x), 0.0, 1.0), s);
}

void main(void) {
    vec3 P=vec3(t,9,3),Q,R=normalize(vec3((FC.xy*2.-r)/r.y,-2))*rotate3D(6.,vec3(1));
    float d,m=1e5,e,f;
    for(float i=1.;i<20.;i++){
        d=(i*.1-1.-P.z)/R.z;
        Q=P+d*R;
        e=fsnoise(ceil(Q.xy*8.+Q.z*5e2))*4.;
        Q*=PI;
        if(sin(Q.x)*sin(Q.y)>0.&&e<1.)m=d,f=e;
    }
    o.rgb=hsv(f,.5,exp(-m*m*.2)*4.);
    o.a=1.;
}
