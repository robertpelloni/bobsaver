#version 420

// original https://www.shadertoy.com/view/3sSBzG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define M_PI 3.1415926

// SETTINGS
const float zFar = 200.;
const float zNear = 1.;

const vec3 background_color = vec3(0.2);
const float collision_distance = 0.00001;
const int marching_iterations = 100;

const float normal_partial_derivative_epsilon = 0.00001;

// COLORS
const vec3 red   = vec3(1., 0., 0.);
const vec3 green = vec3(0., 1., 0.);
const vec3 blue  = vec3(0., 0., 1.);

float sq(in float n) {
    return n * n;
}

// Transformations
mat4 worldMatrix = mat4(1., 0., 0., 0.,   0., 1., 0., 0.,   0., 0., 1., 0.,   0., 0., 0., 1.);

void identity() {
    worldMatrix = mat4(1., 0., 0., 0.,   0., 1., 0., 0.,   0., 0., 1., 0.,   0., 0., 0., 1.);
}

void scale(in float a, in float b, in float c) {
    worldMatrix *= mat4(a , 0., 0., 0.,
                        0., b , 0., 0.,
                        0., 0., c , 0.,
                        0., 0., 0., 1.);
}

void trans(in vec3 v) {
    worldMatrix *= mat4(1., 0., 0., v.x,
                        0., 1., 0., v.y,
                        0., 0., 1., v.z,
                        0., 0., 0., 1.);
}

void rotx(in float a) {
    float sina = sin(a);
    float cosa = cos(a);
    worldMatrix *= mat4(1.,   0.,    0., 0.,
                        0., cosa, -sina, 0.,
                        0., sina,  cosa, 0.,
                        0.,   0.,    0., 1.);
}

void roty(in float a) {
    float sina = sin(a);
    float cosa = cos(a);
    worldMatrix *= mat4( cosa, 0., sina, 0.,
                           0., 1.,   0., 0.,
                        -sina, 0., cosa, 0.,
                           0., 0.,   0., 1.);
}

void rotz(in float a) {
    float sina = sin(a);
    float cosa = cos(a);
    worldMatrix *= mat4(cosa, -sina, 0., 0.,
                        sina,  cosa, 0., 0.,
                          0., 0., 1., 0.,
                          0., 0., 0., 1.);
}

// All object functions (like sphere), scene function and functions inter,
// union and diff returns vec4, where .rgb is color and .a is distance.

vec4 inter(in vec4 a, in vec4 b) {
    if (a.a > b.a) {
        return a;
    } else {
        return b;
    }
}

vec4 union_(in vec4 a, in vec4 b) {
    if (a.a < b.a) {
        return a;
    } else {
        return b;
    }
}

vec4 diff(in vec4 a, in vec4 b) {
    if (a.a > -b.a) {
        return a;
    } else {
        return vec4(b.rgb, -b.a);
    }
}

vec4 sphere(in vec3 pos, in vec3 color, in vec3 center, in float radius) {
    return vec4(color, distance(pos, center) - radius);
}

vec4 plane(in vec3 pos, in vec3 color, in float height) {
    return vec4(color, height - pos.y);
}

vec4 cube(in vec3 pos, in vec3 color, in vec3 coords, in vec3 size) {
    return vec4(color, sqrt(sq(max(0., abs(pos.x - coords.x) - size.x)) +
                            sq(max(0., abs(pos.y - coords.y) - size.y)) +
                            sq(max(0., abs(pos.z - coords.z) - size.z))));
}

vec4 xcylinder(in vec3 pos, in vec3 color, in vec3 coords, in float radius) {
    return vec4(color, distance(pos.yz, coords.yz) - radius);
}

vec4 ycylinder(in vec3 pos, in vec3 color, in vec3 coords, in float radius) {
    return vec4(color, distance(pos.xz, coords.xz) - radius);
}

vec4 zcylinder(in vec3 pos, in vec3 color, in vec3 coords, in float radius) {
    return vec4(color, distance(pos.xy, coords.xy) - radius);
}

vec4 scene(vec3 pos) {
    pos = (vec4(pos, 1.) * worldMatrix).xyz;
    pos = mod(pos + 5., 10.) - 5.;
    return diff(inter(cube(pos, red, vec3(0., 0., 0.), vec3(0.9)),
                      sphere(pos, blue, vec3(0., 0., 0.), 1.25)),
                union_(union_(xcylinder(pos, green, vec3(0., 0., 0.), 0.8 * abs(sin(time / 2.))),
                              ycylinder(pos, green, vec3(0., 0., 0.), 0.8 * abs(sin(time / 2.)))),
                       zcylinder(pos, green, vec3(0., 0., 0.), 0.8 * abs(sin(time / 2.)))));
}

vec3 getNormal(in vec3 pos) {
    float x, y, z;
    float E = normal_partial_derivative_epsilon;
    x = scene(pos + vec3(E, 0., 0.)).a - scene(pos - vec3(E, 0., 0.)).a;
    y = scene(pos + vec3(0., E, 0.)).a - scene(pos - vec3(0., E, 0.)).a;
    z = scene(pos + vec3(0., 0., E)).a - scene(pos - vec3(0., 0., E)).a;
    return normalize(vec3(x, y, z));
}

vec3 ray_marching(vec3 pos, vec3 dir) {
    dir = normalize(dir);
    float len = 0.;
    float mindist;
    vec3 color;
    vec3 norm;

    for (int i = 0; i < marching_iterations; ++i) {
        vec4 tmp = scene(pos);
        color = tmp.rgb;
        mindist = tmp.a;
        norm = getNormal(pos);

        if (mindist < collision_distance) return color * max(0.4, dot(normalize(vec3(0.) - pos), norm));
        if (len > zFar) return background_color;

        len += mindist;
        pos += dir * mindist;
    }
    return background_color;
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / vec2(min(resolution.x, resolution.y));
    uv -= (resolution.xy / min(resolution.x, resolution.y) - vec2(1.)) / 2.;
    uv.y = 1. - uv.y;

    identity();
    trans(vec3(0., 0., abs(sin(time / 2. + M_PI / 2.)) * -5.));
    rotx(time + 2.);
    rotz(time + 2.);
    roty(time + 2.);
    vec3 color = ray_marching(vec3(0.), vec3(uv - vec2(0.5), zNear));

    glFragColor = vec4(color, 1.);
}
