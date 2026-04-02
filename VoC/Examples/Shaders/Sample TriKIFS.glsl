#version 420

// original https://neort.io/art/c819dis3p9f3k6tguudg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;

out vec4 glFragColor;

#define PI 3.141592

vec2 Set(float a)
{
    return vec2(sin(a), cos(a));
}

void main()
{
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / min(resolution.x, resolution.y);
    vec3 col = vec3(0.);
    vec2 uvT = uv;
    float t = time *.4;
    float s = sin(t*.2);
    float c = cos(t*.2);
    uv *= mat2(c, -s, s, c);
    
    vec2 mouseIn = (mouse+1.)/2.+.5; // 0-1

    uv *= 1.25;
    uv.x = abs(uv.x);
    float angle = (5./6.)*PI;
    uv.y += tan(angle) * .5;
    vec2 n = Set(angle);
    float k = dot(uv - vec2(.5, 0.), n);
    uv -= n*max(k, 0.)*2.;
    
    n = Set(mouseIn.x*(2./3.)*PI);
    
    float scale = 1.;
    uv.x += .5;
    for(int i = 0; i < 4; i++)
    {
        uv *= 3.;
        scale *= 3.;
        uv.x -= 1.5;

        uv.x = abs(uv.x);
        uv.x -= .5;
        uv -= n*min(dot(uv, n), 0.)*2.;
    }

    float d, alpha=1.;

    for(int i = 0; i < 3; i++)
    {
        scale *= .3;
        float it = +float(i);
        d = length(uv - vec2(clamp(uv.x, -1. , 1.), 0));
        col += smoothstep(10./resolution.y, .0, d/scale);
        
        float r = (it+1.) * .05;
        d = length(uv - vec2(.5, 0.5*sin(t*3.25+it) + .5)) - r;
        col += smoothstep(6./resolution.y, .0, d/scale);
        d = length(uv - vec2(0.5*cos(t*2.56+it), -.35)) - r;
        col += smoothstep(6./resolution.y, .0, d/scale);
        
        uv /= 5.;
    }

    glFragColor = vec4(col, 1.0);
}

