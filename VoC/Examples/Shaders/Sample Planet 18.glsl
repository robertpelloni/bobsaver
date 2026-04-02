#version 420

// original https://www.shadertoy.com/view/3lcSRB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define mul(a, b) (a) * (b)

struct ray_t {
    vec3 origin;
    vec3 direction;
};

struct sphere_t {
    vec3 origin;
    float radius;
    int material;
};

struct plane_t {
    vec3 direction;
    float distance;
    int material;
};

struct hit_t {
    float t;
    int material_id;
    vec3 normal;
    vec3 origin;
};

    hit_t no_hit = hit_t (
    float(1e8 + 1e1), 
    -1, 
    vec3(0., 0., 0.),
    vec3(0., 0., 0.) 
);

ray_t get_primary_ray(
    in vec3  cam_local_point,
    inout vec3 cam_origin,
    inout vec3  cam_look_at
){
    vec3 fwd = normalize(cam_look_at - cam_origin);
    vec3 up = vec3(0, 1, 0);
    vec3 right = cross(up, fwd);
    up = cross(fwd, right);

    ray_t r = ray_t (
        cam_origin,
        normalize(fwd + up * cam_local_point.y + right * cam_local_point.x)
    );
    return r;
}

mat3 mat3_ident = mat3(1, 0, 0, 0, 1, 0, 0, 0, 1);

mat2 rotate_2d(
    in float  angle_degrees
){
    float angle = radians(angle_degrees);
    float _sin = sin(angle);
    float _cos = cos(angle);
    return mat2(_cos, -_sin, _sin, _cos);
}

mat3 rotate_around_z(
    in float angle_degrees
){
    float angle = radians(angle_degrees);
    float _sin = sin(angle);
    float _cos = cos(angle);
    return mat3(_cos, -_sin, 0, _sin, _cos, 0, 0, 0, 1);
}

mat3 rotate_around_y(
    in  float  angle_degrees
){
    float angle = radians(angle_degrees);
    float _sin = sin(angle);
    float _cos = cos(angle);
    return mat3(_cos, 0, _sin, 0, 1, 0, -_sin, 0, _cos);
}

mat3 rotate_around_x(
    in float  angle_degrees
){
    float angle = radians(angle_degrees);
    float _sin = sin(angle);
    float _cos = cos(angle);
    return mat3(1, 0, 0, 0, _cos, -_sin, 0, _sin, _cos);
}

vec3 linear_to_srgb(
    in vec3  color
){
    const float p = 1. / 2.2;
    return vec3(pow(color.r, p), pow(color.g, p), pow(color.b, p));
}
vec3 srgb_to_linear(
    in vec3  color
){
    const float p = 2.2;
    return vec3(pow(color.r, p), pow(color.g, p), pow(color.b, p));
}

float checkboard_pattern(
    in vec2  pos,
    in float scale
){
    vec2 pattern = floor(pos * scale);
    return mod(pattern.x + pattern.y, 2.0);
}

float band (
    in float start,
    in float peak,
    in float end,
    in float t
){
    return
    smoothstep (start, peak, t) *
    (1. - smoothstep (peak, end, t));
}

void fast_orthonormal_basis(in vec3 n , out vec3 f , out vec3 r)
{
    float a = 1. / (1. + n.z);
    float b = -n.x*n.y*a;
    f = vec3(1. - n.x*n.x*a, b, -n.x);
    r = vec3(b, 1. - n.y*n.y*a, -n.y);
}

void intersect_sphere(
    in ray_t ray,
    in sphere_t sphere,
    inout hit_t  hit
){
    vec3 rc = sphere.origin - ray.origin;
    float radius2 = sphere.radius * sphere.radius;
    float tca = dot(rc, ray.direction);
    if (tca < 0.) return;

    float d2 = dot(rc, rc) - tca * tca;
    if (d2 > radius2) return;

    float thc = sqrt(radius2 - d2);
    float t0 = tca - thc;
    float t1 = tca + thc;

    if (t0 < 0.) t0 = t1;
    if (t0 > hit.t) return;

    vec3 impact = ray.origin + ray.direction * t0;

    hit.t = t0;
    hit.material_id = sphere.material;
    hit.origin = impact;
    hit.normal = (impact - sphere.origin) / sphere.radius;
}

struct volume_sampler_t {
    vec3 origin; 
    vec3 pos; 
    float height;

    float coeff_absorb;
    float T; 

    vec3 C; 
    float alpha;
};

volume_sampler_t begin_volume(
    in vec3 origin,
    in float coeff_absorb
){
    volume_sampler_t v = volume_sampler_t (
        origin, origin, 0.,
        coeff_absorb, 1.,
        vec3(0., 0., 0.), 0.
    );
    return v;
}

float illuminate_volume(
    inout volume_sampler_t  vol,
    in vec3 V,
    in vec3 L
);

void integrate_volume(
    inout volume_sampler_t  vol,
    in vec3 V,
    in vec3 L,
    in float density,
    in float dt
){

    float T_i = exp(-vol.coeff_absorb * density * dt);
    vol.T *= T_i;
    vol.C += vol.T * illuminate_volume(vol, V, L) * density * dt;
    vol.alpha += (1. - T_i) * (1. - vol.alpha);
}

float hash(
    in float n
){
    return fract(sin(n)*753.5453123);
}

float noise_iq(
    in vec3 x
){
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0 - 2.0*f);

    float n = p.x + p.y*157.0 + 113.0*p.z;
    return mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
                   mix( hash(n+157.0), hash(n+158.0),f.x),f.y),
               mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                   mix( hash(n+270.0), hash(n+271.0),f.x),f.y),f.z);

}

float fbm(in vec3 pos, in float  lacunarity, in float  init_gain, in float gain) 
{ 
    vec3 p = pos; 
    float H = init_gain; 
    float t = 0.; 
    for (int i = 0; i < 4; i++) 
    {
         t += noise_iq(p) * H; 
         p *= lacunarity; 
         H *= gain; 
    } 
         return t; 
}

sphere_t planet = sphere_t (
    vec3(0, 0, 0), 1., 0
);

vec3 background(
    in ray_t eye
){

    vec3 sun_color = vec3(1., .9, .55);
    float sun_amount = dot(eye.direction, vec3(0, 0, 1));

    vec3 sky = mix(
        vec3(.0, .05, .2),
        vec3(.15, .3, .4),
        1.0 - eye.direction.y);
    sky += sun_color * min(pow(sun_amount, 30.0) * 5.0, 1.0);
    sky += sun_color * min(pow(sun_amount, 10.0) * .6, 1.0);

    return sky;

}

void setup_camera(
    inout vec3  eye,
    inout vec3 look_at
){

    eye = vec3(0, 0, -2.5);
    look_at = vec3(0, 0, 2);

}

float fbm_clouds(in vec3  pos, in float  lacunarity, in float  init_gain, in float  gain) 
{ 
    vec3 p = pos; 
    float H = init_gain; 
    float t = 0.; 
    for (int i = 0; i < 4; i++) 
    {
         t += (abs(noise_iq(p) * 2. - 1.)) * H; 
         p *= lacunarity; 
         H *= gain; 
    } 
         return t; 
}

volume_sampler_t cloud;//构造函数

float illuminate_volume(
    inout volume_sampler_t  cloud,
    in vec3  V,
    in vec3  L
){
    return exp(cloud.height) / 0.055;
}

void clouds_map(
    inout volume_sampler_t  cloud,
    in float  t_step
){
    float dens = fbm_clouds(
        cloud.pos * 3.2343 + vec3(0.35, 13.35, 2.67),2.0276, 0.5, 0.5);

    dens *= smoothstep(0.29475675, 0.29475675 + 0.0335 , dens);

    dens *= band(0.2, 0.35, 0.65, cloud.height);

    integrate_volume(cloud,
        cloud.pos, cloud.pos, 
        dens, t_step);
}

void clouds_march(
    in ray_t eye,
    inout volume_sampler_t  cloud,
    in float  max_travel,
    in mat3  rot
){
    const int steps = 75;
    const float t_step = (.4 * 4.) / float(steps);
    float t = 0.;

    for (int i = 0; i < steps; i++) {
        if (t > max_travel || cloud.alpha >= 1.) return;
            
        vec3 o = cloud.origin + t * eye.direction;
        cloud.pos = mul(rot, o - planet.origin);

        cloud.height = (length(cloud.pos) - planet.radius) / .4;
        t += t_step;
        clouds_map(cloud, t_step);
    }
}

void clouds_shadow_march(
    in vec3  dir,
    inout volume_sampler_t  cloud,
    in mat3  rot
){
    const int steps = 5;
    const float t_step = .4 / float(steps);
    float t = 0.;

    for (int i = 0; i < steps; i++) {
        vec3 o = cloud.origin + t * dir;
        cloud.pos = mul(rot, o - planet.origin);

        cloud.height = (length(cloud.pos) - planet.radius) / .4;
        t += t_step;
        clouds_map(cloud, t_step);
    }
}

float fbm_terr(in vec3  pos, in float  lacunarity, in float  init_gain, in float  gain) 
{ 
    vec3 p = pos; 
    float H = init_gain; 
    float t = 0.; 
    for (int i = 0; i < 3; i++) 
    {
         t += noise_iq(p)* H; 
         p *= lacunarity; 
         H *= gain; 
    } 
         return t; 
}

float fbm_terr_r(in vec3  pos, in float  lacunarity, in float  init_gain, in float  gain) 
{ 
    vec3 p = pos; 
    float H = init_gain; 
    float t = 0.; 
    for (int i = 0; i < 3; i++) 
    {
         t += (1. - abs(noise_iq(p) * 2. - 1.))* H; 
         p *= lacunarity; 
         H *= gain; 
    } 
         return t; 
}

float fbm_terr_normals(in vec3 pos, in float  lacunarity, in float  init_gain, in float  gain) 
{ 
    vec3 p = pos; 
    float H = init_gain; 
    float t = 0.; 
    for (int i = 0; i < 7; i++) 
    {
         t += noise_iq(p)* H; 
         p *= lacunarity; 
         H *= gain; 
    } 
         return t; 
}

float fbm_terr_r_normals(in vec3  pos, in float lacunarity, in float init_gain, in float gain) 
{ 
    vec3 p = pos; 
    float H = init_gain; 
    float t = 0.; 
    for (int i = 0; i < 7; i++) 
    {
         t += (1. - abs(noise_iq(p) * 2. - 1.))* H; 
         p *= lacunarity; 
         H *= gain; 
    } 
         return t; 
}

vec2 sdf_terrain_map(in vec3  pos)
{
    float h0 = fbm_terr(pos * 2.0987, 2.0244, .454, .454);
    float n0 = smoothstep(.35, 1., h0);

    float h1 = fbm_terr_r(pos * 1.50987 + vec3(1.9489, 2.435, .5483), 2.0244, .454, .454);
    float n1 = smoothstep(.6, 1., h1);
    
    float n = n0 + n1;
    
    return vec2(length(pos) - planet.radius - n * .4, n / .4);
}

vec2 sdf_terrain_map_detail( in vec3  pos)
{
    float h0 = fbm_terr_normals(pos * 2.0987, 2.0244, .454, .454);
    float n0 = smoothstep(0.35, 1., h0);

    float h1 = fbm_terr_r_normals(pos * 1.50987 + vec3(1.9489, 2.435, .5483), 2.0244, .454, .454);
    float n1 = smoothstep(.6, 1., h1);

    float n = n0 + n1;

    return vec2(length(pos) - planet.radius - n * .4, n / .4);
}

vec3 sdf_terrain_normal( in vec3  p)
{

    vec3 dt = vec3(0.001, 0, 0);
    vec3 nn = normalize(vec3(sdf_terrain_map_detail(p + dt.xzz).x - sdf_terrain_map_detail(p - dt.xzz).x , sdf_terrain_map_detail(p + dt.zxz).x - sdf_terrain_map_detail(p - dt.zxz).x , sdf_terrain_map_detail(p + dt.zzx).x - sdf_terrain_map_detail(p - dt.zzx).x));
    return nn;

}

vec3 setup_lights(
     in vec3  L,
     in vec3  normal
){
    vec3 diffuse = vec3(0, 0, 0);

    vec3 c_L = vec3(7, 5, 3);
    diffuse += max(0., dot(L, normal)) * c_L;

    float hemi = clamp(.25 + .5 * normal.y, .0, 1.);
    diffuse += hemi * vec3(.4, .6, .8) * .2;

    float amb = clamp(.12 + .8 * max(0., dot(-L, normal)), 0., 1.);
    diffuse += amb * vec3(.4, .5, .6);

    return diffuse;
}

vec3 illuminate(
     in vec3  pos,
     in vec3  eye,
     in mat3  local_xform,
     in vec2  df
){

    float h = df.y;

    vec3 w_normal = normalize(pos);

    vec3 normal = sdf_terrain_normal(pos);
    float N = dot(normal, w_normal);

    float s = smoothstep(.4, 1., h);
    vec3 rock = mix(
        vec3(.080, .050, .030), vec3(.600, .600, .600),
        smoothstep(1. - .3*s, 1. - .2*s, N));

    vec3 grass = mix(
        vec3(.086, .132, .018), rock,
        smoothstep(0.211, 0.351, h));
        
    vec3 shoreline = mix(
        vec3(.153, .172, .121), grass,
        smoothstep(0.17, 0.211, h));

    vec3 water = mix(
        vec3(.015, .110, .455) / 2., vec3(.015, .110, .455),
        smoothstep(0., 0.05, h));

    vec3 L = mul(local_xform, normalize(vec3(1, 1, 0)));
    shoreline *= setup_lights(L, normal);
    vec3 ocean = setup_lights(L, w_normal) * water;

    
    return mix(
        ocean, shoreline,
        smoothstep(0.05, 0.17, h));
}

vec3 render(
     in ray_t  eye,
     in vec3  point_cam
){
    mat3 rot_y = rotate_around_y(27.);
    mat3 rot = mul(rotate_around_x( time * -12.), rot_y);
    mat3 rot_cloud = mul(rotate_around_x( time * 8.), rot_y);
    
    //if (mouse*resolution.xy.z > 0.) {
    //    rot = rotate_around_y(-mouse*resolution.xy.x);
    //    rot_cloud = rotate_around_y(-mouse*resolution.xy.x);
    //    rot = mul(rot, rotate_around_x(mouse*resolution.xy.y));
    //    rot_cloud = mul(rot_cloud, rotate_around_x(mouse*resolution.xy.y));
    //}

    sphere_t atmosphere = planet;
    atmosphere.radius += .4;

    hit_t hit = no_hit;
    intersect_sphere(eye, atmosphere, hit);
    if (hit.material_id < 0) {
        return background(eye);
    }

    float t = 0.;
    vec2 df = vec2(1, .4);
    vec3 pos;
    float max_cld_ray_dist = (.4 * 4.);
    
    for (int i = 0; i < 120; i++) {
        if (t > (.4 * 4.)) break;
        
        vec3 o = hit.origin + t * eye.direction;
        pos = mul(rot, o - planet.origin);

        df = sdf_terrain_map(pos);

        if (df.x < 0.005) {
            max_cld_ray_dist = t;
            break;
        }

        t += df.x * .4567;
    }

    cloud = begin_volume(hit.origin, 30.034);
    clouds_march(eye, cloud, max_cld_ray_dist, rot_cloud);

    
    if (df.x < 0.005) {
        vec3 c_terr = illuminate(pos, eye.direction, rot, df);
        vec3 c_cld = cloud.C;
        float alpha = cloud.alpha;
        float shadow = 1.;

        pos = mul(transpose(rot), pos);
        cloud = begin_volume(pos, 30.034);
        vec3 local_up = normalize(pos);
        clouds_shadow_march(local_up, cloud, rot_cloud);
        shadow = mix(.7, 1., step(cloud.alpha, 0.33));

        return mix(c_terr * shadow, c_cld, alpha);
    } else {
        return mix(background(eye), cloud.C, cloud.alpha);
    }
}

void main(void) {

    vec2 aspect_ratio = vec2(resolution.x / resolution.y, 1);

    vec3 color = vec3(0, 0, 0);

    vec3 eye, look_at;
    setup_camera(eye, look_at);

    vec2 point_ndc = gl_FragCoord.xy / resolution.xy;

    vec3 point_cam = vec3(
        (2.0 * point_ndc - 1.0) * aspect_ratio * tan(radians(30.)),
        -1.0);

    ray_t ray = get_primary_ray(point_cam, eye, look_at);

    color += render(ray, point_cam);

    glFragColor = vec4(linear_to_srgb(color), 1);
}
