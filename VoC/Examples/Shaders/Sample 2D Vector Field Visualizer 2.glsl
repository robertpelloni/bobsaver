#version 420

// original https://www.shadertoy.com/view/wsVfzc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define GRID_SCALE 0.1
#define CELL_SCALE 1.0
#define VECTOR_SCALE 0.35

float sdIsosceles(in vec2 p, in float b, in float h) {
    p.x = abs(p.x);
    float q = clamp((b - p.x + p.y) / (b + h), 0.0, 1.0);
    vec2 re = vec2(p.x - b + b * q, p.y - h * q);
    vec2 be = vec2(p.x - b * min(p.x / b, 1.0), p.y);
    return sqrt(min(dot(re, re), dot(be, be))) * sign(p.x + (p.y - h) * b / h * sign(p.y));
}

float sdVerticalLine(in vec2 p, in float h) {
    return length(vec2(p.x, p.y - h * clamp(p.y / h, 0.0, 1.0)));
}

float sdVectorArrow(in vec2 p, in vec2 v) {
    float m = length(v);
    vec2 n = v / m;
    p = vec2(dot(p, n.yx * vec2(1.0, -1.0)), dot(p, n));
    return min(sdVerticalLine(p, m), sdIsosceles(p - vec2(0.0, m), 0.1, 0.15));
}

vec2 VectorField(in vec2 p) {
    // Uncomment the next two lines for an interactive vector field or customize it!
    //vec2 mouse = (0.5 * resolution.xy - mouse*resolution.xy.xy) / resolution.y / GRID_SCALE;
    //return normalize(p + mouse).yx * vec2(1.0, -1.0);
    return vec2(sin(p.y + time), sin(p.x + time));
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    vec4 cell = vec4(floor(uv / GRID_SCALE / CELL_SCALE) * CELL_SCALE, mod(uv / GRID_SCALE, CELL_SCALE) - 0.5 * CELL_SCALE);
    float unit = 2.0 / resolution.y / GRID_SCALE;
    float vector = sdVectorArrow(cell.zw, VectorField(cell.xy) * VECTOR_SCALE);
    glFragColor = vec4(smoothstep(unit, 0.0, vector));
}
