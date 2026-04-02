#version 420

// original https://www.shadertoy.com/view/tsc3Rj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Try to tweak this values
const float epsilon = 0.0005;
const float fov = radians(35.);
const float mandelbulb_power = 8.;
const float view_radius = 10.;
const int mandelbulb_iter_num = 15;
const float camera_distance = 3.5;
const float rotation_speed = 0.1;

float mandelbulb_sdf(vec3 pos) {
    vec3 z = pos;
    float dr = 1.0;
    float r = 0.0;
    for (int i = 0; i < mandelbulb_iter_num ; i++)
    {
        r = length(z);
        if (r>2.) break;
        
        // convert to polar coordinates
        float theta = acos(z.z / r);
        float phi = atan(z.y, z.x);

        dr =  pow( r, mandelbulb_power-1.0)*mandelbulb_power*dr + 1.0;
        
        // scale and rotate the point
        float zr = pow( r,mandelbulb_power);
        theta = theta*mandelbulb_power;
        phi = phi*mandelbulb_power;
        
        // convert back to cartesian coordinates
        z = zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
        z+=pos;
    }
    return 0.5*log(r)*r/dr;
}

float scene_sdf(vec3 p)
{
    return mandelbulb_sdf(p);
}

vec3 ray_marching(const vec3 eye, const vec3 ray, out float depth, out int steps)
{
    depth = 0.;
    steps = 0;
    float dist;
    vec3 intersection_point;

    do
    {
        intersection_point = eye + depth*ray;
        dist = scene_sdf(intersection_point);
        depth += dist;
        steps++;
    }
    while(depth < view_radius && dist > epsilon);

    return intersection_point;
}

vec3 estimate_normal(const vec3 p, const float delta)
{
    return normalize(vec3(
        scene_sdf(vec3(p.x + delta, p.y, p.z)) - scene_sdf(vec3(p.x - delta, p.y, p.z)),
        scene_sdf(vec3(p.x, p.y + delta, p.z)) - scene_sdf(vec3(p.x, p.y - delta, p.z)),
        scene_sdf(vec3(p.x, p.y, p.z  + delta)) - scene_sdf(vec3(p.x, p.y, p.z - delta))
    ));
}

vec2 transformed_coordinates(vec2 frag_coord)
{
    vec2 coord = (frag_coord / resolution.xy)*2. - 1.;
    coord.y *= resolution.y / resolution.x;
    return coord;
}

float contrast(float val, float contrast_offset, float contrast_mid_level)
{
    return clamp((val - contrast_mid_level) * (1. + contrast_offset) + contrast_mid_level, 0., 1.);
}

void main(void)
{
    vec2 coord = transformed_coordinates(gl_FragCoord.xy);
    vec2 cursor = mouse*resolution.xy.xy / resolution.xy;
    
    vec3 ray = normalize(vec3(coord*tan(fov), 1));

    float angle = radians(360.)*time*rotation_speed;
    
    mat3 cam_basis = mat3(cos(angle), 0, sin(angle),
                          0, 1, 0,
                          -sin(angle), 0, cos(angle));
    
    ray = cam_basis*ray;
    
    vec3 cam_pos = -cam_basis[2]*camera_distance*(1. - cursor.x);
    
    float depth = 0.;
    int steps = 0;
    vec3 intersection_point = ray_marching(cam_pos + epsilon*ray, ray, depth, steps);

    //AO

    float ao = float(steps) * 0.01;
    ao = 1. - ao / (ao + 0.5);  // reinhard

    const float contrast_offset = 0.3;
    const float contrast_mid_level = 0.5;
    ao = contrast(ao, contrast_offset, contrast_mid_level);

    vec3 normal = estimate_normal(intersection_point, epsilon*0.5);

    vec3 fColor = ao*(normal*0.5 + 0.5);
    
    // Output to screen
    glFragColor = vec4(fColor,1.0);
}
