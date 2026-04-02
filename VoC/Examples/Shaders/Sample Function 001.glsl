#version 420

// original https://www.shadertoy.com/view/3sfBRn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float f(float x)
{
    float y = 0.0;
    float size = 0.25;
    float speed = 3.14;
    
    while(size > 0.001)
    {
        y += sin(x * speed + time) * size;
        speed *= 2.0;
        size *= 0.5;
    }
    
    return y + 0.5;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;

    if( abs( f(uv.x) - uv.y ) < 0.005)
        glFragColor = vec4(1);
}
