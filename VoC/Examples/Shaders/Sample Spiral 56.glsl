#version 420

// original https://www.shadertoy.com/view/cltyzs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.14159265359
#define tau 6.28318530718

float lerp(float a, float b, float cf)
{
    return a + (b - a) * cf;
}

float remap(float x, float a, float b, float A, float B)
{
    float cf = (x - a) / (b - a);
    return lerp(A, B, cf);
}

float circle(float x, float y, float r)
{
    return length(vec2(x, y)) - r;
}

float ring(float c, float thickness)
{
    float res = 1.0 - abs(c) / thickness;
    return clamp(res, 0.0, 1.0);
}

vec2 rotate(vec2 v, float a)
{
    float x = v.x;
    float y = v.y;
    
    float sina = sin(a);
    float cosa = cos(a);
    
    float xx = x * cosa - y * sina;
    float yy = y * cosa + x * sina;
    
    return vec2(xx, yy);
}

float spiral(float r0, float dr, float thickness, vec2 uv)
{    
    float k = 0.0;
    
    for (float r = r0; r >= 0.0; r -= dr)
    {
        float ang = atan(uv.y, uv.x);
        
        float factor = (r - dr) / r;
        float rk = remap(ang, -pi, pi, factor, 1.0);

        float c = circle(uv.x, uv.y, r * rk);
        c = ring(c, thickness);
        
        k = max(k, c);
    }
    
    return k;
}

vec2 disturb(vec2 uv, float periods, float ampl)
{
    float a = atan(uv.y, uv.x);
    a *= periods;
    
    return vec2(
        remap(sin(a), -1.0, 1.0, -ampl, ampl),        
        remap(cos(a), -1.0, 1.0, -ampl, ampl)
    );
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv *= 2.0; uv -= 1.0; uv.x *= resolution.x / resolution.y;
    
    //uv += disturb(uv, 25.0, 0.025);
    
    float bias = mod(time * 2.0, tau) - pi;
    uv = rotate(uv, bias);
    
    float dr = 0.15;
    float thickness = 0.01;
    float r = 0.8;
    
    float k = 0.0;
    
    for (float i = 0.0; i < 5.0; ++i)
    {        
        float offset = i * -0.02;
        k = max(k, spiral(r + offset, dr, thickness, uv));
    }
        
    k = smoothstep(0.05, 0.9, k);
    
    vec3 clr = vec3(0.7, 0.7, 0.7) * k;
    glFragColor = vec4(clr, 1.0);
}
