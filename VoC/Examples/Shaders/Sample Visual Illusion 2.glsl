#version 420

// original https://www.shadertoy.com/view/Ms33WN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//-------------------------------------------------------------------------------------
// Look at this for a 30 seconds,and then see other things,you will feel the illusion.:)
//-------------------------------------------------------------------------------------
//
//  Maybe I should call it "Eye's Effect Shader "
//    because you will find your eyes can write shader after you look at this

//uncomment it to see everything small
#define To_See_Everything_is_Big

//speed
#define speed 0.25

void main(void) { 
    vec2 uv = ( 2.*gl_FragCoord.xy - resolution.xy)/resolution.y;
    
    float r; 
    
    float rr = length(uv);

    #ifdef To_See_Everything_is_Big
        #define t time*speed
    #else
        #define t -time*speed
    #endif    
    r = (length(uv)+t+atan(uv.x,uv.y)*.2);
    r = sin(r*80.);
    
    r = smoothstep(-.4,.4,r);
        
    glFragColor = vec4( r,r,r, 1.0 );
}
