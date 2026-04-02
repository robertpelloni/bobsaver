#version 420

// original https://www.shadertoy.com/view/tt2yWV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define C1    vec2 (0.2, 0.55)
#define C2    vec2 (-0.743644, 0.131826)
#define N    900.0
#define PI    3.14159265358979

mat2 Rotate (in float angle)
{
    float c = cos (angle);
    float s = sin (angle);
    return mat2 (c, s, -s, c);
}

float Mandelbrot (in vec2 c)
{
    vec2 m;

    #ifndef NO_OPTIM
    m = vec2 (c.x + 1.0, c.y);
    if (dot (m, m) < 0.0625) {
        return 1.0;
    }

    m = vec2 (c.x - 0.25, c.y);
    float l = dot (m, m);
    if (c.x < sqrt (l) - 2.0 * l + 0.25) {
        return 1.0;
    }
    #endif

    m = c;
    for (float n = 0.0; n < N; ++n) {
        if (dot (m, m) > 4.0) {
            return n / N;
        }
        m = vec2 (m.x * m.x - m.y * m.y, 2.0 * m.x * m.y) + c;
    }
    return 1.0;
}

void main(void)
{
    vec2 c = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;

    float time = time * 0.1;
    float zoom = 1.5 * pow (0.5, 18.0 * (0.5 - 0.5 * cos (time * 2.0)));
    float angle = PI * 6.0 * cos (time);
    vec2 translate = mix (C1, C2, smoothstep (-0.4, 0.4, sin (time)));

    c = zoom * Rotate (angle) * c + translate;
    float m = Mandelbrot (c);
    glFragColor = vec4 (m, pow (m, 0.6), pow (m, 0.3), 1.0);
}
