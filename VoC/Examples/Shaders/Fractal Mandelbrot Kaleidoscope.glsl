#version 420

// original https://www.shadertoy.com/view/ss23WW

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

float mandelbrot(vec2 uv,vec2 c){
    int j;
    for(int i=0;i<ITR;i++){
        j++;
        uv=vec2(uv.x*uv.x-uv.y*uv.y+c.x,2.0*uv.x*uv.y+c.y);
        if(length(uv)>float(ITR)){
            break;
        }
    }
    return float(j)/float(ITR);
}

void main(void) {
    vec2 uv=(2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
    uv.xy*=rot(time*0.5);
    uv=pmod(uv.xy,9.0);
    uv=mod(uv,0.8)-0.4;
    uv*=3.0;
    uv*=0.5+abs(sin(time*0.5));
    uv+=vec2(-0.5,0.0);
    float f=mandelbrot(vec2(0.0),uv);

    vec3 col=vec3(pow(f,3.0));

    glFragColor=vec4(col,1.0);
}
