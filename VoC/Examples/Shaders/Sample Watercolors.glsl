#version 420

// original https://www.shadertoy.com/view/msyfz1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
Author: Felipe Tovar-Henao [www.felipe-tovar-henao.com]
Title: Watercolors
*/

#define PI 3.14159265359
#define TWO_PI 6.28318530718
#define SPEED.25

vec2 adjustViewport(vec2 coord,vec2 res){
    return(coord*2.-res)/(res.x<res.y?res.x:res.y);
}

mat2 rot2(in float a){
    float c=cos(a);
    float s=sin(a);
    return mat2(c,-s,s,c);
}

float fold(in float x){
    return abs(mod(x+1.,2.)-1.);
}

vec2 fold(in vec2 p){
    return vec2(fold(p.x),fold(p.y));
}

float cosine(in float x,in float s){
    float y=cos(fract(x)*PI);
    return floor(x)+.5-(.5*pow(abs(y),1./s)*sign(y));
}

vec2 cosine(in vec2 p,in float s){
    return vec2(cosine(p.x,s),cosine(p.y,s));
}

vec3 cosine(in vec3 p,in float s){
    return vec3(cosine(p.xy,s),cosine(p.z,s));
}

float scale(in float x,in float a,in float b,in float c,in float d){
    return(x-a)/(b-a)*(d-c)+c;
}

vec3 gradient(in float t,in vec3 a,in vec3 b,in vec3 c,in vec3 d){
    return a+b*cos(TWO_PI*(c*t+d));
}

vec3 c1=vec3(.1);
vec3 c2=vec3(.15);
vec3 c3=vec3(2.6);
vec3 c4=vec3(.1,.5,.6);

void main(void) {
    vec2 uv=adjustViewport(gl_FragCoord.xy,resolution.xy);
    float t=time*SPEED;
    t += cosine(t*.25, 2.);
    uv*=5.;
    vec2 p=uv;
    vec2 q=1.-uv;
    float a=.5;
    vec3 col=vec3(0);
    for(float i=1.;i<9.;i++){
        float s=pow(1.3,i);
        float an=-a-cos(a*.5+t)*.125;
        mat2 m=rot2(an);
        p*=m;
        q*=m;
        a+=dot(cos(q+t+i-a)/s,vec2(.25));
        vec2 k=fold(q-t-a+s);
        float h=scale(sin(a+t*1.5),-1.,1.,.5,.75);
        q=mix(q,k,h);
        vec2 tmp=q;
        q=p;
        p=tmp;
        q*=2.;
        float w=a;
        col+=gradient(a*.5+t*.3+i,c1,c2,c3,c4)*w;
    }
    col=cosine(col,1.5);
    glFragColor=vec4(col,1.);
}
