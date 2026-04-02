#version 420

// original https://www.shadertoy.com/view/tdyfDK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Copyright © 2020 IWBTShyGuy
// Attribution 4.0 International (CC BY 4.0)

// ------ Configures ------ //
const vec3 RED = vec3(230.0, 0.0, 18.0) / 255.0;
const vec3 GREEN = vec3(0.0, 167.0, 60.0) / 255.0;
const vec3 BLUE = vec3(0.0, 100.0, 180.0) / 255.0;

const uint N_SPHERE = 8u;
const float SPHERE_RADIUS = 0.5;
const float ORBIT_RADIUS = 2.0;
const float ORBIT_VELO = 1.0;
const float ROTATION_VELO = 1.5;
const vec3 ROTATION_AXIS = normalize(vec3(1.0, 2.0, 0.0));

const float SPHERE_DOT_RADIUS = 0.07;
const float BACK_DOT_RADIUS = 0.21;
const float BACK_DOT_INTERVAL = 0.12;
const float BACK_DOT_VELO = 1.5;

// ------ 3D utilities ------ //
const float PI = 3.141592653;

struct Camera {
    vec3 position;
    vec3 direction;
    vec3 up_direction;
    float fov;
    float aspect; // x / y
};

struct Ray {
    vec3 origin;
    vec3 direction;
};

Camera newCamera(vec3 position, vec3 direction, vec3 up_direction, float fov, float aspect) {
    Camera camera;
    camera.position = position;
    camera.direction = direction;
    camera.up_direction = up_direction;
    camera.fov = fov;
    camera.aspect = aspect;
    return camera;
}

// perspective camera ray
// cf: https://qiita.com/aa_debdeb/items/301dfc54788f1219b554
Ray cameraRay(in Camera camera, in vec2 uv) {
    uv = uv * 2.0 - 1.0;
    float radian = camera.fov;
    float h = tan(radian * 0.5);
    float w = h * camera.aspect;
    vec3 right = normalize(cross(camera.direction, camera.up_direction));
    vec3 up = normalize(cross(right, camera.direction));
    vec3 direction = normalize(right * w * uv.x + up * h * uv.y + camera.direction);
    Ray ray;
    ray.origin = camera.position;
    ray.direction = direction;
    return ray;
}

// Rodrigues' rotation formula
mat3 rot(vec3 axis, float angle) {
    return mat3(
        axis[0] * axis[0] * (1.0 - cos(angle)) + cos(angle),
        axis[0] * axis[1] * (1.0 - cos(angle)) + axis[2] * sin(angle),
        axis[0] * axis[2] * (1.0 - cos(angle)) - axis[1] * sin(angle),
        axis[0] * axis[1] * (1.0 - cos(angle)) - axis[2] * sin(angle),
        axis[1] * axis[1] * (1.0 - cos(angle)) + cos(angle),
        axis[1] * axis[2] * (1.0 - cos(angle)) + axis[0] * sin(angle),
        axis[0] * axis[2] * (1.0 - cos(angle)) + axis[1] * sin(angle),
        axis[1] * axis[2] * (1.0 - cos(angle)) - axis[0] * sin(angle),
        axis[2] * axis[2] * (1.0 - cos(angle)) + cos(angle)
    );
}

bool depthTest(in Ray ray, in vec3 current_position, in vec3 new_position) {
    float dist0 = distance(ray.origin, current_position);
    float dist1 = distance(ray.origin, new_position);
    return dist0 > dist1;
}

// ------ sphere ------ //
struct Sphere {
    vec3 center;
    float radius;
};

Sphere newSphere(in vec3 center, in float radius) {
    Sphere sphere;
    sphere.center = center;
    sphere.radius = radius;
    return sphere;
}

const float A = (sqrt(5.0) + 1.0) / 2.0;
const float B = (sqrt(5.0) - 1.0) / 2.0;

const uint N = 32u; // the number of vertices.
const vec3 VERTICES[N] = vec3[](
    normalize(vec3(1.0, 1.0, 1.0)),
    normalize(vec3(1.0, 1.0, -1.0)),
    normalize(vec3(1.0, -1.0, 1.0)),
    normalize(vec3(1.0, -1.0, -1.0)),
    normalize(vec3(-1.0, 1.0, 1.0)),
    normalize(vec3(-1.0, 1.0, -1.0)),
    normalize(vec3(-1.0, -1.0, 1.0)),
    normalize(vec3(-1.0, -1.0, -1.0)),
    normalize(vec3(0.0, A, B)),
    normalize(vec3(0.0, A, -B)),
    normalize(vec3(0.0, -A, B)),
    normalize(vec3(0.0, -A, -B)),
    normalize(vec3(A, B, 0.0)),
    normalize(vec3(A, -B, 0.0)),
    normalize(vec3(-A, B, 0.0)),
    normalize(vec3(-A, -B, 0.0)),
    normalize(vec3(B, 0.0, A)),
    normalize(vec3(B, 0.0, -A)),
    normalize(vec3(-B, 0.0, A)),
    normalize(vec3(-B, 0.0, -A)),
    normalize(vec3(0.0, 1.0, A)),
    normalize(vec3(0.0, 1.0, -A)),
    normalize(vec3(0.0, -1.0, A)),
    normalize(vec3(0.0, -1.0, -A)),
    normalize(vec3(1.0, A, 0.0)),
    normalize(vec3(1.0, -A, 0.0)),
    normalize(vec3(-1.0, A, 0.0)),
    normalize(vec3(-1.0, -A, 0.0)),
    normalize(vec3(A, 0.0, 1.0)),
    normalize(vec3(A, 0.0, -1.0)),
    normalize(vec3(-A, 0.0, 1.0)),
    normalize(vec3(-A, 0.0, -1.0))
);

bool onSphere(in Ray ray, in Sphere sphere, out vec3 intersection) {
    vec3 to_center = sphere.center - ray.origin;
    vec3 h = to_center - dot(to_center, ray.direction) * ray.direction;
    float d2 = sphere.radius * sphere.radius - dot(h, h);
    if (d2 < 0.0) return false;
    intersection = ray.origin + (dot(to_center, ray.direction) - sqrt(d2)) * ray.direction;
    return true;
}

// ------ basis function for gradation ------ //
float parab(float t) { return 2.0 * t * t; }

vec3 nowColor(float t) {
    t = fract(t / 3.0) * 3.0;
    float r0 = t < 1.0 ? (t < 0.5 ? 1.0 - parab(t) : parab(1.0 - t)) : 0.0;
    float g = t < 2.0 ? (t < 1.0 ? 1.0 - r0 : (t < 1.5 ? 1.0 - parab(t - 1.0) : parab(2.0 - t))) : 0.0;
    float r1 = 2.0 < t ? (t < 2.5 ? parab(t - 2.0) : 1.0 - parab(3.0 - t)) : 0.0;
    float b = 1.0 < t ? 1.0 - g - r1 : 0.0;
    return (r0 + r1) * RED + g * GREEN + b * BLUE;
}

Sphere[N_SPHERE] createSpheres(float t) {
    Sphere sphere[N_SPHERE];
    for (uint i = 0u; i < N_SPHERE; i++) {
        float theta = t + 2.0 * PI * float(i) / float(N_SPHERE);
        sphere[i] = newSphere(vec3(sin(theta), 0.0, cos(theta)) * ORBIT_RADIUS, SPHERE_RADIUS);
    }
    return sphere;
}

vec4 backGroundPolka() {
    vec2 uv = gl_FragCoord.xy / resolution.y / BACK_DOT_INTERVAL + BACK_DOT_VELO * time;
    vec2 lattice = uv + 0.5;
    lattice = vec2(floor(lattice.x), floor(lattice.y));
    if (distance(uv, lattice) < BACK_DOT_RADIUS) return vec4(nowColor(time), 1.0);
    else return vec4(0.0, 0.0, 0.0, 1.0);
}

vec3 rotOnSphere(in Sphere sphere, in vec3 position, mat3 rotation) {
    return rotation * (position - sphere.center) + sphere.center;
}

vec4 spherePolka(in Sphere sphere, in vec3 position) {
    for (uint i = 0u; i < N; i++) {
        vec3 dot_center = sphere.radius * VERTICES[i] + sphere.center;
        if (distance(position, dot_center) < SPHERE_DOT_RADIUS) {
            return vec4(nowColor(-time), 1.0);
        }
    }
    return vec4(0.0, 0.0, 0.0, 1.0);
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec3 unit = normalize(vec3(0.0, -0.5, 1.0));
    Camera camera = newCamera(
        -5.0 * unit - vec3(0.0, 0.5, 0.0),
        unit,
        vec3(0.0, 1.0, 0.0),
        PI / 4.0,
        resolution.x / resolution.y
    );
    Ray ray = cameraRay(camera, uv);

    Sphere sphere[N_SPHERE] = createSpheres(ORBIT_VELO * time);
    bool onOneSphere = false;
    vec3 position = vec3(100.0);
    uint idx;
    for (uint i = 0u; i < N_SPHERE; i++) {
        vec3 tmp_position;
        if (onSphere(ray, sphere[i], tmp_position)) {
            if (depthTest(ray, position, tmp_position)) {
                position = tmp_position;
                idx = i;
            }
            onOneSphere = true;
        }
    }
    if (onOneSphere) {
        mat3 rotation = rot(ROTATION_AXIS, ROTATION_VELO * time);
        position = rotOnSphere(sphere[idx], position, rotation);
        glFragColor = spherePolka(sphere[idx], position);
    } else {
        glFragColor = backGroundPolka();
    }
}
