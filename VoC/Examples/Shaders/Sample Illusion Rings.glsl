#version 420

// original https://www.shadertoy.com/view/wsGBRR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// the rings are always stationary
// the arrows give the mind the illusion the rings are moving or changing size

#define PI            3.14159265358979
#define RADIUS        0.5
#define THICKNESS    0.1
#define BORDER        0.002
#define SPEED        8.0
#define STRIPS        3.0

float segDist (in vec2 p, in vec2 a, in vec2 b) {
    p -= a;
    b -= a;
    return length (p - b * clamp (dot (p, b) / dot (b, b), 0.0, 1.0));
}

void main(void) {
    vec2 p = gl_FragCoord.xy;

    // Normalization of the fragment coordinates
    p = (2.0 * p - resolution.xy) / resolution.y;

    // Background color
    glFragColor = vec4 (vec3 (0.5 + 0.05 * cos (p.x * 50.0) * cos (p.y * 50.0)), 1.0);

    // Select the animation
    float select = floor (6.0 * fract (time * 0.03 + step (0.0, p.x) / 3.0));

    // Display the rings & marker
    p.x = abs (p.x) - RADIUS * 1.6;

    float d = length (p);
    float a = STRIPS * atan (p.y, p.x);
    float t = time * SPEED * STRIPS;

    vec4 c = vec4 (1.0, smoothstep (-0.05, 0.05, cos (t + a)), 0.0, 1.0);
    glFragColor = mix (glFragColor, c, step (abs (d - RADIUS), THICKNESS));

    float dt;
    float m;
    if (select < 1.5) {
        dt = PI * (0.5 + select);
        m = abs (d - 0.05 - 0.1 * select);
    } else {
        a *= 1.0 - 1.0 / STRIPS;
        dt = PI * 0.5 * (select - 2.0);
        vec2 tip = 0.15 * vec2 (-sin (dt), cos (dt));
        m = segDist (p, -tip * 0.5, tip);
        m = min (m, segDist (p, tip, tip * 0.7 + 0.3 * vec2 (tip.y, -tip.x)));
        m = min (m, segDist (p, tip, tip * 0.7 - 0.3 * vec2 (tip.y, -tip.x)));
    }
    glFragColor.rgb *= smoothstep (0.025, 0.026, m);

    c.g = smoothstep (-0.05, 0.05, cos (t + dt + a));
    glFragColor = mix (glFragColor, c, smoothstep (BORDER * 1.1, BORDER, abs (d - RADIUS - THICKNESS)));
    c.g = 1.0 - c.g;
    glFragColor = mix (glFragColor, c, smoothstep (BORDER * 1.1, BORDER, abs (d - RADIUS + THICKNESS)));
}
