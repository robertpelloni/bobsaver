#version 420

// original https://www.shadertoy.com/view/fsfBz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_ITER 255

#define MAX_OUTWARD_ZOOM 0.7
#define MAX_INWARD_ZOOM 10000.0
#define THRESHOLD 1.0

vec3 map_color(float it)
{
    return vec3(1.0 - sin(it * 3.14));
}

void main(void)
{
    const vec2 trasl = vec2(-0.7449, 0.1);

    // point on screen between [-1, 1]
    vec2 frag_p = (gl_FragCoord.xy / resolution.xy) * 2.0 - 1.0;

    vec2 mb_c = vec2(0) + trasl; // mandelbrot center point
    vec2 mb_p = frag_p + trasl; // mandelbrot point under analysis 
    
    float s = (abs(mod(time * 0.01, 1.0)) * (MAX_INWARD_ZOOM - MAX_OUTWARD_ZOOM)) + MAX_OUTWARD_ZOOM; // scaling factor
    vec2 zoomed_p = (mb_p - mb_c) * (1.0 / s) + mb_c; // the zoomed point

    vec2 p0 = zoomed_p;
    vec2 p = vec2(0);
    
    float it = 0.0;
    while ((p.x * p.x + p.y * p.y) <= 2.0 * 2.0 && it < float(MAX_ITER))
    {
        float tmp = p.x * p.x - p.y * p.y + p0.x;
        p.y = 2.0 * p.x * p.y + p0.y;
        p.x = tmp;
        it += 1.0;
    }
    
    
    glFragColor = vec4(map_color(it / float(MAX_ITER)), 1.0);
 
}
