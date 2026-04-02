#version 420

// original https://www.shadertoy.com/view/WdfyRl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 random2(vec2 uv)
{
    uv = vec2(dot(uv,vec2(127.1,311.7)),
              dot(uv,vec2(269.5,183.3)));
    return -1.0 + 2.0 * fract(sin(uv) * 43758.5453123);
}

void main(void)
{
    float cellNum = 10.;
    
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    uv.x *= resolution.x / resolution.y;
    
    uv *= cellNum;
    
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    
    float minDist = 1.;
    
    for (int y = -1; y <= 1; y++)
    {
        for (int x = -1; x <= 1; x++)
        {
            vec2 neighbor = vec2(x, y);
            
            vec2 point = random2(i + neighbor);
            
            point = 0.5 + 0.5 * sin(time + 6.2831 * point);
            
            float dist = length(neighbor + point - f);
            
            minDist = min(minDist, dist);
        }
    }
    
    // mouse control
    vec2 mouse = mouse*resolution.xy.xy / resolution.xy;
    mouse.x *= resolution.x / resolution.y;
    mouse *= cellNum;
    mouse -= i;
    
       float dist = length(mouse - f);
    
       minDist = min(minDist, dist);
    
    glFragColor = vec4(vec3(minDist),1.);
}
