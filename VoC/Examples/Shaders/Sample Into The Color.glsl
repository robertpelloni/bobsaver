#version 420

// original https://www.shadertoy.com/view/NtjGzz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float wtan(float x){
    if(x<3.14/2.0){
        return tan(x);
    }
    else{
        return tan(-x);
    }
}

void main(void)
{
    float pTime = time*2.0;
    float modT = -1.0*(0.3*sin(pTime*1.2)+pTime*1.3);
    float p = 20.0*wtan(3.14*gl_FragCoord.xy.x/resolution.x);
    
    float r = sin(modT+p*1.0);
    float g = sin(modT+p*1.02);
    float b = sin(modT+p*1.03);
    
    glFragColor = vec4(r,g,b,1.0);
}
