#version 420

// original https://neort.io/art/c6fpmks3p9f79lb752c0

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// original https://neort.io/art/c6fpmks3p9f79lb752c0

// Copyright © 2021 IWBTShyGuy
// Attribution 4.0 International (CC BY 4.0)
uniform sampler2D backbuffer;

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

/* ------------------------------------------------------ */
// Hash without Sine https://www.shadertoy.com/view/4djSRW

float hash11(float p)
{
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

vec2 hash22(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);

}

vec3 hash33(vec3 p3)
{
    p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy + p3.yxx)*p3.zyx);

}

/* ------------------------------------------------------ */

#define time time
#define resolution resolution

const float AXIS_VELO = 1.0 / PI;
const float ROTATE_MEAN_VELO = PI / 2.0;

// https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdRoundBox(vec3 p, vec3 b, float r) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

// Random unit vector
// https://qiita.com/aa_debdeb/items/e416ae8a018692fc07eb
vec3 randomAxis(vec2 gen) {
    vec2 uv = hash22(gen);
    float z = 2.0 * uv.x - 1.0;
    float t = 2.0 * PI * uv.y;
    return vec3(
        sqrt(1.0 - z * z) * cos(t),
        sqrt(1.0 - z * z) * sin(t),
        z
    );
}

// B-spline basis function
vec3 bspbasis(float t) {
    return vec3 (
        (1.0 - t) * (1.0 - t) * 0.5,
        ((t + 1.0) * (1.0 - t) + t * (2.0 - t)) * 0.5,
        t * t * 0.5
    );
}

// smooth moving unit vector
vec3 movingAxis(float t, float gen) {
    t *= AXIS_VELO;
    vec3 axis0 = randomAxis(vec2(floor(t - 2.0), gen));
    vec3 axis1 = randomAxis(vec2(floor(t - 1.0), gen));
    vec3 axis2 = randomAxis(vec2(floor(t), gen));
    t = fract(t);
    vec3 b = bspbasis(t);
    return normalize(axis0 * b.x + axis1 * b.y + axis2 * b.z);
}

// cellwise SDF
float cellDist(in vec3 p, in vec3 q, in float t) {
    vec3 fq = floor(q);
    float gen = fq.x + fq.y * sqrt(2.0) + fq.z * sqrt(5.0);
    float exists = hash11(gen + 1.8649);
    if (exists < 0.8) return 0.5;
    vec3 disp = 0.1 * hash33(fq);
    p = fract(q) + p - q - 0.5 - disp;
    vec3 axis = movingAxis(t, gen);
    float theta = hash11(gen + 0.9286);
    theta = 2.0 * ROTATE_MEAN_VELO * theta * t;
    p = rot(axis, theta) * p;
    return sdRoundBox(p, vec3(0.15), 0.025);
}

// SDF
float sDist(in vec3 p, in vec3 dir, in float t) {
    float dist = cellDist(p, p, t);
    if (floor(p + dist * dir) != floor(p)) {
        dist = min(dist, cellDist(p, p + dist * dir, t));
    }
    return dist;
}

// https://www.iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 calcNormal(in vec3 p, in vec3 dir, in float t) {
    const float eps = 0.0001;
    const vec2 h = vec2(eps,0);
    return normalize(vec3(
        cellDist(p+h.xyy, p, t) - cellDist(p-h.xyy, p, t),
        cellDist(p+h.yxy, p, t) - cellDist(p-h.yxy, p, t),
        cellDist(p+h.yyx, p, t) - cellDist(p-h.yyx, p, t)
    ));
}

const float FAR = 12.0;
void main(void) {
    vec2 theta = vec2(0.15, 0.25) * time;
    theta.y = sin(theta.y) * 0.7;
    Camera camera = newCamera(
        vec3(sin(time * 0.1) * 0.1, -time * 0.5, cos(time * 0.1) * 0.1),
        vec3(cos(theta.x) * cos(theta.y), sin(theta.y), sin(theta.x) * cos(theta.y)),
        //vec3(0),
        //vec3(0, 0, 1),
        vec3(0, 1, 0),
        PI / 4.0,
        resolution.x / resolution.y
    );
    Ray ray = cameraRay(camera, gl_FragCoord.xy / resolution.xy);

    vec3 p = ray.origin;
    for (int _i = 0; _i < 100; _i++) {
        float dist = sDist(p, ray.direction, time);
        float rDist2 = dot(p - ray.origin, p - ray.origin);
        if (dist < 0.00001 || rDist2 > 144.0) break;
        p += dist * ray.direction;
    }

    vec3 col = vec3(0.9, 0.8, 0.9);
    float dist = length(p - ray.origin);
    if (dist < FAR) {
        vec3 normal = calcNormal(p, ray.direction, time);
        float c = -dot(ray.direction, normal);
        c = clamp(c, 0.0, 1.0);
        float k = smoothstep(0.0, 1.0, dist / FAR);
        k *= k;
        vec3 mat = hash33(floor(p) + 1.23);
        col = (1.0 - k) * c * mat + k * col;
    }

    glFragColor = vec4(pow(col, vec3(0.4545)), 1);
}
