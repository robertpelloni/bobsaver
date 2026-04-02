#version 420

// original https://www.shadertoy.com/view/XtSyW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash1( uint n ) 
{
    // integer hash copied from Hugo Elias
    n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 789221U) + 1376312589U;
    return float( n & uvec3(0x7fffffffU))/float(0x7fffffff);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.y;
    
    vec2 uv2 = uv;
    uv2 = uv2 - resolution.xy / resolution.y * 0.5;
    float d = 0.3;
    //uv2 = mod(uv2+d/2., d)-d/2.;
    uv2 = mod(uv2+vec2(0., d/2.), d)-d/2.;
    if(length(uv2) < 0.1)
        uv.y=uv.x;
    
    glFragColor = vec4(vec3(hash1(uint(uv.y*resolution.y*0.5))),1.0);
}
