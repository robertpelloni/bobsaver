#version 420

// original https://www.shadertoy.com/view/wsGGDz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define SIN(a) smoothstep(-4., 2.5, sin(a))
#define SIN2(a) (SIN(a)*SIN(a))

vec2 rot(vec2 p, float a)
{
    vec2 i = vec2(cos(a), sin(a));
    return vec2(p.x*i.x - p.y*i.y, p.x*i.y + p.y*i.x);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (2.*gl_FragCoord.xy - resolution.xy)/resolution.y;

    uv.x += .1*sin(uv.y*uv.x*40.);
    
    uv += rot(uv, length(uv+time));
    
    vec2 tuv = abs(log(-uv*.005 + 0.909));
    
    
    float v = 1.01 -.0005;
    // Time varying pixel color
    vec3 col = vec3(
        SIN2(20./pow(tuv.x,v*v*v)),
        SIN2(20./pow(tuv.x,v*v)),
        SIN2(20./pow(tuv.x,v))
    )/length(tuv*7.);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
