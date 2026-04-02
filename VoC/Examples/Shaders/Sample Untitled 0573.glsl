#version 420

// 050720N Simplified

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;

out vec4 glFragColor;

const vec3 tint = vec3(1,.8,.4);
const vec3 bgColor = vec3(1,.8,.4);

#define MODE_2
#define ITERATIONS 15.

void main()
{
    vec2 p=(2.0*gl_FragCoord.xy-resolution)/min(resolution.x,resolution.y);
    
    for(float i = 1.; i < ITERATIONS; ++i)
    {
        p.x += .75 / i * sin(i * p.y) + 1. + time * 0.02;
        p.y += .75 / i * cos(i * p.x) + 2. + time * 0.02;
    }
    vec3 col;
    
#ifdef MODE_1
    col=vec3(sin(p.x), sin(p.y), 1);
#endif
    
#ifdef MODE_2
    col = bgColor - vec3(sin(p.x) - sin(p.y));
#endif
    
#ifdef MODE_3
    col=vec3(sin(p.x) - sin(p.y), sin(p.y) - sin(p.x), cos(p.x) - cos(p.y));
#endif

    glFragColor=vec4(col, 1.0);
}
