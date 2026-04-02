#version 420

// original https://www.shadertoy.com/view/4tcBDn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
 * Fractal Brownian Motion
 *
 * Reference: https://thebookofshaders.com/13/
 * 
 * See also: http://www.iquilezles.org/www/articles/morenoise/morenoise.htm
 */

#define NUM_OCTAVES 5

const vec3 color = vec3(0, 0.745, 0.9);

// Get random value
float random(in vec2 st)
{
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Get noise
float noise(in vec2 st)
{
    vec2 i = floor(st);
    vec2 f = fract(st);
    
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// fractional brown motion
float fbm(in vec2 st)
{
    float v = 0.0;
    float a = 0.5;
    
    for (int i = 0; i < NUM_OCTAVES; i++)
    {
        v += a * noise(st);
        st = st * 2.0;
        a *= 0.5;
    }
    
    return v;
}

void main(void)
{
    vec2 st = gl_FragCoord.xy / resolution.xy;
        
    vec2 q = vec2(0.0);
    q.x = fbm(st);
    q.y = fbm(st + vec2(1.0));
    
    vec2 r = vec2(0.0);
    r.x = fbm(st + 1.0 * q + vec2(1.7, 9.2) + 0.15 * time);
    r.y = fbm(st + 1.0 * q + vec2(8.3, 2.8) + 0.12 * time);
    
    float f = fbm(st + r);
    
    // f^3 + 0.6f^2 + 0.5f
    float coef = (f * f * f + (0.6 * f * f) + (0.5 * f));
    
    glFragColor = vec4(coef * color, 1.0);
}
