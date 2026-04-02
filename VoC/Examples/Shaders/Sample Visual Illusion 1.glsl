#version 420

// original https://www.shadertoy.com/view/ls33WN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Visual illusion.glsl
//License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//Created by 834144373 (恬纳微晰) 2015/12/8
//Tags: 2D,visual illusion,effect
//-----------------------------------------------------------------------------------------

#define t time/15.
#define q 0.77

void main(void) {
    vec2 uv = ( 2.*gl_FragCoord.xy - resolution.xy)/resolution.y;
    
    float r; 
    
    float rr = length(uv);
    
    r = length(uv)-t*sign(rr-q);
    
    r = sin(r*80.);
    
    r = smoothstep(-0.4,0.4,r);
        
    glFragColor = vec4( r,r,r, 1.0 );
}

