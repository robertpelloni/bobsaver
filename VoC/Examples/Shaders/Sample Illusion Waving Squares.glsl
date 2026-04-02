#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3tsGDl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define animate

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = 4.5*gl_FragCoord.xy/resolution.y;
    #ifdef animate
    uv.y += 1.*sin(time*1.2);
    #endif
    float sq = floor((fract(uv.y)*2.-1.)*(fract(uv.x)*2.-1.))+1.;
    
    vec3 offwhite = vec3(197,218,180)/256.;
    vec3 blue     = vec3(  6,165,200)/256.;
    
    vec3 col = mix(offwhite,blue,sq);
    
    vec3 magenta  = vec3(183, 29,111)/256.;
    vec3 white    = vec3(1);
    
    float sq2 = floor(fract(uv.x-uv.y-.075)+.15)*
        floor(fract((uv.x+uv.y)-.075)+.15);
    
    sq2 += floor(fract(uv.x-uv.y-.075+.5)+.15)*
        floor(fract((uv.x+uv.y+.5)-.075)+.15);
    
    int sc = int(fract((uv.x+uv.y)/4.+.05)*8.);
    sc = (sc>>2)^(int(sc%4!=2));
    
    vec3 col2 = sq2*mix(magenta,white,float(sc));
    
    glFragColor = vec4(col2.r <= 0. ? col : col2,1.);//vec4(col+sq2,1.);
}
