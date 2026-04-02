#version 420

// original https://www.shadertoy.com/view/Xsf3zH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float aspect;
const float vfov = 1.02;
vec4 seed = vec4(0.4, 0.0, 0.0, -0.8);
const float err_thres = 0.0075;
const int iter = 10;
const float reflectivity = 0.4;
const vec3 diffuse_color = vec3(0.38, 0.35, 0.32);
const int show_floor = 1;

//uniform mat4 mvmat, normmat;
mat3 rotmat;

#define quat(s, x, y, z)    vec4(x, y, z, s)
#define quat_identity()        vec4(0.0, 0.0, 0.0, 1.0)

#define vec2quat(v)        (v).wxyz

struct Ray {
    vec3 origin;
    vec3 dir;
};

struct Julia {
    bool inside;
    vec4 q;
    vec4 qprime;
};

struct Material {
    vec3 kd, ks;
    float kr;
    float spow;
};

struct ISect {
    bool hit;
    float t;
    vec3 pos;
    vec3 normal;
    Material mat;
};

ISect find_intersection(Ray ray);
vec3 shade(Ray ray, ISect isect);
float amboc(ISect isect);
vec3 sky(Ray ray);
Julia julia(vec4 q, vec4 c);
float julia_dist(vec4 z);
vec3 julia_grad(vec4 z);
vec4 quat_mul(vec4 q1, vec4 q2);
vec4 quat_sq(vec4 q);
float quat_length_sq(vec4 q);
ISect ray_julia(Ray ray);
ISect ray_sphere(Ray ray, float rad);
ISect ray_floor(Ray ray);
Ray get_primary_ray(in vec2 tc);

vec3 steps_color(int steps);

void main(void)
{
    float theta = time * 0.075;
    float phi = 0.25;
    float sintheta = sin(theta);
    float costheta = cos(theta);
    float sinphi = sin(phi);
    float cosphi = cos(phi);
    
    mat3 rotx = mat3(
        costheta, 0, -sintheta,
        0, 1, 0,
        sintheta, 0, costheta);
    mat3 roty = mat3(
        1, 0, 0,
        0, cosphi, sinphi,
        0, -sinphi, cosphi);
    rotmat = rotx * roty;
    
    seed[0] = cos(time * 0.333);
    seed[3] = sin(time * 0.333) * 1.25 - 0.25;
    
    
    vec2 tc = gl_FragCoord.xy / resolution.xy;
    aspect = resolution.x / resolution.y;
    Ray ray = get_primary_ray(tc);

    float energy = 1.0;
    vec3 color = vec3(0.0, 0.0, 0.0);

    for(int i=0; i<2; i++) {
        ISect res = find_intersection(ray);

        if(res.hit) {
            color += shade(ray, res) * energy;
            energy *= res.mat.kr;

            if(energy < 0.001) {
                break;
            }

            ray.origin = res.pos;
            ray.dir = reflect(ray.dir, res.normal);
        } else {
            color += sky(ray) * energy;
            break;
        }
    }

    glFragColor = vec4(color, 1.0);
}

ISect find_intersection(Ray ray)
{
    ISect res;
    res.hit = false;
    
    ISect bhit = ray_sphere(ray, 2.0);
    if(bhit.hit) {
        ray.origin = bhit.pos;
        res = ray_julia(ray);
    }

    if(!res.hit && show_floor == 1) {
        res = ray_floor(ray);
    }
    return res;
}

vec3 shade(Ray ray, ISect isect)
{
    vec3 ldir = normalize(vec3(10.0, 10.0, -10.0) - isect.pos);
    vec3 vdir = -ray.dir;
    vec3 hdir = normalize(ldir + vdir);

    float ndotl = dot(ldir, isect.normal);
    float ndoth = dot(hdir, isect.normal);

    vec3 dcol = isect.mat.kd;// * abs(ndotl);
    vec3 scol = isect.mat.ks * pow(abs(ndoth), isect.mat.spow);

    return vec3(0.05, 0.05, 0.05) + dcol + scol;
}

#define AO_STEP        0.04
#define AO_MAGIC    8.0
float amboc(ISect isect)
{
    float sum = 0.0;

    for(float fi=0.0; fi<5.0; fi+=1.0) {
        float sample_dist = fi * AO_STEP;
        vec3 pt = isect.pos + isect.normal * sample_dist;
        float jdist = julia_dist(quat(pt.x, pt.y, pt.z, 0.0));

        sum += 1.0 / pow(2.0, fi) * (sample_dist - jdist);
    }
    
    float res = 1.0 - AO_MAGIC * sum;
    return clamp(res, 0.0, 1.0);
}

vec3 sky(Ray ray)
{
    vec3 col1 = vec3(0.75, 0.78, 0.8);
    vec3 col2 = vec3(0.56, 0.7, 1.0);

    float t = max(ray.dir.y, -0.5);
    return mix(col1, col2, t);
}

Julia julia(vec4 q, vec4 c)
{
    Julia res;
    res.inside = true;

    res.q = q;
    res.qprime = quat_identity();

    //for(int i=0; i<iter; i++) {
    for(int i=0; i<10; i++) {
        res.qprime = 2.0 * quat_mul(res.q, res.qprime);
        res.q = quat_sq(res.q) + c;

        if(dot(res.q, res.q) > 8.0) {
            res.inside = false;
            break;
        }
    }
    return res;
}

float julia_dist(vec4 z)
{
    Julia jres = julia(z, seed);

    float lenq = length(jres.q);
    float lenqprime = length(jres.qprime);

    return 0.5 * lenq * log(lenq) / lenqprime;
}

#define OFFS 1e-4
vec3 julia_grad(vec4 z)
{
    vec3 grad;
    grad.x = julia_dist(z + quat(OFFS, 0.0, 0.0, 0.0)) - julia_dist(z - quat(OFFS, 0.0, 0.0, 0.0));
    grad.y = julia_dist(z + quat(0.0, OFFS, 0.0, 0.0)) - julia_dist(z - quat(0.0, OFFS, 0.0, 0.0));
    grad.z = julia_dist(z + quat(0.0, 0.0, OFFS, 0.0)) - julia_dist(z - quat(0.0, 0.0, OFFS, 0.0));
    return grad;
}

vec4 quat_mul(vec4 q1, vec4 q2)
{
    vec4 res;
    res.w = q1.w * q2.w - dot(q1.xyz, q2.xyz);
    res.xyz = q1.w * q2.xyz + q2.w * q1.xyz + cross(q1.xyz, q2.xyz);
    return res;
}

vec4 quat_sq(vec4 q)
{
    vec4 res;
    res.w = q.w * q.w - dot(q.xyz, q.xyz);
    res.xyz = 2.0 * q.w * q.xyz;
    return res;
}

#define MIN_STEP    0.001
ISect ray_julia(Ray inray)
{
    float dist_acc = 0.0;
    Ray ray = inray;
    ISect res;

    float fi = 0.0;
    for(int i=0; i<1000; i++) {
        vec4 q = quat(ray.origin.x, ray.origin.y, ray.origin.z, 0.0);
        
        float dist = max(julia_dist(q), MIN_STEP);

        ray.origin += ray.dir * dist;
        dist_acc += dist;

        if(dist < err_thres) {
            res.hit = true;
            res.t = dist_acc;
            res.pos = ray.origin;
            res.normal = normalize(julia_grad(quat(res.pos.x, res.pos.y, res.pos.z, 0.0)));
            res.mat.kr = reflectivity;
            res.mat.kd = diffuse_color * amboc(res);
            res.mat.ks = vec3(0.4, 0.4, 0.4);
            res.mat.spow = 50.0;
            break;
        }

        if(dot(ray.origin, ray.origin) > 100.0) {
            res.hit = false;
            break;
        }
        fi += 0.1;
    }

    return res;
}

ISect ray_sphere(Ray ray, float rad)
{
    ISect res;
    res.hit = false;

    float a = dot(ray.dir, ray.dir);
    float b = 2.0 * dot(ray.dir, ray.origin);
    float c = dot(ray.origin, ray.origin) - rad * rad;

    float d = b * b - 4.0 * a * c;
    if(d < 0.0) return res;

    float sqrt_d = sqrt(d);
    float t1 = (-b + sqrt_d) / (2.0 * a);
    float t2 = (-b - sqrt_d) / (2.0 * a);

    if((t1 >= 0.0 || t2 >= 0.0)) {
        if(t1 < 0.0) t1 = t2;
        if(t2 < 0.0) t2 = t1;
        
        res.hit = true;
        res.t = min(t1, t2);
        res.pos = ray.origin + ray.dir * res.t;
        //res.mat.kd = vec3(1.0, 0.3, 0.2);
        //res.normal = res.pos / rad;
    }

    return res;
}

#define FLOOR_HEIGHT    (-2.0)

ISect ray_floor(Ray ray)
{
    ISect res;
    res.hit = false;

    if(ray.origin.y < FLOOR_HEIGHT || ray.dir.y >= 0.0) {
        return res;
    }

    res.normal = vec3(0.0, 1.0, 0.0);
    float ndotdir = dot(res.normal, ray.dir);

    float t = (FLOOR_HEIGHT - ray.origin.y) / ndotdir;
    res.pos = ray.origin + ray.dir * t;

    if(abs(res.pos.x) > 8.0 || abs(res.pos.z) > 8.0) {
        res.hit = false;
    } else {
        res.hit = true;
    
        float chess = mod(floor(res.pos.x * 0.75) + floor(res.pos.z * 0.75), 2.0);
        res.mat.kd = mix(vec3(0.498, 0.165, 0.149), vec3(0.776, 0.851, 0.847), chess);
        res.mat.ks = vec3(0.0, 0.0, 0.0);
        res.mat.spow = 1.0;
        res.mat.kr = 0.0;
    }
    return res;
}

Ray get_primary_ray(in vec2 tc)
{
    Ray ray;
    //ray.origin = (mvmat * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
    ray.origin = rotmat * vec3(0.0, 0.0, -3.0);

    float ysz = 2.0;
    float xsz = aspect * ysz;

    float px = tc.x * xsz - xsz / 2.0;
    float py = tc.y * ysz - 1.0;
    float pz = 1.0 / tan(0.5 * vfov);

    //vec4 dir = normmat * vec4(px, py, pz, 1.0);
    vec3 dir = rotmat * vec3(px, py, pz);
    ray.dir = normalize(dir.xyz);

    return ray;
}

vec3 steps_color(int steps)
{
    if(steps <= 1) {
        return vec3(0.0, 0.5, 0.0);
    } else if(steps == 2) {
        return vec3(0.0, 1.0, 0.0);
    } else if(steps == 3) {
        return vec3(0.0, 0.0, 0.5);
    } else if(steps == 4) {
        return vec3(0.0, 0.0, 1.0);
    } else if(steps == 5) {
        return vec3(0.0, 0.5, 0.5);
    } else if(steps == 6) {
        return vec3(0.0, 1.0, 1.0);
    } else if(steps == 7) {
        return vec3(0.5, 0.0, 0.5);
    } else if(steps == 8) {
        return vec3(1.0, 0.0, 1.0);
    } else if(steps == 9) {
        return vec3(0.5, 0.0, 0.0);
    }
    return vec3(0.5 + float(steps - 9) / 10.0, 0.0, 0.0);
}
