#version 420

// original https://www.shadertoy.com/view/MtGGDK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define N 20.0
#define time time * 0.7

float hash( vec2 p)
{
    vec3 p2 = vec3(p.xy, 2.0);
    return fract(sin(dot(p2, vec3(27.1, 20.7, 2.4))) * 0.5453123);
}

float noise(in vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);
    f *= f * (3.0 - 2.0 * f);
    return mix(mix(hash(i + vec2(0., 0.)), hash(i + vec2(1., 0.)), f.x),
               mix(hash(i + vec2(0., 1.)), hash(i + vec2(1., 1.)), f.x),
               f.y);
}

float random(float n)
{
    return fract(sin(n) * 43758.5453);
}

float range(float a, float b, float n)
{
    return a + (b - a) * random(n);
}

float lux(vec2 uv, float x, float y)
{
    float val = 0.011 / distance(uv, vec2(x, y));
    return pow(val, 0.97);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    
    vec4 color = vec4(0.0);
    
    for (float i = 0.0; i < N; i += 1.0)
    {
        float x = 2.0 * noise(vec2(range(0.9, 2.2, i + 0.1), time * range(0.9, 2.2, i + 0.2))) - 1.0;
        float y = 2.0 * noise(vec2(range(0.9, 2.2, i + 0.3), time * range(0.9, 2.2, i + 0.4))) - 1.0;
        
        x *= 0.8;
        y *= 0.8;
        
        color.r += lux(uv, -x, y);
        color.b += lux(uv, x, -y);
        color.g += lux(uv, x, y);
    }
    
    color = step(0.5, color);
    
    vec3 pal = vec3(10, 10, 10 );
    color.xyz = floor( color.xyz * pal  ) / pal.xyz;
    
    glFragColor = color;
}
