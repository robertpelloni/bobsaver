#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_BITS 24

float bitReverse(float n, float b)
{
    n = floor(n);
    b = floor(b);
    
    float acc = 0.0;
    
    for(int i = 0;i < MAX_BITS;i++)
    {
        if(i >= int(b))
        {
            break;    
        }
        
        acc += exp2(float(i)) * mod(floor(n / exp2((b-1.0) - float(i))), 2.0);
    }
    
    return acc;
}

float bit(float n, float b)
{
    return mod(floor(n / exp2(floor(b))),2.0);
}

void main( void ) {

    vec2 uv = gl_FragCoord.xy;
    
    float n = time*10.0;
    float b = 24.0;
    float pb = floor((1.0 - uv.x / resolution.x) * b);
    
    float color = 0.0;
    
    if(uv.y > resolution.y/2.0)
    {
        color = bit(bitReverse(n,b),pb);
    }
    else
    {
        color = bit(n,pb);
    }
    
    color = color * 0.75 + 0.25;
    color *= 1.0 - abs(fract(uv.x / resolution.x * b)-0.5);
    color *= 1.0-step(abs(uv.y - resolution.y/2.0),8.0);
    
    glFragColor = vec4( vec3( color ), 1.0 );

}
