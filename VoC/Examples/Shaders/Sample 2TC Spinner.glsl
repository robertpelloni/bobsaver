#version 420

// original https://www.shadertoy.com/view/Xls3WH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 p = gl_FragCoord.xy - resolution.xy*.5;
    float d = length(p) / resolution.y;
    float a = atan(p.x, p.y)/6.2832;    
    a += time*.1 + d;
    float c = abs((mod(a, .05) / .05)-.5);
    c *= abs(mod(pow(d, .15), .1)/.1 - .5) * 4.;
    glFragColor = vec4(c,c*d,c-d,1.0);
}
