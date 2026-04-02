#version 420

// original https://neort.io/art/c2cvkvk3p9f8s59b9kbg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

float n = 3.0;

//function-----------------------------------------------------------------------------------
vec2 repeat(vec2 pos)
{
    return fract(pos * n);
}

//primitive----------------------------------------------------------------------------------
float lineCross(vec2 pos)
{
    // horizontal
    float h = step(0.0, pos.x) * step(0.95, 1.0 - pos.x);
    
    // Vertical
    float v = step(0.0, pos.y) * step(0.95, 1.0 - pos.y);
    return clamp(h + v, 0.0, 1.0);
}

float metaball(vec2 pos, vec2 offset, float scale)
{
    pos = pos - offset;
    float len = length(pos);
    float d = 0.0;
    
    if(len < scale)
    {
        d = (1.0 - len / scale);
    }
    return smoothstep(0.0, 0.97, d);
}

//map----------------------------------------------------------------------------------------
float map(vec2 pos)
{
    return lineCross(repeat(pos));
}

float map2(vec2 pos)
{
    float ball = 0.0;
    float speed = 1.0;
    float scale = 0.8;
    
    for(float i = 0.0; i < 10.0; i++)
    {
        float x = float(i) * 1.0;
        float y = float(10.0 - i) * 0.18;
        float moveX = cos(x + time * speed) * 1.5;
        float moveY = sin(y + time * speed) * 1.1 / cos(y + time);
        
        ball += metaball(pos, vec2(moveX ,moveY), scale);
    }
    return ball;
}

//main---------------------------------------------------------------------------------------
void main(void) 
{
    vec2 pos = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    vec3 col = vec3(map(pos)) * vec3(map2(pos));
    
    glFragColor = vec4(col, 1.0);
}
