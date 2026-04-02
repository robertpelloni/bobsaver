#version 420

// original https://www.shadertoy.com/view/XlcBRl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Jamie Pendergast

float Wave(vec2 polar, float offset)
{
    return smoothstep(0., 1., sin((polar.x + offset) * 4. + (polar.y * 3.) -(time * 10.)));
}

void main(void)
{
    vec2 uv = -1. + 2. * gl_FragCoord.xy/resolution.xy;
    uv.x *= resolution.x / resolution.y;
    vec2 polar = vec2(atan(uv.x,uv.y),length(uv));
    polar += vec2(time * 0.1);
    float a = Wave(polar,0.);
    polar += vec2(time * 0.3);
    float b = Wave(polar,a + 1.);
    polar += vec2(time * 0.5);
    float c = Wave(polar,b + 2.);
    // Output to screen
    glFragColor = vec4(a,b,c,1.);
}
