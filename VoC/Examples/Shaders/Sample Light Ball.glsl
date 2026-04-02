#version 420

// original https://www.shadertoy.com/view/NldSD4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Copyright © 2021 IWBTShyGuy
// Attribution 4.0 International (CC BY 4.0)

const float PI = 3.141592653;

struct Camera {
    vec3 position;
    vec3 direction;
    vec3 up_direction; // not require dot(direction, up_direction) == 0
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

// perspective camera ray, uv = gl_FragCoord.xy / resolution.xy
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

const int UN = 40;
const int VN = 16;

vec2 nearUVN(in vec3 p, in float radius) {
    vec3 n = normalize(p);

    vec2 x = normalize(n.zx);
    float u = acos(clamp(x.x, -1.0, 1.0)) * sign(x.y);
    float v = n.y;

    float un = floor(float(UN) * radius);
    u = (1.0 + u / PI) * 0.5;
    u = floor(u * un + 0.5);

    float vn = floor(float(VN) * radius);
    v = (1.0 + v) * 0.5;
    v = floor(v * vn + 0.5);

    return vec2(u, v);
}

vec3 getPoint(in vec2 uvn, in float radius) {
    float un = floor(float(UN) * radius);
    float vn = floor(float(VN) * radius);

    vec2 uv = vec2(
        uvn.x / un,
        clamp(uvn.y, 1.0, vn - 1.0) / vn
    );
    uv.x = (2.0 * uv.x - 1.0) * PI;
    uv.y = 2.0 * uv.y - 1.0;
    float r = sqrt(1.0 - uv.y * uv.y);
    return vec3(r * sin(uv.x), uv.y, r * cos(uv.x)) * radius;
}

float halfMap(in Ray ray, in vec3 p0, in float radius) {
    float c0 = 0.0;
    vec2 uvn0 = nearUVN(p0, radius);
    for (int i = 0; i < 49; i++) {
        vec2 e = vec2(i / 7 - 3, i % 7 - 3);
        vec3 p = getPoint(uvn0 + e, radius);
        float dist = dot(p - ray.origin, ray.direction);
        dist = length(ray.origin + dist * ray.direction - p);
        float c = clamp(1.0e-4 / (1.0e-5 + dist * dist), 0.0, 1.0);
        dist = clamp(dist / 0.05, 0.0, 1.0);
        dist = dist * dist;
        c = mix(c * c, 0.0, dist);
        c0 = max(c0, c);
    }
    return c0;
}

float sphereMap(in Camera camera, in vec2 uv, in float theta, in float radius) {
    Ray ray = cameraRay(camera, uv);

    ray.origin = rot(vec3(0, 1, 0), theta) * ray.origin;
    ray.direction = rot(vec3(0, 1, 0), theta) * ray.direction;

    float midDist = -dot(ray.origin, ray.direction);
    float r0 = length(ray.origin + midDist * ray.direction);
    if (r0 > radius + 0.05) return 0.0;

    float diff = radius + 0.05;
    diff = sqrt(diff * diff - r0 * r0);
    vec3 p0 = ray.origin + (midDist - diff) * ray.direction;
    vec3 p1 = ray.origin + (midDist + diff) * ray.direction;

    float c = 0.0;
    c = max(c, halfMap(ray, p0, radius));
    c = max(c, halfMap(ray, p1, radius));
    return c;
}

void main(void) {
    vec3 dir = normalize(vec3(0, sin(time * 0.3) * 0.2, 1));
    Camera camera = newCamera(
        dir * 3.0,
        -dir,
        vec3(0, 1, 0),
        PI / 4.0,
        resolution.x / resolution.y
    );

    vec2 uv = gl_FragCoord.xy / resolution.xy;
    float c = 0.0;
    c = max(c, sphereMap(camera, uv, -time * 0.4, 1.0));
    c = max(c, sphereMap(camera, uv, time * 0.7, 0.7));

    c = pow(c, 0.4545);
    glFragColor = vec4(c, c, c, 1);
}
