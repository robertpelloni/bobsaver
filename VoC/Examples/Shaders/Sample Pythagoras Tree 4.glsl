#version 420

// original https://www.shadertoy.com/view/7sdfz4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float cross2(vec2 a, vec2 b) {
    return a.x * b.y - a.y * b.x;
}

const int n = 5;

vec2 pts[n] = vec2[n](
    vec2(-1.0, 1.0),
    vec2(0.0, 2.0),
    vec2(1.0, 1.0),
    vec2(1.0, -1.0),
    vec2(-1.0, -1.0)
);

const int l = 8;

vec2 trans(vec2 a1, vec2 a2, vec2 b1, vec2 b2, vec2 c) {
    vec2 t = a2 - a1;
    t /= dot(t, t);
    vec2 s = b2 - b1;
    return mat2(
        -s.x, -s.y,
        s.y, -s.x
    ) * mat2(
        t.x, -t.y,
        t.y, t.x
    ) * (c - a1) + b2;
}

bool checkIn(vec2 c) {
    bool a = true;
    for (int i = 0; i < n; i++) {
        if (cross2(c - pts[i], pts[(i + 1) % n] - pts[i]) <= -0.000001) {
            a = false;
        }
    }
    return a;
}

void main(void) {
    float x = time;
    pts = vec2[n](
        vec2(-1.0, 1.0),
        vec2(cos(x), 1.0 + abs(sin(x))),
        vec2(1.0, 1.0),
        vec2(1.0, -1.0),
        vec2(-1.0, -1.0)
    );

    vec2 uv = (gl_FragCoord.xy / resolution.xy - 0.5) * 2.0 * vec2(resolution.x / resolution.y, 1.0);

    vec2 c = uv * 4.0 + vec2(0.0, 3.0);

    vec4 o = vec4(0.0);
    for (int j = 0; j < l; j++) {
        for (int k = 0; k < (1 << j); k++) {
            vec2 d = c;
            for (int i = 0; i < j; i++) {
                if ((k & (1 << i)) == 0) {
                    d = trans(pts[0], pts[1], pts[3], pts[4], d);
                } else {
                    d = trans(pts[1], pts[2], pts[3], pts[4], d);
                }
            }
            if (checkIn(d)) {
                o += (0.3 + 0.7 * float(l - j - 1) / float(l - 1)) *
                    vec4(1.0, (float(k) + 0.5) / float(1 << j), 0.4, 0.0);
            }
        }
    }

    glFragColor = o;
}
