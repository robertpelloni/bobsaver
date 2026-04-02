#version 420

// original https://www.shadertoy.com/view/NsjGRD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926538

float nsin(in float x)
{
    return sin(x) * 0.5 + 0.5;
}

void main(void)
{
    vec2 st = gl_FragCoord.xy/resolution.y;
    st.x += (1.0 - resolution.x/resolution.y) * 0.5;
    float thickness = 0.005;
    float alias = 3.0 / resolution.x;
    float speed = 0.05;
    float t = time * speed;
    vec3 color;
    for (int i = 0; i < 50; i += 1) {
        float outer = sin((float(i) / 50.0) * PI * 2.0 + t) * 0.25 + 0.25;
        float a = atan(st.y - 0.5, st.x - 0.5);
        float d = distance(st, vec2(0.5));
        float f = d
            + sin(time * speed * 4.1 + st.y * 10.0) * 0.01
            + sin(time * speed * 4.6 + st.x * 9.0) * 0.015
            + sin((a + t) * 16.0) * 0.05 * d
            + sin((0.31 + a + t * 0.77) * 6.0) * 0.03 * d;
        f *= 1.05;
        float v =
            smoothstep(outer, outer - alias, f)
            - smoothstep(outer - thickness, outer - thickness - alias, f);
        color += vec3(
            sin(float(i) * nsin(0.2 + t * 1.23)) * 0.5 + 0.5,
            sin(float(i) * nsin(2.0 + t * 1.67)) * 0.5 + 0.5,
            sin(float(i) * nsin(1.0 + t * 1.76)) * 0.5 + 0.5
        ) * v;
    }
    glFragColor = vec4(color,1.0);
}
