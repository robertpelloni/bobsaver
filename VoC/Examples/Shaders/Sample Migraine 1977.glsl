#version 420

// original https://www.shadertoy.com/view/ws2Gz3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy*200.;
    
    float nTime=time*6.;
    
    float s = sin(nTime*.05);
    float c = cos(nTime*.051);
    uv*=mat2(c, -s, s, c); 
    
    
    float col1=tan(sin(uv.y)+cos(uv.x));
    float col2=tan(sin(uv.y)+sin(uv.x+sin(nTime)));
    float col3=tan(sin(uv.x)+cos(uv.y+sin(nTime)));
    
    glFragColor = vec4(col1,col2,col3,1.0);
}
