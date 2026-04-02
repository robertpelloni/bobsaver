#version 420

// original https://www.shadertoy.com/view/7tl3D2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    float c  = cos(time);
    float s  = sin(time);
    vec2  r  = resolution.xy * 0.5;
    vec2  p  = mat2(c, -s, s, c) * (gl_FragCoord.xy - r)/r.y;
    
    float l2 = 0.75;
    float x  = l2 / sqrt(3.0);
    
    vec2  p0 = vec2( 0.0,  x * 2.0);
    vec2  p1 = vec2(-l2 , -x      );
    vec2  p2 = vec2( l2 , -x      );
    vec2  k;
    float D, d;
    
    for(int i = 0; i < 12; ++i)
    {
        D = length(p - p0);           k = p0;
        d = length(p - p1); if(d < D) k = p1, D = d;
        d = length(p - p2); if(d < D) k = p2;
        
        p = k + 2.0 * (p - k);
    }
    
    glFragColor = vec4(clamp(1.0 - length(p) * 0.1, 0.0, 1.0));
}
