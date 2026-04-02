#version 420

// original https://neort.io/art/c54915k3p9fe3sqpjpq0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

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

void main(void) {
    float c = 0.0;
    vec3 lp = vec3(cos(0.5 * time), 1.0 + sin(time), sin(0.7 * time)) * 2.0;

    Camera camera = newCamera(
        vec3(10, 10, 10),
        -normalize(vec3(1, 1, 1)),
        vec3(0, 1, 0),
        3.141592653 / 4.0,
        resolution.x / resolution.y
    );
    Ray ray = cameraRay(camera, gl_FragCoord.xy / resolution.xy);

    float t = -ray.origin.y / ray.direction.y;
    vec3 p = ray.origin + t * ray.direction - lp;
    c = 2.0 / dot(p, p);
    
    vec3 a = lp - ray.origin;
    vec3 h = a - dot(a, ray.direction) * ray.direction;
    float d2 = dot(h, h);
    c = max(c, 0.5 / d2);

    glFragColor = vec4(c, c, c, 1);
}
