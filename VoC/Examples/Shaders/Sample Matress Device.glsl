#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define STEPS 25.

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/resolution.y;
    
    float t = time;           
    float m = 0.;
    float col = 0.;
    float sStep = 1./STEPS;
    float zoomF =  sin(t*.5)*.5+.5;
    
    for(float i = 1.; i>0.01; i-=sStep){
        float isf = t*.1;
        vec2 iuv = uv * (1. + i * .5) + vec2(cos(isf), sin(isf))*2.;
        
        isf = i*STEPS*.5 - t*5.;
        vec2 guv = iuv * (3. + zoomF) + vec2(sin(isf), cos(isf))*.05;        
        guv = fract(guv) - .5;
                    
        float mi = step(abs(i*.75 - length(guv)), .005);
        
        if(mi > 0.){
            col = 1. - i;
        }
        
        m += mi;
    }   
        
    col *= min(m, 1.) * (1. - length(uv)*.25);
    
    glFragColor = vec4(col);
}
