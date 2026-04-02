#version 420

// original https://www.shadertoy.com/view/tltSWs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Basic Fractal Zero by @paulofalcao

const int maxIterations=6;

//generic rotation formula
mat2 rot(float a){
    float c=cos(a);float s=sin(a);
    return mat2(c,-s,s,c);
}

void main(void) {
    //normalize stuff
    vec2 R=resolution.xy,uv=(gl_FragCoord.xy-0.5*R)/R.x;
    
    //global zoom
    uv*=sin(time)*0.5+1.5;
    
    //shift, mirror, rotate and scale 6 times...
    for(int i=0;i<maxIterations;i++){
        uv*=2.1;          //<-Scale
        uv*=rot(time);   //<-Rotate
        uv=abs(uv);       //<-Mirror
        uv-=0.5;          //<-Shift
    }

    //draw a circle
    glFragColor=vec4(length(uv)<0.4);
}
