#version 420

// original https://www.shadertoy.com/view/3ssfRj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 u = 4.*(2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    float pi = 3.14159265359;

    u /= pow(2.,time*.4);
    u -= vec2(.00008303,.0);

    vec2 v = u;
    float e = 2.;

    for(float i = 0.; i < 32.; ++i)
    {
        u = vec2(atan(u.y,u.x),log(length(u)));
        u = sin(atan(u.x,u.y)*e+vec2(0.,pi*.5))*pow(length(u),e);
        u-= v*v;
    }
    glFragColor = vec4(exp(dot(u,u)*-.02));
}
