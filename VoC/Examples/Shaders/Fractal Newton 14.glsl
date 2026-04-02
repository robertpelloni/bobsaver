#version 420

// original https://www.shadertoy.com/view/3lSXz1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define THRESHOLD 0.000001
#define MAX_ITERATIONS 100
#define ANTI_ALIASING 2

vec2 f(vec2 z) {
    float magnitude = dot(z, z);
    return (2.0 * z + vec2(z.x * z.x - z.y * z.y, -2.0 * z.x * z.y) / (magnitude * magnitude)) / 3.0;
}

vec2 roots[] = vec2[](
    vec2(1.0, 0.0),
    vec2(-0.5, 0.5 * sqrt(3.0)),
    vec2(-0.5, -0.5 * sqrt(3.0))
);

vec3 palette[] = vec3[](
    vec3(1.0, 0.0, 0.0),
    vec3(0.0, 1.0, 0.0),
    vec3(0.0, 0.0, 1.0)
);

vec3 drawFractal(vec2 z) {
    for (int iterations = 0; iterations < MAX_ITERATIONS; ++iterations) {
        z = f(z);
        
        for (int root = 0; root < roots.length(); ++root) {
            vec2 difference = z - roots[root];
            float distance = dot(difference, difference);
            if (distance < THRESHOLD) {
                return palette[root] * (0.75 + 0.25 * cos(0.25 * (float(iterations) - log2(log(distance) / log(THRESHOLD)))));
            }
        }
    }
}

void main(void) {
    float zoom = exp(-5.0 * (0.9 - cos(time / 5.0)));
    vec2 center = vec2(0.14918, 0.09001);
    
    vec3 color = vec3(0);
    
    for (int x = 0; x < ANTI_ALIASING; ++x) {
        for (int y = 0; y < ANTI_ALIASING; ++y) {
            color += drawFractal(center + zoom * ((2.0 * (gl_FragCoord.xy + vec2(x, y) / float(ANTI_ALIASING)) - resolution.xy) / resolution.y - center));
        }
    }
    
    glFragColor = vec4(color / float(ANTI_ALIASING * ANTI_ALIASING), 1.0);
}
