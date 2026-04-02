#version 420

// original https://www.shadertoy.com/view/lsKfWy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = gl_FragCoord.xy * 5.0 / resolution.xy - 1.0;
    float d = 0.0;
    for (float i = 0.0; i < 200.0; ++i) {
        float j = max(0.0, 3.14 - distance(uv, vec2(
            sin(i + time * mod(i * 2633.2363, 0.42623)) * 12.0,
            cos(i  * 0.617 + time * mod(i * 36344.2363, 0.52623)) * 12.0
        )));
        d += cos(j);
     }
    float r = cos(d * 6.0) * 0.5 + 0.5;
    float g = cos(d * 3.0) * 0.5 + 0.5;
    glFragColor = vec4(r, g, max(r, g), 1.0);
}
