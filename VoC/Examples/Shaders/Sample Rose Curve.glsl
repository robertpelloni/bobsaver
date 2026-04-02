#version 420

// original https://www.shadertoy.com/view/MtVBRc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = (2.0*gl_FragCoord.xy - resolution.xy)/resolution.y;

    float theta = atan(uv.y, uv.x);
    
    float i = 5.0, j = 6.0;

    float n = cos(0.003*i*time)*4.0+4.0;
    float d = sin(0.003*j*time)*4.0+4.0;
    
    float c = 0.45;//abs(mouse*resolution.xy.x/resolution.x*2.0 - 1.0);        //using mouse to control "c"
    
    float r = 0.0;
    
    float factor = 0.0;
    for(int i=0; i < 16; i++)
    {
        r = (sin(n/d*theta))*0.5 + c;            //rose curve function
        float tmp = abs(length(uv) - r);
        factor += 1.0 - smoothstep(-1.5,1.5, tmp / fwidth(length(uv) - r));;
        theta += 3.1415926*2.0;
    }
    
    glFragColor = vec4( 1. - factor );
}
