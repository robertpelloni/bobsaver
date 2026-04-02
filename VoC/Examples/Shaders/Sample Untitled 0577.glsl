#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wd3yDS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define td 1.
#define nCircles 64
#define PI 3.141592
#define dog 0.25

vec2 rotate2D(vec2 _st, float _angle)
{
    _st -= 0.5;
    _st = mat2(
        cos(_angle),-sin(_angle),
        sin(_angle),cos(_angle)
    ) * _st;
    _st += 0.5;
    
    return _st;
}

float ring(float e0, float d, float f)
{
    return smoothstep(e0, e0 + d, f) - smoothstep(e0 + d, e0 + 2. * d, f);
}

void main(void)
{
    // Normalize uv and account for aspect ratio
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    float ar = resolution.x / resolution.y;
    uv.x = (uv.x - 0.5) * ar + 0.5;

    // Preserve original uv
    vec2 p = uv;
    
    float t = time * td;
    
    float even_t = 0.5 * (tan(t) + 1.0);
    even_t *= -dog;
    
    float odd_t = 0.5 * (tan(t - 0.9) + 1.0);
    odd_t *= -dog;
    
    float rot_t = 2.0 * PI * t * 0.3;
    
    vec3 col = vec3(0.0);
    
    float angle_d = 2.0 * PI / float(nCircles);
    float radius = dog;
    int i = 0;
    for(; i < nCircles; ++i)
    {
        float flag = float(i % 2);
        
        float ang = angle_d * float(i);
        vec2 C = vec2(cos(ang), sin(ang));
        C *= radius * mix(1., .75, flag);
        
        vec2 circ_p = rotate2D(p, mix(-1. * rot_t, rot_t, flag)) - 0.5;
        float f = length(circ_p - C);
        
        for(int j = 0; j < 3; ++j)
        {
            float col_d = float(j) * 0.005;
            float ring_t = mix(odd_t * -1.0, even_t, flag);
            col[j] += ring(dog, 0.004, f + ring_t + col_d);
        }
    }
    
    glFragColor = vec4(col, 1.0);
}
