#version 420

// by @paulofalcao
//
// https://www.shadertoy.com/view/XsyXRK
//
// Fun with some feedbacks :)
//

uniform float time;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

vec3 subImg(float xs,float ys, float zs){
    vec2 xy=gl_FragCoord.xy/resolution.xy;
    xy-=0.5;
    xy+=vec2(sin(time*xs)*0.1,cos(time*ys)*0.1);
    xy*=(1.1+sin(time*zs)*0.1);
    xy+=0.5;
    return texture2D(backbuffer,xy).xyz;
}

vec3 drawCircle(in vec2 xy){
    float l=length(xy);
    float c=sin(length(l)*128.0)*.5+0.5;
    if (l>.233) c=0.0;
    if (l<.184) c=0.0;
    return vec3(c,c,c);
}

void main( void ) {
    
    vec2 xy=resolution.xy;xy=-.5*(xy-2.0*gl_FragCoord.xy)/xy.x;
    xy*=1.0+sin(time*4.0)*0.2;
    xy.x+=sin(xy.x*32.0+time*16.0)*0.01;
    xy.y+=sin(xy.y*16.0+time*8.0)*0.01;
    vec3 c=drawCircle(xy);
 
    vec3 fC=
        subImg(3.3,3.1,2.5)*vec3(0.3,0.7,1.0)+
        subImg(2.4,4.3,3.3)*vec3(0.3,1.0,0.7)+
        subImg(2.2,4.2,4.2)*vec3(1.0,0.7,0.3)+
        subImg(3.2,3.2,2.1)*vec3(1.0,0.3,0.7)+
        subImg(2.2,1.2,3.4)*vec3(0.3,0.5,0.7)+
        subImg(5.2,2.2,2.2)*vec3(0.8,0.5,0.1);
    
    glFragColor=vec4((fC/3.6+c)*0.95,1.0);
    
}
