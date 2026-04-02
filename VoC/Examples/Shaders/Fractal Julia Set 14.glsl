#version 420

// original https://www.shadertoy.com/view/fsBGRG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ITR 100
#define PI 3.1415926

mat2 rot(float a){
    float c=cos(a);
    float s=sin(a);
    return mat2(c,-s,s,c);
}

vec2 pmod(vec2 p,float n){
    float np=PI*2.0/n;
    float r=atan(p.x,p.y)-0.5*np;
    r=mod(r,np)-0.5*np;
    return length(p)*vec2(cos(r),sin(r));
}

float julia(vec2 uv){
    int j;
    for(int i=0;i<ITR;i++){
        j++;
        vec2 c=vec2(-0.345,0.654);
        vec2 d=vec2(time*0.005,0.0);
        uv=vec2(uv.x*uv.x-uv.y*uv.y,2.0*uv.x*uv.y)+c+d;
        if(length(uv)>float(ITR)){
            break;
        }
    }
    return float(j)/float(ITR);
}

void main(void) {
    vec2 uv=(2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;

    uv.xy*=rot(time*0.5);
    //uv=pmod(uv.xy,6.0);
    uv*=abs(sin(time*0.2));
    float f=julia(uv);

    glFragColor=vec4(f-0.4,(f-(fract(time*0.1))),f,1.0);
}
