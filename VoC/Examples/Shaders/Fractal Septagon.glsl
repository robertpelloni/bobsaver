#version 420

// original https://www.shadertoy.com/view/wllXWB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Based on http://paulbourke.net/fractals/septagon/

//uncomment to modify the ϕ value with your mouse
//#define MOUSE_CONTROL

float MAX_STEPS=512.;
float PI=acos(-1.);
float AA=1.;

#define vecMul(a,b) vec2(a.x*b.x-a.y*b.y,a.x*b.y+a.y*b.x)
#define vecDiv(a,b) vec2(a.x*b.x+a.y*b.y,a.y*b.x-a.x*b.y)/(b.x*b.x+b.y*b.y)

mat2 matRot(float a){
    float c=cos(a),
          s=sin(a);
    return mat2(c,s,s,-c);
}

vec3 samplePoint(vec2 c,float maxIters){
    float i;
    for(i=0.;i<maxIters;i++){
        vec2 c2 = vecMul(c ,c );
        vec2 c3 = vecMul(c2,c );
        vec2 c6 = vecMul(c3,c3);
        vec2 c7 = vecMul(c6,c );
        #ifdef MOUSE_CONTROL
            c7+=2.*mouse*resolution.xy.xy/resolution.xy-1.;
        #else
            c7.x -=.7/5.;
        #endif
        c = vecDiv(c7,c );
        if(length(c)>2.){
            break;
        }
    }
    float ic=(5.*i/maxIters);
    return vec3(cos(1.-ic)+1.,cos(2.-ic)+1.,cos(3.-ic)+1.)/2.;
    //uncomment this and comment the line above to see a warped grid overlay
    //c=fract(c/10.)-.5;
    //float lg=2.*max(abs(c.x),abs(c.y));
    //return lg*vec3(cos(1.-ic)+1.,cos(2.-ic)+1.,cos(3.-ic)+1.)/2.;
}

void main(void) {
    vec2 c = 2.*gl_FragCoord.xy/resolution.xy-1.;
    c.x*=resolution.x/resolution.y;
    
    float zoomFactor=9.5*(-cos(PI*time/18.)+1.);
    float maxIters=MAX_STEPS*(zoomFactor+18.)/36.;
    float zoom=pow(2.,zoomFactor);
    c/=zoom;
    float delt=((1./resolution.y)/zoom)/AA;
    
    c*=matRot(zoomFactor/10.);
    c+=vec2(.159,.120);
    
    vec3 col;
    for(float y=0.;y<AA;y++){
        for(float x=0.;x<AA;x++){
            col+=samplePoint(c+vec2(x,y)*delt,maxIters);
        }
    }
    col/=(AA*AA);
    glFragColor = vec4(col,1.0);
}
