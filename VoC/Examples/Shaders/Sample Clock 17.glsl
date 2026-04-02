#version 420

// original https://www.shadertoy.com/view/MlyXzV

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Created by pthextract in 2017-Jan-21

#define N 5e-1 / (1.-cos(atan(i.x,i.y)
void main(void) //WARNING - variables void (out vec4 o,vec2 i) need changing to glFragColor and gl_FragCoord
{
    vec2 i = gl_FragCoord.xy;
    vec4 o;
    i+=i-resolution.xy;
    
    o =  N-date.w/vec4(6,360,4320,1)*acos(0.)*.4))
        +N-date.w/vec4(.1,6,4320,1)*acos(0.)*.4))+N*12.));
       
    
    float d=distance(i,vec2(.5,.5));
    o*=2.*33333./ d/ d/d;
    if ( d<resolution.y*.95)o*=o;
    else{
    
     
        o*=(d+111.)*.2;}
    //if (dist<resolution.y*.15) o+=distance(i,vec2(.5,.5));
    glFragColor = o;
}
