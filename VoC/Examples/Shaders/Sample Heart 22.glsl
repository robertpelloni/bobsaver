#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tsKXRK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_DIST 100.0
#define MAX_STEPS 128
#define SURF_DIST 0.0001
#define M_PI 3.1415926535897932384626433832795
#define AA 2

#define MATERIAL_BODY 1

struct Hit {
    float d;
    int material;
};

// Distance to sphere at origin of radius `r`
float sd_sphere(vec3 p, float r) {
    return length(p) - r;
}

#define check_hit(m) if(dist < mindist) { material = m; mindist = dist; }

float almostIdentity( float x, float m, float n )
{
    if( x>m ) return x;
    float a = 2.0*n - m;
    float b = 2.0*m - 3.0*n;
    float t = x/m;
    return (a*t + b)*t*t + n;
}

// Return the closest surface distance to point p
Hit get_sdf(vec3 p) {
    float mindist = MAX_DIST;
    int material = 0;
    float dist;

    // heart
    vec3 q = p;
    q.x = abs(q.x);
    q.x = almostIdentity(q.x, 2.0, 1.0);
    q.z = q.z*(2.0 - q.y/15.0);
    q.y = 4.0 + 1.2*q.y - q.x*sqrt(max((20.0-q.x)/15.0, 0.0));
    dist = sd_sphere(q, 15.0 + pow(0.5 + 0.5*sin(time*10.0 + q.y/25.0 + q.x/12.0 + q.z/20.0), 4.0)*3.0);
    dist /= 3.0;
    check_hit(MATERIAL_BODY);

    return Hit(mindist, material);
}

// Get normal at point `p` using the tetrahedron technique for computing the gradient
vec3 get_normal(vec3 p) {
    const float eps = 0.01;
    vec2 e = vec2(1.0,-1.0);
    return normalize(e.xyy*get_sdf(p + e.xyy*eps).d + 
                     e.yyx*get_sdf(p + e.yyx*eps).d + 
                     e.yxy*get_sdf(p + e.yxy*eps).d + 
                     e.xxx*get_sdf(p + e.xxx*eps).d);
}

// March a ray from `rayfrom` along the `raydir` direction and return the closet surface distance
Hit ray_march(vec3 rayfrom, vec3 raydir) {
    // begin at ray origin
    float t = 0.0;
    Hit hit;
    // ray march loop
    for(int i=0; i<MAX_STEPS; ++i) {
        // compute next march point
        vec3 p = rayfrom+t*raydir;
        // get the distance to the closest surface
        hit = get_sdf(p);
        // hit a surface
        if(abs(hit.d) < (SURF_DIST*t))
            break;
        // increase the distance to the closest surface
        t += hit.d;
    }
    if(t > MAX_DIST)
        hit.material = 0;
    // return the distance to `rayfrom`
    hit.d = t;
    return hit;
}

// Hard shadows
float hard_shadow(vec3 rayfrom, vec3 raydir, float tmin, float tmax) {
    float t = tmin;
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = rayfrom + raydir*t;
        float h = get_sdf(p).d;
        if(h < SURF_DIST)
            return 0.0;
        t += h;
        if(t > tmax)
            break;
    }
    return 1.0;
}

// Get occlusion along `normal` from point of view `rayfrom`
float get_occlusion(vec3 rayfrom, vec3 normal) {
    const int AO_ITERATIONS = 5;
    const float AO_START = 0.01;
    const float AO_DELTA = 0.11;
    const float AO_DECAY = 0.95;
    const float AO_INTENSITY = 1.0;

    float occ = 0.0;
    float decay = 1.0;
    for(int i=0; i<AO_ITERATIONS; ++i) {
        float h = AO_START + float(i) * AO_DELTA;
        float d = get_sdf(rayfrom + h*normal).d;
        occ += (h-d) * decay;
        decay *= AO_DECAY;
    }
    return clamp(1.0 - occ * AO_INTENSITY, 0.0, 1.0);
}

// Return diffuse albedo color for material
vec3 get_material_diffuse(vec3 p, int material) {
    switch(material) {
        case MATERIAL_BODY:
            return vec3(0.3, 0.0, 0.0);
        default:
            return vec3(1.0, 1.0, 1.0);
    }
}

// Return specular color for material
vec3 get_material_specular(vec3 p, int material) {
    switch(material) {
        case MATERIAL_BODY:
            return vec3(0.3, 0.05, 0.05)*3.0;
        default:
            return vec3(0.0);
    }
}

// Compute the scene light at a point
vec3 get_light(vec3 raydir, vec3 p, int material) {
    vec3 diffuse = vec3(0);
    vec3 specular = vec3(0);
    vec3 normal = get_normal(p);
    float occlusion = get_occlusion(p, normal);

    // sun light
    const float SUN_INTENSITY = 1.0;
    const float SUN_SHINESS = 8.0;
    const vec3 SUN_DIRECTION = normalize(vec3(0.6, 0.35, 0.5));
    const vec3 SUN_COLOR = vec3(1.0,0.77,0.6);

    float sun_diffuse = clamp(dot(normal, SUN_DIRECTION), 0.0, 1.0);
    float sun_shadow = hard_shadow(p, SUN_DIRECTION, 0.01, 20.0);
    float sun_specular = pow(clamp(dot(reflect(SUN_DIRECTION, normal), raydir), 0.0, 1.0), SUN_SHINESS);

    diffuse += SUN_COLOR * (sun_diffuse * sun_shadow * SUN_INTENSITY);
    specular += SUN_COLOR * sun_specular;

    // sky light
    const float SKY_INTENSITY = 1.0;
    const float SKY_SHINESS = 8.0;
    const float SKY_BIAS = 0.5;
    const vec3 SKY_COLOR = vec3(0.50,0.70,1.00);
    const vec3 SKY_DIRECTION = vec3(0.0, 1.0, 0.0);

    float sky_diffuse = SKY_BIAS + (1.0 - SKY_BIAS)*clamp(dot(normal, SKY_DIRECTION), 0.0, 1.0);
    float sky_specular = pow(clamp(dot(reflect(SKY_DIRECTION, normal), raydir), 0.0, 1.0), SKY_SHINESS);
    diffuse += SKY_COLOR * (SKY_INTENSITY * sky_diffuse * occlusion);
    specular += SKY_COLOR * (sky_specular * occlusion);

    // fake indirect light
    const float INDIRECT_INTENSITY = 0.2;
    const float INDIRECT_SHINESS = 8.0;
    const vec3 INDIRECT_COLOR = SUN_COLOR;

    vec3 ind_dir = normalize(SUN_DIRECTION * vec3(-1.0,0.0,1.0));
    float ind_diffuse = clamp(dot(normal, ind_dir), 0.0, 1.0);
    float ind_specular = pow(clamp(dot(reflect(ind_dir, normal), raydir), 0.0, 1.0), INDIRECT_SHINESS);
    diffuse += INDIRECT_COLOR * (ind_diffuse * INDIRECT_INTENSITY);
    specular += INDIRECT_COLOR * (ind_specular * INDIRECT_INTENSITY);

    // fresnel light
    const float FRESNEL_INTENSITY = 2.0;
    const vec3 FRESNEL_COLOR = SUN_COLOR;
    float fresnel_diffuse = clamp(1.0+dot(raydir, normal), 0.0, 1.0);
    diffuse += FRESNEL_COLOR * (FRESNEL_INTENSITY * fresnel_diffuse * (0.5 + 0.5*sun_diffuse));
    
    // apply material
    vec3 col = diffuse * get_material_diffuse(p, material) +
               specular * get_material_specular(p, material);

    // gamma correction
    col = pow(col, vec3(0.4545));

    return col;
}

vec3 get_sky_background(vec3 raydir) {
    const vec3 SKY_COLOR1 = vec3(0.4,0.75,1.0);
    const vec3 SKY_COLOR2 = vec3(0.7,0.8,0.9);
    vec3 col = mix(SKY_COLOR2, SKY_COLOR1, exp(10.0*raydir.y));
    return col;
}

// Return camera transform matrix looking from `lookfrom` towards `lookat`, with tilt rotation `tilt`,
// vertical field of view `vfov` (in degrees), at coords `uv` (in the range [-1,1])
vec3 get_ray(vec3 lookfrom, vec3 lookat, float tilt, float vfov, vec2 uv) {
    // camera up vector
    vec3 vup = vec3(sin(tilt), cos(tilt), 0.0);
    // camera look direction
    vec3 lookdir = normalize(lookat - lookfrom);
    // unit vector in camera x axis
    vec3 u = cross(lookdir, vup);
    // unit vector in camera y axis
    vec3 v = cross(u, lookdir);
    // vector in camera z axis normalized by the fov
    vec3 w = lookdir * (1.0 / tan(vfov*M_PI/360.0));
    // camera transformation matrix
    mat3 t = mat3(u, v, w);
    // camera direction
    return normalize(t * vec3(uv, 1.0));
}

vec3 render(vec2 uv) {
    float theta = 10.0*mouse.x*resolution.xy.x/resolution.x + time;
    vec3 lookat = vec3(0.0, 1.0, 0.0);
    vec3 lookfrom = vec3(80.0*sin(theta), 5.0, 80.0*cos(theta));
    vec3 raydir = get_ray(lookfrom, lookat, 0.0, 30.0, uv);
    Hit hit = ray_march(lookfrom, raydir);
    vec3 p = lookfrom + raydir * hit.d;
    if(hit.material > 0)
        return get_light(raydir, p, hit.material);
    else
        return get_sky_background(raydir);
}

vec3 render_aa(vec2 uv) {
#if AA > 1
    float w = 1.0/resolution.y;
    vec3 col = vec3(0.0);
    for(int n=0; n<AA*AA; ++n) {
        vec2 o = 2.0*(vec2(float(int(n / AA)),float(int(n % AA))) / float(AA) - 0.5);
        col += render(uv + o*w);
    }
    col /= float(AA*AA);
    return col;
#else
    return render(uv);
#endif
}

void main(void) {
    // uv coords in range from [-1,1] for y and [-aspect_ratio,aspect_ratio] for x
    vec2 uv = 2.0 * ((gl_FragCoord.xy-0.5*resolution.xy) / resolution.y);
    // render the entire scene
    vec3 col = render_aa(uv);
    // set the finished color
    glFragColor = vec4(col,1);
}
