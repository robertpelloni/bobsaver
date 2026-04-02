#version 420

// original https://www.shadertoy.com/view/stlGz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define CONST_A  10.0
#define CONST_B  28.0
#define CONST_C  (8.0/3.0)

#define NUM_ITERATIONS 12
#define DT 0.01

vec3 f(in vec3 p, float a, float b, float c)
{
    for (int i = 0; i < NUM_ITERATIONS; i++ )
    {
        vec3 dp;
        dp.x = a * (p.y - p.x);
        dp.y = p.x * (b - p.z) - p.y;
        dp.z = p.x * p.y - c * p.z;
        p += DT * dp;
    } 
    
    return p;
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 hsl2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

    return c.z + c.y * (rgb-0.5)*(1.0-abs(2.0*c.z-1.0));
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy * 2.0 - 1.0;
    
    vec3 p = vec3(uv, 0.0) * 150.0;
    p.z = 150.0 * sin(p.x*0.05+time) * cos(p.y * 0.05 + time * 0.5);
    vec3 q = f(p, CONST_A + 5.0* sin(time + 0.4), CONST_B * sin(time-1.5), CONST_C * sin(time));
    vec3 col = hsv2rgb(normalize(q));
    
    glFragColor = vec4(col,1.0);
}
