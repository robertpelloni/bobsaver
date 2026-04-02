#version 420

// original https://www.shadertoy.com/view/wllXD8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define N_ITERS 1000
#define PI 3.14159265

vec3 color(float t) {
    vec3 a = vec3(0.5);
    vec3 b = vec3(0.5);
    vec3 c = vec3(1.0);
    vec3 d = vec3(0.0, 0.1, 0.2);
    return a + b * cos(2.0*PI*(c*t + d));
}

vec2 cmul(vec2 c1, vec2 c2) {
    return vec2(c1.x*c2.x - c1.y*c2.y, c1.x*c2.y + c1.y*c2.x);
}

// shortest vector from point 'p' to line L(t)=a + t*n
vec2 line_point_distance(vec2 p, vec2 a, vec2 n) {
    vec2 p2a = a - p;
    return p2a - dot(p2a,n)*n;
}

float shade(vec2 c, vec2 point) {
    vec2 z = vec2(0.0, 0.0);
    float dist = 1.0e20;
    for (int i=0; i<N_ITERS; i++) {
        // quadratic mandlebrot set: z(n+1) = z(n)^2 + c
        z = cmul(z,z) + c;
        if (length(z) > 500.0) break;
        vec2 r = line_point_distance(z, vec2(0.0), point);
        dist = min(dist, r.x*r.x + r.y*r.y);
    }
    return sqrt(dist);
}

float linscale(float x, float x1, float x2, float y1, float y2) {
    return (y2-y1)/(x2-x1) * (x-x1) + y1;
}

vec2 screen_coord(vec2 xy, vec2 dim) {
    return (xy - 0.5*dim) / min(dim.x, dim.y);
}

void main(void) {
    vec2 uv = 2.0*screen_coord(gl_FragCoord.xy, resolution.xy);
    vec2 mouse = 2.0*screen_coord(mouse*resolution.xy.xy, resolution.xy);
    mouse = normalize(mouse);
    float line_d = length(line_point_distance(uv, vec2(0.0), mouse));
    float line = (line_d < 0.01 ? 1.0 : 0.0);
    vec3 fractal_col = color(shade(uv, mouse));
    vec3 col = mix(fractal_col, vec3(1.0), line);
    glFragColor = vec4(col,1.0);
}
