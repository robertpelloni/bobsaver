#version 420

// original https://www.shadertoy.com/view/wtBXDD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926
#define TAU 6.2831852

#define SF 1./min(resolution.x,resolution.y)

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/resolution.y;
    
    float a = atan(uv.y, uv.x)/TAU;
    
    float l = length(uv);
    float m = 0.;
    for(float n=0.; n<6.; n+=1.){
        float i = n*PI*.25;
        float t = time*1. + i;
        
        float tt = 16.;
        float f = t + a*PI*tt;
        
        float s = sin(f)*.5+.5;
        float w = sin(PI*time + f + a*PI*4.)*.5+.5;
        
        float bs = w*.01;
        
        m = max(m, smoothstep(SF*2.+bs, bs, abs(l - (s*.25 + .225))) * (w*.5+.5) );
    }
    
    
    glFragColor = vec4(m);
}
