#version 420

// original https://www.shadertoy.com/view/tscBW2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define gray(rgb) (rgb.r * 0.299 + rgb.g * 0.587 + rgb.b * 0.114)
#define cmpv(v, b) (v.x > b.x && v.y > b.y && v.x < (b.x + 1.0) && v.y < (b.y + 1.0))
#define m_p 3.14155
#define norm(a) (a + 1.0) * 0.5
//#define norm(a) abs(a)
//#define COLORED_OFF

vec2 calcAspect(vec2 iRes)
{
    vec2 aspect = vec2(float(iRes.x < iRes.y) * iRes.x / iRes.y,
                       float(iRes.y < iRes.x) * iRes.y / iRes.x);
    aspect.x += float(aspect.x == 0.0);
    aspect.y += float(aspect.y == 0.0);
    return aspect;
}

//------------------------------------------------------------
float waves(vec2 p, vec2 s, float t)
{
    p *= s * m_p;
    return norm(sin(sin(p.x - t) - p.y));
}

//------------------------------------------------------------
float radial(vec2 p, float s, float t)
{
    return norm(sin(length(p) / s - t));
}

//------------------------------------------------------------
float spiral(vec2 p, float s, float t)
{
    float e = exp(length(p)); /*can also try pow(l,l) or sqrt(l)*/
    return norm(sin((exp(length(p)) - s * atan(p.y, p.x) - t) / s));
}

//------------------------------------------------------------
float windmill(vec2 p, float c, float w, float t)
{
    float sl = sin(length(p)) * w;
    return norm(sin((atan(p.x, p.y) / (1.0 / c) - sl) + t));
}

//------------------------------------------------------------
float angles(vec2 p, float s, float t)
{
    return norm(sin(p.x * p.y / s - t));
}

//------------------------------------------------------------
float radial_waves(vec2 p, float s, vec2 w, float t)
{
    float a = atan(p.x, p.y) / (1.0 / w.x);
    return norm(sin(length(p) / s / norm(sin(a) + w.y) - t));
}

//------------------------------------------------------------
float windmill_waves(vec2 p, float c, float w, float t)
{
    float sl = sin(length(p) * w - t);
    return norm(sin((atan(p.x, p.y) / (1.0 / c) - sl) + t));
}

//------------------------------------------------------------
float spiral_waves(vec2 p, float s, float w, float t)
{
    float l = exp(sin(length(p)));
    float a = atan(p.y, p.x);
    
    return norm(sin((l - s * (a - sin(a * w - t) + t)) / s));
}

//------------------------------------------------------------
float double_waves(vec2 p, vec2 s, float w, float t)
{
    p *= s * m_p;
    p += norm(sin(p.y * w - t));
    return norm(sin(sin(p.x - t)  - p.y));
}
//------------------------------------------------------------

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 aspect = calcAspect(resolution.xy);
    vec2 auv = uv * aspect;
    const vec2 cells = vec2(3, 3);
    vec2 cell = cells * uv;
    vec2 cc = (floor(cell) + 0.5) / cells * aspect;
    vec2 v = cc - auv;
    
    float g = 0.0;
    
    if(cmpv(cell, vec2(0.0, 0.0)))
    {
        g = waves(auv, vec2(16.0, 32.0), time);
    }
    else if(cmpv(cell, vec2(1.0, 0.0)))
    {
        g = radial(v, 0.008, time);
    }
    else if(cmpv(cell, vec2(2.0, 0.0)))
    {
        g = windmill(v, 8.0, 40.0, time);
    }
    else if(cmpv(cell, vec2(0.0, 1.0)))
    {
        g = spiral(v, 0.008, time * 0.02);
    }
    else if(cmpv(cell, vec2(1.0, 1.0))) 
    {
        g = angles(v, 0.0008, time);
    }
    else if(cmpv(cell, vec2(2.0, 1.0)))
    {   
        g = radial_waves(v, 0.0005, vec2(8.0, 10.0), time);
    }
    else if(cmpv(cell, vec2(0.0, 2.0)))
    {
        g = double_waves(auv, vec2(16.0, 32.0), 1.2, time);
    }
    else if(cmpv(cell, vec2(1.0, 2.0)))
    {
        g = spiral_waves(v, 0.008, 8.0, time);
    }
    else if(cmpv(cell, vec2(2.0, 2.0)))
    {
        g = windmill_waves(v, 8.0, 120.0, time);
    }

    vec2 rc = cells / cell;
    
    vec3 col = norm(vec3(sin(time), sin(time + 1.0), sin(time + 2.0))) * 2.0;
    #ifdef COLORED_OFF
        col = vec3(1.0);
    #endif
    // Output to screen
    glFragColor = vec4(col * g, 1.0);
}
