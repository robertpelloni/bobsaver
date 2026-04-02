#version 420

// original https://www.shadertoy.com/view/wsScRt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(_)\
    mat2(\
        2.0,\
          (sin(t)/cos(t))\
        -sin(2.5),\
         sin(t)/cos(t)\
        -sin(2.5)\
    ,2.0)

void main(void)
{
    float t = time;
    vec2 r = resolution.xy;
    vec2 p=(gl_FragCoord.xy*2.-r)/min(r.y,r.x);
    for(int i=0;i<4;++i){
        p=abs(p)-0.34;p*=R(t);
    }
    float v = 1.0/(p.y)*(5.0/-log(p.y/.3));
    glFragColor = vec4(v*vec3(1.0,1.0,1.0),1);
}
