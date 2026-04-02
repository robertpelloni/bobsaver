#version 420

// original https://www.shadertoy.com/view/7tBXDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//https://raytracing.github.io/books/RayTracingInOneWeekend.html

const float PI = 3.14159;
const float SAMPLES_PER_PIXEL = 10.;
const int MAX_RAY_BOUNCES = 6;

float hash12(vec2 p) {
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}
vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);

}
vec3 hash32(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}

vec3 random_in_unit_sphere(vec2 p) {
    vec3 rand = hash32(p);
    float phi = 2.0 * PI * rand.x;
    float cosTheta = 2.0 * rand.y - 1.0;
    float u = rand.z;

    float theta = acos(cosTheta);
    float r = pow(u, 1.0 / 3.0);

    float x = r * sin(theta) * cos(phi);
    float y = r * sin(theta) * sin(phi);
    float z = r * cos(theta);

    return vec3(x, y, z);
}

vec3 random_unit_vector(vec2 p) {
    return normalize(random_in_unit_sphere(p));
}

vec3 random_in_unit_disk(vec2 p) {
    return vec3(random_in_unit_sphere(p).xy, 0);
}

const int material_lambertian = 0;
const int material_metal = 1;
const int material_dielectric = 2;

struct ray {
    vec3 origin;
    vec3 dir;
};

struct material {
    int type;
    vec3 albedo;
    float metal_fuzz;
    float dielectric_index_of_refraction;
};

struct hit_record {
    vec3 p;
    vec3 normal;
    float t;
    material material;
};

struct sphere {
    vec3 center;
    float radius;
    material material;
};

sphere s1 = sphere(vec3( 0.0, -1000., -1.0), 1000., material(material_lambertian, vec3(0.5), 0., 0.));
sphere s2 = sphere(vec3(-4.0,    1.0, 2.),   1.0, material(material_dielectric, vec3(0), 0., 1.5));
sphere s3 = sphere(vec3( 0.0,    1.0, 0.),   1.0, material(material_metal, vec3(0.7, 0.6, 0.5), 0., 0.));
sphere s4 = sphere(vec3( 4.0,    1.0, 2.),   1.0, material(material_lambertian, vec3(0.7, 0.3, 0.3), 0., 0.));
sphere s5 = sphere(vec3(-6, 0.2, 2.8), 0.2, material(material_dielectric, vec3(0, 0, 0.2), 0., 1.5));
sphere s6 = sphere(vec3(1.6, 0.2, -0.9), 0.2, material(material_dielectric, vec3(0), 0., 1.5));
sphere s7 = sphere(vec3(-5.7, 0.2, -2.7), 0.2, material(material_lambertian, vec3(0.8, 0.3, 0.3), 0., 0.));
sphere s8 = sphere(vec3(-3.6, 0.2, -4.4), 0.2, material(material_lambertian, vec3(0.9, 0.3, 0.2), 0., 0.));
sphere s9 = sphere(vec3(0.8, 0.2, 2.3), 0.2, material(material_lambertian, vec3(0.2, 0, 0.5), 0., 0.));
sphere s10 = sphere(vec3(3.8, 0.2, 4.2), 0.2, material(material_lambertian, vec3(0.4, 0.3, 0.7), 0., 0.));
sphere s11 = sphere(vec3(-0.1, 0.2, -1.9), 0.2, material(material_lambertian, vec3(0.4, 0, 0.4), 0., 0.));
sphere s12 = sphere(vec3(-2.5, 0.2, 5.4), 0.2, material(material_metal, vec3(0.3, 0.7, 0.9), 0.3, 0.));
sphere s13 = sphere(vec3(-3.9, 0.2, -0.3), 0.2, material(material_lambertian, vec3(0.9, 0.8, 0.5), 0., 0.));
sphere s14 = sphere(vec3(-6, 0.2, 4), 0.2, material(material_lambertian, vec3(0.9, 0.9, 0.5), 0., 0.));
sphere s15 = sphere(vec3(4.4, 0.2, -0.5), 0.2, material(material_lambertian, vec3(0.5, 0.4, 0.8), 0., 0.));
sphere s16 = sphere(vec3(3.4, 0.2, 5.3), 0.2, material(material_lambertian, vec3(0.1, 0.6, 0.2), 0., 0.));
sphere s17 = sphere(vec3(4.6, 0.2, -3.8), 0.2, material(material_lambertian, vec3(0.2, 0.2, 0.2), 0., 0.));
sphere s18 = sphere(vec3(0.7, 0.2, -2.5), 0.2, material(material_metal, vec3(0, 0.2, 0.1), 0., 0.));
sphere s19 = sphere(vec3(2.4, 0.2, -4.3), 0.2, material(material_lambertian, vec3(0.8, 0.9, 0), 0., 0.));
sphere s20 = sphere(vec3(4.4, 0.2, 4.9), 0.2, material(material_lambertian, vec3(0.8, 0.8, 0), 0., 0.));
sphere s21 = sphere(vec3(-4.7, 0.2, 4.6), 0.2, material(material_lambertian, vec3(0.8, 0.8, 0.7), 0., 0.));
sphere s22 = sphere(vec3(4.2, 0.2, -3.5), 0.2, material(material_lambertian, vec3(0.8, 0.8, 0.6), 0., 0.));
sphere s23 = sphere(vec3(-5.2, 0.2, 0.5), 0.2, material(material_lambertian, vec3(0.2, 0.7, 0.9), 0., 0.));
sphere s24 = sphere(vec3(5.7, 0.2, -0.8), 0.2, material(material_lambertian, vec3(0.3, 0, 0.7), 0., 0.));

void hit_sphere(sphere sph, ray r, inout hit_record rec, inout bool hit_anything) {
    float closest_so_far = rec.t;
    vec3 oc = r.origin - sph.center;
    float a = dot(r.dir, r.dir);
    float half_b = dot(oc, r.dir);
    float c = dot(oc, oc) - sph.radius * sph.radius;
    float discriminant = half_b * half_b - a * c;
    if (discriminant < 0.) {
        return;
    }

    float sqrtd = sqrt(discriminant);

    // Find the nearest root that lies in the acceptable range
    float root = (-half_b - sqrtd) / a; // the t. from -b - sqrt(dis) / 2a
    if (root < 0.001 || closest_so_far < root) {
        root = (-half_b + sqrtd) / a;
        if (root < 0.001 || closest_so_far < root) {
            return;
        }
    }

    hit_anything = true;
    vec3 p = r.origin + r.dir * root;
    rec = hit_record(p, (p - sph.center) / sph.radius, root, sph.material);
}

bool hit(ray r, out hit_record rec) {
    bool hit = false;
    // dummy. Set initial hit distance to max
    rec = hit_record(vec3(0), vec3(0), 9999., material(material_lambertian, vec3(0), 0., 0.));

    // unrolling this loop gave 4x perf boost...
    hit_sphere(s1, r, rec, hit);
    hit_sphere(s2, r, rec, hit);
    hit_sphere(s3, r, rec, hit);
    hit_sphere(s4, r, rec, hit);
    hit_sphere(s5, r, rec, hit);
    hit_sphere(s6, r, rec, hit);
    hit_sphere(s7, r, rec, hit);
    hit_sphere(s8, r, rec, hit);
    hit_sphere(s9, r, rec, hit);
    hit_sphere(s11, r, rec, hit);
    hit_sphere(s12, r, rec, hit);
    hit_sphere(s13, r, rec, hit);
    hit_sphere(s14, r, rec, hit);
    hit_sphere(s15, r, rec, hit);
    hit_sphere(s16, r, rec, hit);
    hit_sphere(s17, r, rec, hit);
    hit_sphere(s18, r, rec, hit);
    hit_sphere(s19, r, rec, hit);
    hit_sphere(s21, r, rec, hit);
    hit_sphere(s22, r, rec, hit);
    hit_sphere(s23, r, rec, hit);
    hit_sphere(s24, r, rec, hit);
    return hit;
}

bool near_zero(vec3 p) {
    float s = 1e-8;
    return p.x < s && p.y < s && p.z < s;
}

float reflectance(float cosine, float ref_idx) {
    // Use Schlick's approximation for reflectance
    float r0 = (1. - ref_idx) / (1. + ref_idx);
    r0 = r0 * r0;
    return r0 + (1. - r0) * pow((1. - cosine), 5.);
}

void scatter(hit_record rec, ray r, vec2 seed, inout vec3 attenuation, inout ray scattered) {
    material m = rec.material;

    if (m.type == material_lambertian) {
        vec3 scatter_direction = normalize(rec.normal + random_unit_vector(seed));

        // catch degenerate scatter direction
        if (near_zero(scatter_direction)) {
            scatter_direction = rec.normal;
        }

        scattered = ray(rec.p, scatter_direction);
        attenuation = m.albedo;
    } else if (m.type == material_metal) {
        vec3 reflected = reflect(r.dir, rec.normal);
        ray scattered_ = ray(rec.p, normalize(reflected + m.metal_fuzz * random_in_unit_sphere(seed)));
        if (dot(scattered_.dir, rec.normal) > 0.) {
            scattered = scattered_;
            attenuation = m.albedo;
        }
    } else if (m.type == material_dielectric) {
        bool front_face = dot(r.dir, rec.normal) < 0.;
        vec3 adjusted_normal = front_face ? rec.normal : -rec.normal;
        float ref = m.dielectric_index_of_refraction;
        float refraction_ratio = front_face ? 1.0/ref : ref;

        float cos_theta = min(dot(-r.dir, adjusted_normal), 1.0);
        float sin_theta = sqrt(1.0 - cos_theta * cos_theta);

        bool cannot_refract = refraction_ratio * sin_theta > 1.0;
        vec3 direction;

        if (cannot_refract || reflectance(cos_theta, refraction_ratio) > hash12(seed)) {
            direction = reflect(r.dir, adjusted_normal);
        } else {
            direction = refract(r.dir, adjusted_normal, refraction_ratio);
        }

        scattered = ray(rec.p, direction);
        attenuation = vec3(1);
    }
}

vec3 ray_color(in ray r, vec2 seed) {
    vec3 color = vec3(1);
    hit_record rec;
    int depth;
    for (depth = 0; depth < MAX_RAY_BOUNCES; depth++) {
        if (hit(r, rec)) {
            ray scattered;
            vec3 attenuation;
            scatter(rec, r, seed * 999. + float(depth), attenuation, scattered);
            r = scattered;
            color *= attenuation;
        } else {
            // hit bg, aka nothing
            float t = 0.5 * (r.dir.y + 1.0);
            color *= mix(vec3(1.), vec3(0.5, 0.7, 1.0), t);

            break;
        }
    }

    if (depth > MAX_RAY_BOUNCES) {
        return vec3(0);
    }
    return color;
}

void main(void) {
    // camera
    vec3 lookfrom = vec3(cos(time) * 13., 2.0, sin(time) * 10.);
    vec3 lookat = vec3(0, 0, 0);
    vec3 vup = vec3(0, 1, 0);
    float vfov = 30.0;
    float aspect_ratio = resolution.x / resolution.y;
    float aperture = 0.1;
    float focus_dist = 10.0;

    float theta = radians(vfov);
    float h = tan(theta / 2.);
    float viewport_height = 2.0 * h;
    float viewport_width = aspect_ratio * viewport_height;

    vec3 w = normalize(lookfrom - lookat);
    vec3 u = normalize(cross(vup, w));
    vec3 v = cross(w, u);

    vec3 origin = lookfrom;
    vec3 horizontal = focus_dist * viewport_width * u;
    vec3 vertical = focus_dist * viewport_height * v;
    vec3 lower_left_corner = origin - horizontal / 2. - vertical / 2. - focus_dist * w;

    float lens_radius = aperture / 2.;

    // render
    vec3 color = vec3(0);
    for (float s = 0.; s < SAMPLES_PER_PIXEL; s++) {
        vec2 rand = hash22(gl_FragCoord.xy * 999. + s + time);

        vec2 normalizedCoord = (gl_FragCoord.xy + rand) / resolution.xy;
        vec3 rd = lens_radius * random_in_unit_disk(normalizedCoord * 999. + s + time);
        vec3 offset = u * rd.x + v * rd.y;
        ray r = ray(
            origin + offset,
            normalize(lower_left_corner + normalizedCoord.x * horizontal + normalizedCoord.y * vertical - origin - offset)
        );
        color += ray_color(r, normalizedCoord);
    }

    glFragColor = vec4(sqrt(color / SAMPLES_PER_PIXEL), 1.0);
}

