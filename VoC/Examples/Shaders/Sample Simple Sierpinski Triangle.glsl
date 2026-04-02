#version 420

// original https://www.shadertoy.com/view/NdsGRj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define L 1.5
#define N 11.

#define OVERFLOW 0.035
#define HARSHNESS 2.

void main(void) {
    vec2 uv = 1.7*(gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    uv.y *= -1.;
    //vec3 color = vec3(uv.xy, 0);
    vec3 color = vec3(0);

    uv.y -= .25;
    
   
    //float T = clamp(log(1. +mod(time, exp(1.)-1.)), 0., 1.);
    float T = (exp(mod(time*log(1.1)*.5, 1.*log(1.1)))-1.)/(1.1-1.);
    //uv *= mix(1., .5, T);
    //uv.y -= mix(0., .5, T);
    uv *= mix(.5, .25, T);
    uv.y -= mix(.5, .75, T);
    

    //complexité O(n)
    for(int i=0; i<int(N); i++){
        if(-uv.y > abs(uv.x)*0.57735026){
            uv = (uv-vec2(0, -L/3.))*2.;
        }else if(uv.x > 0.){
            uv = (uv-vec2(cos(PI/6.)/3.*L, sin(PI/6.)/3.*L))*2.;
        }else{
            uv = (uv-vec2(-cos(PI/6.)/3.*L, sin(PI/6.)/3.*L))*2.;
        }
    }
    

    //check if point is inside the triangle in the middle
    // if(//dot(normalize(uv-vec2(0, -2./3.*L)), vec2(0, 1)) > 0.866025404
    //     uv.y+2./3.*L > abs(uv.x)*1.7320
    //     && uv.y < 1./3.*L){
    //     color.rg = vec2(1.);
    // }

    float inside_amount = HARSHNESS*min(
        min(max(0., (uv.y+2./3.*L) - (abs(uv.x)-OVERFLOW*N)*1.7320)*10./N, 1.),
        min(max(0., -uv.y + 1./3.*L +OVERFLOW*N)*15./N, 1.)  
    );
    color.rg = vec2(inside_amount);

    glFragColor = vec4(color, 1);
}
