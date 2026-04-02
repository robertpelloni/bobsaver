#version 420

// original https://www.shadertoy.com/view/7lXBRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

bool equals(float x, float y, float tol) { return abs(x - y) < tol; }
float vary(float range, float minimum, float offset, float speed) { return (sin(time / speed + offset) + 1.0) / 2.0 * range + minimum; }
float vary(float range, float minimum, float offset) { return vary(range, minimum, offset, 1.0); }

vec4 circle(float radius, float x, float y) {
    float xMid = gl_FragCoord.xy.x - x;
    float yMid = gl_FragCoord.xy.y - y;
    float x2 = xMid * xMid;
    float y2 = yMid * yMid;

    vec4 col = vec4(0.0, 0.0, 0.0, 0.0);
    float detail = 10.0;
    for (float i = 0.0; i < detail; i++) {
        float newRadius = radius - i / detail * radius;
        if (equals(x2 + y2, vary(newRadius, 0.0, 0.0), vary(detail, vary(5000.0, 100.0, 0.0, 2.0), 0.0))) {
            col = vec4(vary(1.0, 0.0, i + 0.0), vary(1.0, 0.0, i + 2.0),vary(1.0, 0.0, i + 3.0), 1.0);
        }
    }
    return col;
}

vec4 backColor(vec2 coord) {
    float offset = (coord.x / resolution.x) * (coord.y / resolution.y);

    return vec4(
        vary(1.0, 0.0, time + offset, 100.0),
        vary(1.0, 0.0, time + offset + 1.0, 100.0),
        vary(1.0, 0.0, time + offset + 2.0, 100.0),
        1.0
    );
}

float rand(float x) {
    return x * 1664525.0 + 1013904223.0;
}

int rand1(int a)
{
    int lim = 1000000;
    a = (a * 125) % 2796203;
    return ((a % lim) + 1);
}

float rand1(float a) { return float(rand1(int(a))); }

void main(void)
{    
    vec4 white = vec4(1.0, 1.0, 1.0, 1.0);
    vec4 grey = vec4(0.5, 0.5, 0.5, 1.0);
    vec4 black = vec4(0.0, 0.0, 0.0, 1.0);
    
    float minRes = min(resolution.x, resolution.y);
    float maxRes = max(resolution.x, resolution.y);
    float radius = (maxRes / 2.0) * (maxRes / 2.0);
    
    glFragColor = backColor(gl_FragCoord.xy);
    vec4 color;
    for (float i = 0.0; i < 50.0; i++) {
        if ((color = circle(radius, vary(1.0, 0.0, sin(i) * i) * resolution.x, vary(1.0, 0.0, cos(i) * i) * resolution.y)).w == 1.0) {
            glFragColor = color;
        }
    }
}
