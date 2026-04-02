#version 420

// original https://www.shadertoy.com/view/tlBBDz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define t time

mat2 r(float a)
{
    float s = sin(a), c = cos(a);
    return mat2(cos(a), sin(a), -sin(a), cos(a));
}

void main(void)
{
    vec2 p = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.x;
    
    p *= r(t*0.247457);
    p += vec2(sin(t * 0.5) * 0.5, cos(t * 0.5) * 0.5);
    
    float c = 0.0;
    
    vec2 s = vec2(-0.1456315 + sin(t * 0.3452) * 0.005, 0.1793245 + sin(t * 0.4313) * 0.003) * acos(-1.0);

    for (int i = 0; i < 512; i++)
    {
        p = vec2(p.x * p.x - p.y * p.y + s.x, p.x * p.y + p.x * p.y + s.y);
        float d = length(p);
        if (d < 2.0)
        {
            c += 1.0;
        }
    }
    c /= 512.0;
    
    vec3 col = pow(vec3(c), vec3(3.0, 2.0, 1.0)) * 10.0;
    col = clamp(col, 0.0, 1.0);
    
    glFragColor = vec4(col, 1);
}
