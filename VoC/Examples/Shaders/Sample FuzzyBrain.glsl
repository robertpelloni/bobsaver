#version 420

// original https://www.shadertoy.com/view/4dtfz8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TWO_PI  6.283

vec2 rand(vec2 p)
{
    return fract(sin(vec2(dot(p,vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

void main(void)
{
    float scale = 7.0;
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);

    float _d = length(uv)*0.95;
    
    uv = (uv * scale);// + vec2(time * 1.1, time * 0.75);
    vec2 st1 = floor(uv);
    vec2 st2 = fract(uv);

    float mindist = 0.25;
    float speed = time;
    for (int x = -1; x <= 1; x++)
    {
        for (int y = -1; y <= 1; y++)
        {
            vec2 n = vec2(float(y), float(x));
            vec2 offset = rand(st1 + n);
            offset.x = 0.5+sin(speed + TWO_PI * offset.x)*0.5;
            offset.y = 0.5+sin(speed + TWO_PI * offset.y)*0.5;
            vec2 pos = n + offset - st2;
            float d = length(pos);
            mindist = min(mindist, mindist * d);
        }
    }
    
    
    vec3 col = vec3(mindist*3.5);
    col *= _d*_d;
    
    glFragColor = vec4(col, 1.0);
}
