#version 420

// original https://www.shadertoy.com/view/Wdt3WX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.14159265359
float ssin(float x, float s)//aliased sin
{
    return cos(floor(x*s)*pi/s);
}
void main(void)
{
    vec2 u = 4.*(2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec2 m = mouse*resolution.xy.xy/resolution.xy;
    float t = 1060.01109;//+m.x*.001;
    float n = 333.;
    vec4 s = vec4(0.);
    for(float i = .5; i < n; ++i)
    {
        vec2 a = sin(t*i+vec2(0.,pi*.5));
        vec4 b = fract(sin(i)
                   *vec4(6925.953,7925.953,8925.953,9925.953)
                      +time*.05);
        s += ssin(dot(u,a)+t*.001*i,1.)*b;
    }
    s = s/sqrt(n)+4.;
    glFragColor = .5+.5*cos(s+5.5);
}
