#version 420

// original https://www.shadertoy.com/view/7dVXzR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float max_d = 100000.;
float min_d = 0.0015;
int max_i = 220;
float rotation_speed = .2;

vec4 s0 = vec4(-4.5, 0., -3., 4.);
vec4 s1 = vec4(3., -1.8, -2., 2.2);
vec4 c0 = vec4(1., -1.5, 4., 2.5);
float p1 = -4.03;
vec4 c2 = vec4(.5, 2.02, 3.5, 1.);
vec4 s2 = vec4(.5, 4.5, 3.5, 1.5);
vec4 s3 = vec4(-7., 4., 5., 1.);

float sum(vec3 v) { return v.x + v.y + v.z; }
float max_abs(vec3 v) { return max(max(abs(v.x), abs(v.y)), abs(v.z)); }

float sphere(vec3 p, vec3 s, float r) { return sqrt(sum((p - s) * (p - s))) - r; }

float cube(vec3 p, vec3 s, float r) { return max_abs(p - s) - r; }

vec3 cube_m(vec3 p, vec4 c, vec3 ray) {
    if(abs(p.x - c.x) > max(abs(p.z - c.z), abs(p.y - c.y))) { ray.x *= -1.; }
    if(abs(p.y - c.y) > max(abs(p.z - c.z), abs(p.x - c.x))) { ray.y *= -1.; }
    if(abs(p.z - c.z) > max(abs(p.y - c.y), abs(p.x - c.x))) { ray.z *= -1.; }
    return ray;
}

vec3 col(vec3 cam, vec3 ray) {
    vec3 p = cam;
    vec3 col = vec3(1., 1., 1.);
    vec3 col_1 = col;
    vec3 pcol = vec3(0., 0., 0.);
    float min_s3d = 2.;
    bool t;
    for(int i = 0; i < max_i; i ++) {
        t = true;
        float d = max_d;
        d = min(d, sphere(p, s0.xyz, s0.a));
        if(d < min_d && t) {
            ray -= normalize(s0.xyz - p) * dot(s0.xyz - p, ray) / s0.a * 2.;
            col *= vec3(1., .5, .5);
            t = false;
        }
        d = min(d, sphere(p, s1.xyz, s1.a));
        if(d < min_d && t) {
            ray -= normalize(s1.xyz - p) * dot(s1.xyz - p, ray) / s1.a * 2.;
            col *= vec3(.5, 1., .5) * (float(sin(atan((s1.x - p.x) / (s1.z - p.z)) * 10. + sin(time) * 30.) > 0.) * .7 + .3);
            t = false;
        }
        d = min(d, sphere(p, s2.xyz, s2.a));
        if(d < min_d && t) {
            ray -= normalize(s2.xyz - p) * dot(s2.xyz - p, ray) / s2.a * 2.;
            col *= vec3(.2, 1., 1.) * (float(sin(atan(length(s2.xz - p.xz) / (s2.y - p.y)) * 12.) > 0.) * .7 + .3);
            t = false;
        }
        float s3d = sphere(p, s3.xyz, s2.a);
        if(s3d < min_s3d && s3d < 2.) { min_s3d = s3d; }
        d = min(d, s3d * .4);
        if(d < min_d && t) {
            pcol += vec3(2., 2., 4.) * col;
            t = false;
            break;
        }
        d = min(d, cube(p, c0.xyz, c0.a));
        if(d < min_d && t) {
            ray = cube_m(p, c0, ray);
            col *= vec3(.5, .5, 1.);
            t = false;
        }
        if(ray.y < 0.) {
            d = min(d, (p1 - p.y) / ray.y);
            if(d < min_d && t) {
                ray.y *= -1.;
                col *= vec3(.3, .3, .3);
                t = false;
            }
        }
        d = min(d, cube(p, c2.xyz, c2.a));
        if(d < min_d && t) {
            ray = cube_m(p, c2, ray);
            col *= vec3(1., 1., .1);
            t = false;
        }
        if(!t) {
            p += ray * min_d * 2.;
            pcol += col_1 * vec3(1., 1., 2.) * (2. - min_s3d) * (2. - min_s3d) * .5;
            min_s3d = 2.;
            col_1 = col;
        }
        p += ray * d;
        if(length(p) > max_d) { break; }
    }
    pcol += col * vec3(1., 1., 2.) * (2. - min_s3d) * (2. - min_s3d) * .5;
    if(length(p) <= max_d && t) { return pcol; }
    col = col * (ray.yxz * vec3(.5, .35, .35) + vec3(.5, .65, .65)).rgb * (ray.y * 2.5 + .4) *
    (0.9 + .2 * float(sin(atan(ray.x / ray.z) * 30.) > 0.6)) *
    (0.9 + .2 * float(sin(atan(ray.y / ray.z) * 30.) > 0.6)) *
    (0.9 + .2 * float(sin(atan(ray.y / ray.x) * 30.) > 0.6)) + pcol;
    return col;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - resolution.xy * .5) / (resolution.x + resolution.y) * 4.;

    float x = time * 1.5 - float(int(time * 1.5)) - .5;
    s2.y = 4.52 + (1. - x * x * 4.) * 2.;

    float t = time * rotation_speed;
    glFragColor.rgb = col(
        vec3(sin(t) * 25., 4., - cos(t) * 25.),
        normalize(vec3(- sin(t) * 1.3 + cos(t) * uv.x,
            uv.y - .3, cos(t) * 1.3 + sin(t) * uv.x))
    );
    glFragColor.a = 1.;
}
