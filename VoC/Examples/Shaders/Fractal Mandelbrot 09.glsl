#version 420

// original https://www.shadertoy.com/view/tdGcDK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    
    float animatedTime = max(0.0,abs(sin(time/20.0))*13.0 - 2.0);
    
    float zoom    =       pow(3.0,animatedTime) * 0.7;
    
    vec2 position = vec2(  
                                -0.74364386269,
                                0.13182590271
                              );
    
    
    float iterations =      20.0 + animatedTime*80.0;
    
    
    
    const float limit = 1e+6;
    
    vec2 uv = gl_FragCoord.xy/resolution.y;
    uv -= resolution.xy/resolution.y * 0.5;
    uv*=2.0;
    
    //uv is now in [-1,1][-1,1]
    
    
    
    uv /= zoom;
    uv += position;
    
    vec2 complex = uv;
    int i = 0;    
    for(;float(i)<iterations;i++){
        
        float temp = complex[1]*complex[0]*2.0;
        complex[0] = complex[0]*complex[0]-complex[1]*complex[1];
        
        complex[1]=temp;
        
        complex+=uv;
        
        
        if ((abs(complex[0])>limit)||(abs(complex[1])>limit))
            break;
    }
    
    float fractured_steps = 0.5 - 0.5*log(complex[0]*complex[0]+complex[1]*complex[1])/log(limit);
    
    float color = (float(i) + fractured_steps )/(float(iterations)+8.0);

    glFragColor = vec4(color,color,color,1.0);
}
