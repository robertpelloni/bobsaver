#version 420

// original https://www.shadertoy.com/view/WdySDz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define _MaxRep 25.

float circle(vec2 uv, float rad, float thi, vec2 center)
{
    float r = length(uv-center);
    r = abs(r-rad);
    float w = 10./resolution.y;
    r = smoothstep(thi+w,thi-w, r);
    return r;
}

float animation(vec2 uv)
{
    float a = 0.;
    float rad = 0.8;
    float thi = 0.007;
    vec2 center = vec2(0.,0.);
    float decrease = rad*0.05;
    for(float i= 0.; i < _MaxRep; i++)
    {
        center.x = decrease*sin(2.*time+i+1.);
        center.y = decrease*cos(time+i+1.);
        a += circle(uv, rad, thi, center);
        rad -= decrease;
    }
    return a;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    vec3 col = vec3(abs(uv.x),0.1,0.2);
    col *= animation(uv);
    glFragColor = vec4(col,1.0);
}
