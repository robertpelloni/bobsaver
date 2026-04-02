#version 420

// original https://www.shadertoy.com/view/WsccDj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define nSteps 64
#define PI 3.141592
#define dog 0.25

#define cm_A vec3(0.5, 0.5, 0.5)
#define cm_B vec3(0.5, 0.5, 0.5)
#define cm_C vec3(1.0, 1.0, 0.5)
#define cm_D vec3(0.8, 0.9, 0.3)

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

vec3 colormap(float t)
{
    return cm_A + cm_B * cos(2.0 * PI * (cm_C * t + cm_D));
}

void main(void)
{
    // Normalize uv and account for aspect ratio
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    float ar = resolution.x / resolution.y;
    uv.x = (uv.x - 0.5) * ar + 0.5;

    // Preserve original uv
    vec2 p = uv;
    float t = time;
    vec3 col = vec3(0.0);
    
    float cos_t = cos(t * .35);
    cos_t *= 64.0;
    
    p = p - 0.5;
    p *= 1.35;
    
    vec2 polar;
    polar.x = length(dot(p, p));
    polar.y = atan(p.y, p.x) + PI;
    
    float rads = polar.y;
    
    for(int i = 0; i < nSteps; ++i)
    {
        float rd = float(i+1) / float(nSteps);
        float ring_x = sin(rads * 3.0 + rd * cos_t) - 2.0;
        float f = ring(0.01, 0.5, polar.x + ring_x);
        
        col += vec3(f) * colormap(rd * 2. + t * .3);
        
        polar.x *= 1.2;
    }
    col *= .5;
    
    glFragColor = vec4(col, 1.0);
}
