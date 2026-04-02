#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/sls3DN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

uint hash2(uint x)
{
    x ^= x >> 16;
    x *= 0x7feb352dU;
    x ^= x >> 15;
    x *= 0x846ca68bU;
    x ^= x >> 16;
    return x;
}

float rand(vec2 uv)
{
    uint fb = floatBitsToUint(uv.y)^hash2(floatBitsToUint(uv.x));

    fb = hash2(fb) & 0x007fffffu | 0x3f800000u;
    float f = uintBitsToFloat(fb) - 1.0;

    return f;
}

vec2 polar(vec2 uv)
{
    return vec2(length(uv),(atan(uv.x,uv.y))*1.);
}

float v(vec2 uv)
{
    float grid_size = 6.;
    uv = (polar(uv)-vec2(time*0.2,0.)) * grid_size;
    uv.y =abs(uv.y*0.12);
    vec2 i_uv = floor(uv);
    vec2 f_uv = fract(uv);
        
    const float m = sqrt(2.);
    float r = m;
    
    for(float y = -1.; y <= 1.; y++)
    {
        for(float x = -1.; x <= 1.; x++)
        {
            vec2 n = vec2(x,y);
            vec2 p = vec2(rand(i_uv+n));
            p = vec2(sin(p.x*(4.+time)*0.5),cos(p.y*time*1.5))*0.5+0.5;
            vec2 d = (n + p - f_uv);
            r = min(r,length(d));
        }
    }
    
    return 1.0-pow(r*(0.5*m),0.1);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy*2.-resolution.xy)/resolution.y;

    vec3 col = vec3(pow(length(uv*.4),2.))*vec3(0.31,0.13,.2)*v(uv)*40.;
    
    glFragColor = vec4(pow(col,vec3(1.0/2.2)),1.0);
}
