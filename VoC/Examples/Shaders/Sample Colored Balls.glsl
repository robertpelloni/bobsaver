#version 420

// original https://neort.io/art/buckf6k3p9f7gige8su0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define FC gl_FragCoord
#define r resolution
#define o glFragColor
#define t time

void main(void) {
    vec2 p=(FC.xy*2.0-r)/r.y*2.+t/2,I=floor(p+.5);
    p-=I;
    vec3 R=vec3(p*1.58,-2.5);
    float s=max(dot(normalize(vec3(sin(t*2.),sin(t*3.),2)),(vec3(0,0,5)+R*(2.62-sqrt(6.87-dot(R,R)))*4.77/dot(R,R))/1.5),0.),v=fract(sin(dot(I,vec2(8,9)))*2e4);
    o=vec4(vec3(1.,v,1.-v)*s+pow(s,20.),1.);
}
