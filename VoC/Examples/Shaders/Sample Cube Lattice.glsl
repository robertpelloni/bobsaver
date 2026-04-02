#version 420

// original https://www.shadertoy.com/view/lltyzX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
 * Started from: https://www.youtube.com/watch?v=yxNnRSefK94
 * 
 * Just a quick GLSL/Raymarching experiment.
 *
 **/

#define GRID_CELL_SIZE 3.0
#define GRID_SIZE (GRID_CELL_SIZE + 1.0)
#define GRID_MOD (GRID_SIZE * 2.0)

float map(vec3 p)
{
    float t1 = time * 0.5;
    p.x += sin(p.y) * 0.2;
    p.y += sin(p.x) * 0.2;
    vec3 q = fract(p) * 2.0 - 1.0;
    q = clamp(q, -0.33, 0.33);
    return length(q) - 0.33;
}

float trace(vec3 o, vec3 r)
{
    float t = 0.0;
    for (int i = 0; i < 32; ++i)
    {
        vec3 p = o + r * t;
        float d = map(p);
        t += d * 0.5;
    }
    
    return t;
}

bool circle(in float r, in vec2 o, in vec2 v)
{
    return (length(o - v) <= r) ? true : false;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy;

    bool in_circle = circle(GRID_CELL_SIZE, uv - mod(uv, GRID_MOD) + vec2(GRID_SIZE), uv);

    vec3 color = vec3(0.0, 0.0, 0.0);
    if (in_circle)
    {
        uv /= resolution.xy;
        uv = uv * 2.0 - 1.0;
        uv.x *= resolution.x / resolution.y;

        vec3 r = normalize(vec3(uv, 1.0));
        
        float the1 = sin(time * 0.1) * 5.0;
        float the2 = time * 0.25;
        r.xz *= mat2(cos(the1), -sin(the1), sin(the1), cos(the1));
        r.xy *= mat2(cos(the2), -sin(the2), sin(the2), cos(the2));

        float t1 = time * 0.5;
        vec3 o = vec3(cos(t1), sin(t1), 0.0);
        
        float t = trace(o, r);
        
        float fog = 1.0 / (1.0 + t * t * 0.25);
        
        r = sin(r + time * 2.5);
        r *= 0.5;
        r += 1.0;
        color = vec3(fog) * vec3(r.x, r.y, r.z);
    }

    glFragColor = vec4(color, 1.0);
}
