#version 420

// original https://www.shadertoy.com/view/lltBW8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float plotline(vec2 uv, float line)
{
    return    smoothstep( line-0.02, line, uv.y ) - 
            smoothstep( line, line+0.02, uv.y );
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    float uvx = uv.x;

    
    vec4 bg = vec4(0.6,0.6,0.6,1.0);
    
    if( uv.x < 0.8)
    {
        uv.x = uv.x*6.0;
    
        uv.y = uv.y*4.0;
        
        float lineA = 2.0+sin(4.0*sin(2.0*time+uv.x));
    
        float lineB = 2.0+sin(2.0*time+uv.x);
        
        lineA = plotline(uv,lineA) * uvx*2.0;
    
        lineB = plotline(uv,lineB) * uvx*2.0;
    
        bg = (1.0-lineA)*bg + lineA*vec4(1.0,1.0,1.0,1.0);
        
        bg = (1.0-lineB)*bg + lineB*vec4(0.2,0.2,0.2,1.0);
        
    }

    glFragColor = vec4(bg);
}
