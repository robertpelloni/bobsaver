#version 420

// original https://www.shadertoy.com/view/ldfBRN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 u = (gl_FragCoord.xy+gl_FragCoord.xy-resolution.xy)/resolution.y;
    u = fract(u) - .5;
    float r = .8, d = step(length(u),r);
    for (int i = 0; i < 9; i++)
    {
        r *= .5 + .1 * sin(float(i) + time);
        if (mod(float(i), 2.) == 0.)
        {
            d -= step(length(u+vec2(0, r)), r);
            d -= step(length(u+vec2(r, 0)), r);
            d -= step(length(u-vec2(0, r)), r);
            d -= step(length(u-vec2(r, 0)), r);
        }
        else
        {
            d += step(length(u+vec2(0, r)), r);
            d += step(length(u+vec2(r, 0)), r);
            d += step(length(u-vec2(0, r)), r);
            d += step(length(u-vec2(r, 0)), r);
        }
        
    }
    glFragColor = vec4(d);
}
