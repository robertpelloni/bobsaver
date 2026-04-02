#version 420

// original https://www.shadertoy.com/view/WtG3Rc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    float t = time, r = length(uv) / sqrt(2.);
    float pi = 3.14159;
    float k = 3.;
    float w = t + 2. * sin(-3. * t + 12. * r);
    vec2 s = sin(w + 8. * k * pi * uv / (1. + k * r));
    float v = s.x*s.y;
    glFragColor = vec4(v / fwidth(v));
}
