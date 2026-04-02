#version 420

// original https://www.shadertoy.com/view/XlX3DM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Created by S.Guillitte 

void main(void)
{
    float k=0.;
    vec3 d =  vec3(gl_FragCoord.xy,1.0)/vec3(resolution.xy,1.0)-.5;
    vec3 o = d;
    vec3 c=k*d;
    vec3 p;
    
    for( int i=0; i<99; i++ ){
        
        p = o+sin(time*.1);
        for (int j = 0; j < 10; j++) 
        
            p = abs(p.zyx-.4) -.7,k += exp(-6. * abs(dot(p,o)));
        
        k/=3.;
        o += d *.05*k;
        c = .97*c + .1*k*vec3(k*k,k,1);
    }
    c =  .4 *log(1.+c);
    glFragColor = vec4(c,1.0);
}
