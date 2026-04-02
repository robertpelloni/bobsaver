#version 420

// original https://www.shadertoy.com/view/tdsfz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 u = 2.*(2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    float pi = 3.14159265359;
    float p = 1.+sin(time)*.05;
    u *= p;
    vec2 v = u;
    float e = -4.;
    for(float i = 0.; i < 5.; ++i)
    {
        u = sin(atan(u.y,u.x)*e+vec2(0.,pi*.5))*pow(length(u),-1.+4./(e+1.));
        u+= v/p;
    }
    glFragColor = vec4(exp(dot(u,u)*-.1));

}
