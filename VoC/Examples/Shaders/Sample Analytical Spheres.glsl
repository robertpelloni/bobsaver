#version 420

// original https://www.shadertoy.com/view/tdXyzB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// analytical raytracing speres with phong shading and reflections
// this is written for clarity, not for performance.

const float INFINITY = 1e20;
const float PI = 3.1415;

// sphere locations. radius is equal to z
const uint SPHERE_COUNT = 10u;
const vec4 spheres[SPHERE_COUNT] = vec4[](
    vec4(0.0, 0.0, -100.0, 100.0),
    vec4(0.0, 0.0, 0.8, 0.8),
    vec4(1.0, 1.0, 0.4, 0.4),
    vec4(1.0, -1.0, 0.4, 0.4),
    vec4(-1.0, 1.0, 0.4, 0.4),
    vec4(-1.0, -1.0, 0.4, 0.4),
    vec4(1.5, 0.0, 0.1, 0.1),
    vec4(0.0, 1.5, 0.1, 0.1),
    vec4(-1.5, 0.0, 0.1, 0.1),
    vec4(0.0, -1.5, 0.1, 0.1)
);

// ambient, diffuse, specular, RGB
const vec3 AMBIENT = vec3(0.001);
const vec3 DIFFUSE = vec3(0.5);
const vec3 SPECULAR = vec3(1.);
const float SHININESS = 50.;
const vec3 REFLECT = vec3(0.8);

// light, RGB. light is an isentropic light as I'm lazy.
const vec3 LIGHT = vec3(1.0);
const vec3 LIGHT_DIR = normalize(vec3(0.0, -1.0, -0.5)); 

// calculate analytic collision with the geometry.
vec3 collide(vec3 origin, vec3 dir, out float depth) {
    depth = INFINITY;
    uint match;

    // try colliding with the spheres, keeping the lowest depth entry
    for (uint i = 0u; i < SPHERE_COUNT; i++) {
        // early-z, just by projected center distance
        vec3 s = spheres[i].xyz - origin;
        float t = dot(dir, s);
        if (t > depth || t < 0.0) {
            continue;
        }

        // collision test
        vec3 d = (dir * t - s);
        if (length(d) > spheres[i].w) {
            continue;
        }
        
        // store any useful data for the actual collision calc
        depth = t;
        match = i;
    }
    if (depth == INFINITY) {
        return vec3(0.);
    }

    // math
    vec3 s = spheres[match].xyz - origin;
    float t = depth;
    vec3 d = (dir * t - s);
    // this line is numerically a bit unstable due to the subtraction of two large numgers which can be close together
    vec3 r = d - dir * sqrt(spheres[match].w * spheres[match].w - dot(d, d));

    // surface normal and final depth
    depth = length(s + r);
    return normalize(r);
}

vec3 light_ray(vec3 orig, vec3 dir, out vec3 hit, out vec3 hit_norm) {
    // hit something
    float depth;
    hit_norm = collide(orig, dir, depth);
    hit = orig + depth * dir;

    // shadow
    float shadow_depth;
    collide(hit, -LIGHT_DIR, shadow_depth);
    
    // lighting
    vec3 light = vec3(0.0);
    if (depth < 1e9) {
        light += AMBIENT;
        if (shadow_depth > 1e9) {
            light += DIFFUSE * dot(-LIGHT_DIR, hit_norm);
            light += SPECULAR * pow(max(0.0, dot(reflect(-LIGHT_DIR, hit_norm), dir)), SHININESS);
        }
    }
    return light * LIGHT;
}

vec3 camera;
vec3 camera_dir;
vec3 camera_up;
const float AR = 1.4;

// this part is identical for every pixel
void setup() {
    camera = vec3(5.0 * cos(time), 5.0 * sin(time), 1.);
    camera_dir = normalize(-camera);
    camera_up = vec3(0., 0., 1.);
}

vec3 calcpixel(vec2 uv) {
    // setup ray dir, norm vector >
    vec3 camera_x = normalize(cross(camera_dir, camera_up));
    // setup ray dir, norm vector ^
    vec3 camera_y = normalize(cross(camera_x, camera_dir));
    // final ray dir
    vec3 ray_dir = normalize(camera_dir * AR + camera_x * uv.x + camera_y * uv.y);
    
    vec3 hit, hit_norm;
    vec3 light = light_ray(camera, ray_dir, hit, hit_norm);
    
    vec3 reflect_dir = reflect(ray_dir, hit_norm);
    vec3 reflect_hit, reflect_norm;
    vec3 reflection = light_ray(hit, reflect_dir, reflect_hit, reflect_norm);

    // assemble
    return light + reflection * REFLECT;
}

const uint AA = 2u;

void main(void)
{
    // setup scene parameters
    setup();
    
    
    vec3 color = vec3(0.);
    for (uint i = 0u; i < AA; i++) {
        for (uint j = 0u; j < AA; j++) {
            // setup screen coord system. up = (0, 1), down = (0, -1), right = (AR, 0), left = (-AR, 0)
            vec2 coord = gl_FragCoord.xy + vec2(i, j) / float(AA);
            vec2 uv = (coord - resolution.xy * 0.5) / resolution.y;

            color += calcpixel(uv);
        }
    }
    color /= float(AA * AA);
    
    // gamma correct and write to output
    glFragColor = vec4(pow(color, vec3(1. / 2.2)), 1.);
}
