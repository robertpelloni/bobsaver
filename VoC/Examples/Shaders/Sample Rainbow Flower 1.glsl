#version 420

// original https://www.shadertoy.com/view/4djSWm

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

// License: CC0 1.0
// http://creativecommons.org/publicdomain/zero/1.0/

const int iterations = 8;
const float colour_separation = 6.283185307/float(iterations);
float angle_separation;

void main(void)
{
    angle_separation = colour_separation * (sin(time * 0.002)* 16.0 + 16.0);

    vec2 uv = vec2(gl_FragCoord.xy / resolution.xy) * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    float d = dot(uv, uv);
    float a = atan(uv.x, uv.y);
    vec3 c = vec3(0);
    for (int i = 0; i < 16; ++i)
    {
        float x = (pow(d, 0.02) * 2.5 - 2.3 + sin((a + float(i) * angle_separation) *5.0) * 0.1) * 10.0;
        x = x < 1.0 ? x : 2.0 - x;
        vec3 r = vec3(sin(float(i) * colour_separation        ) * 0.5 + 0.5,
                      sin(float(i) * colour_separation + 2.094) * 0.5 + 0.5,
                      sin(float(i) * colour_separation + 4.189) * 0.5 + 0.5);
        c += r*x;
    }
    c = c / float(iterations) * 2.0;
    vec3 f = pow(c, vec3(0.8));
    f *= clamp(c * 2.0, vec3(0.25), vec3(1.0));
    glFragColor = vec4(f, 1.0);
}
