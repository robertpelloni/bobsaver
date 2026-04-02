#version 420

// original https://www.shadertoy.com/view/WlSGRz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/min(resolution.x, resolution.y);

    float speed = 0.5f;
    vec2 p = uv * 5.0f;
    for (int i = 1; i < 10; ++i)
    {
        float fi = float(i);
        vec2 mouse = mouse*resolution.xy.xy / 1000.0f;
        p.x += 0.2f / fi * sin(fi * 3.0f * p.y + time * speed) + mouse.x;
        p.y += 0.2f / fi * sin(fi * 3.0f * p.x + time * speed) + mouse.y;
    }
    
    vec3 col1 = vec3(1, 0, 0.25); // off1 color (primary)
    vec3 col2 = vec3(0, 0.3f, 1); // off2 color (secondary)
    vec3 col3 = vec3(1, 1, 1);    // off3 color (sub)
    
    // [0, 1]
    float off1 = cos(p.x + p.y) * 0.5f + 0.5f;
    float off2 = sin(p.x + p.y) * 0.5f + 0.5f;
    float off3 = (2.0f - (off1 + off2)) * 0.5f;
       
    // over operator
    vec3 color = vec3(0);
    color = mix(color, col1, off1);
    color = mix(color, col2, off2);
    color = mix(color, col3, off3);
    
    glFragColor = vec4(color, 1.0f);
}
