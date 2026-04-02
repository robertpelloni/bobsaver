#version 420

// original https://www.shadertoy.com/view/3tSyW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by inigo quilez - iq/2020
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// A blend between 
//  https://www.shadertoy.com/view/4dBSRK
// and
//  https://www.shadertoy.com/view/wl2yDV

// 0: triangles
// 1: squares
#define SHAPE 0

void main(void)
{
    vec2 p = 4.0*(2.0*gl_FragCoord.xy-resolution.xy) / resolution.y;

    #if SHAPE==0
    p.x += 0.5*p.y;
    #endif
    
    vec2 f = fract(p);
    vec2 i = floor(p);
    
    float id = fract(fract(dot(i,vec2(0.436,0.173))) * 45.0);
    #if SHAPE==0
    if( f.x>f.y ) id += 1.3;
    #endif
    
    vec3  col = 0.5+0.5*cos(0.7*id  + vec3(0.0,1.5,2.0) + 4.0);
    float pha = smoothstep(-1.0,1.0,sin(0.2*i.x + 0.2*time + id*1.0));
    
    #if SHAPE==0
    vec2  pat = min(0.5-abs(f-0.5),abs(f.x-f.y)) - 0.3*pha;
    #else
    vec2  pat = 0.5-abs(f-0.5) - 0.5*pha;
    #endif
    
    pat = smoothstep( 0.04, 0.07, pat );

    glFragColor = vec4( col*pat.x*pat.y, 1.0 );
}
