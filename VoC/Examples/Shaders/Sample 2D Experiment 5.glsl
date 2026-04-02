#version 420

// original https://www.shadertoy.com/view/Xl2XzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int iterations = 12;
const float view = 40.;
#define CIRCLE
#define COLOR

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy - .5;
    uv *= view;
    
    for (int i = 0; i < iterations; i++) {
        float ang = atan(uv.y+cos(uv.x*2.+time)*.5,
                         uv.x+sin(uv.y*2.+time)*.5)-length(uv)*.1;
        float sn = sin(ang);
        float cs = cos(ang);
        
        mat2 m = mat2(sn,cs,-cs,sn);
        uv = uv*.2-abs(uv*.5*m);
    }
    
    #ifdef CIRCLE
    float d = length(mod(uv,1.)-.5)-.4;
    #else
    float d = length(max(abs(mod(uv,1.)-.5)-vec2(.1,.4), 0.));
    #endif
    
    #ifdef COLOR
    d += time*.05;
    d *= 50.;
    glFragColor = vec4( sin(d), cos(d+.5346), -sin(d+1.63), 1. )*.5+.5;
    #else
    glFragColor = vec4(max(0.,1.-d*100.));
    #endif
}
