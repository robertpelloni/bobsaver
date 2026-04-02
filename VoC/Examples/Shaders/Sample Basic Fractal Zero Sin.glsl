#version 420

// original https://www.shadertoy.com/view/wtdSWs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Basic Fractal Sin by @paulofalcao

const int maxIterations=8;

//generic rotation formula
vec2 rot(vec2 uv,float a){
    float c=cos(a);float s=sin(a);
    return uv*mat2(c,-s,s,c);
}

void main(void) {
    //normalize stuff
    vec2 uv=resolution.xy;uv=-.5*(uv-2.0*gl_FragCoord.xy)/uv.x;

    //global zoom
    uv*=sin(time)*2.5+5.5;

    //shift, mirror, rotate and scale 6 times...
    for(int i=0;i<maxIterations;i++){
        uv*=1.5;                        //<-Scale
        uv=rot(uv,time);               //<-Rotate
        uv+=sin(uv*sin(time)*8.0)*0.1; //<-Sin Distortion
        uv=abs(uv);                     //<-Mirror
        uv-=0.5;                        //<-Shift
    }

    //draw a circle
    float c=length(uv)>0.2?0.0:1.0;    

    glFragColor = vec4(c,c,c,1.0);
}
