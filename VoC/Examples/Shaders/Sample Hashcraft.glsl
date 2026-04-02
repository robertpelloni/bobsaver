#version 420

// original https://www.shadertoy.com/view/Md3BW2

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// LICENSE: http://unlicense.org/
#define SCALE 13

vec4 hash( uvec2 p)
{   
    uvec2 r = p ^ (p << ((p.x + p.x + p.x + p.x + p.y) >> SCALE));
    uvec2 g = p ^ (p << ((p.x + p.y + p.y + p.y) >> SCALE));
    uvec2 b = p ^ (p << ((p.x + p.x + p.y) >> SCALE));            
    uvec2 a = p ^ (p << ((p.x + p.y) >> SCALE));      
        
    uvec4 n = uvec4((r.x & r.y) - r.x, (g.x & g.y) - g.x, (b.x & b.y) - b.x, (a.x & a.y) - a.x);
    n ^= (n << 21U);
    n ^= (n << (n >> 27U));
    
    return vec4(n) * (1.0/float(0xffffffffU));
}

void main(void)
{
    uvec2 uv = uvec2(gl_FragCoord);

    vec4 col = hash(uv+uvec2(4U << SCALE)+uvec2(1U,3U)*uint(frames));
    
    glFragColor = vec4(sqrt((col.xyz+col.yzw)*0.5),1.0);
}
