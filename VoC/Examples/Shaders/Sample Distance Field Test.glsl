#version 420

// original https://www.shadertoy.com/view/4dScRG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define THRES        1e-3
#define MAX_ITER    250
#define MAX_STEP    0.1
#define M_PI        3.14159265

float calc_dist(in vec3 p);

vec3 ray_march(in vec3 p, in vec3 dir);
vec3 colorize(in vec3 p, in vec3 dir, in float dist);
vec3 backdrop(in vec3 dir);
vec3 get_ray_dir(in vec2 p);

float tsec;

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    tsec = time;
    
    vec3 origin = vec3(0.0, 0.0, -13.0);
    vec3 dir = normalize(get_ray_dir(uv));
    
    glFragColor.rgb = ray_march(origin, dir);
    glFragColor.a = 1.0;
}

float calc_dist(in vec3 p)
{
    const vec3 sph_pos = vec3(0.0, 0.0, 0.0);
    vec3 sph_dir = p - sph_pos;
    float sph_dist = length(sph_dir * vec3(1.0, 1.0, 1.0));
    sph_dir = normalize(sph_dir);
    float theta = atan(sph_dir.z, sph_dir.x) + M_PI + cos(sph_dist + tsec * 2.0) * 0.1;
    theta = mod(theta - tsec * 0.2, 2.0 * M_PI);
    float phi = acos(sph_dir.y) + cos(sph_dist + tsec * 1.2) * 0.1;
    
    float rad = 5.0 + (1.0 - sin(theta * 8.0)) * 1.0 *
        (1.0 - cos(phi * 10.0)) * 1.0;
    sph_dist -= rad;
    
    return sph_dist;
}

vec3 ray_march(in vec3 p, in vec3 dir)
{
    float d, total_d = 0.0;
    
    for(int i=0; i<MAX_ITER; i++) {
        if((d = calc_dist(p)) <= THRES) {
            return colorize(p, dir, total_d);
        }
        
        d = min(d, MAX_STEP);
        
        p = p + dir * d;
        total_d += d;
    }
    
    return backdrop(dir);
}

vec3 calc_normal(in vec3 p)
{
    const float delta = 1e-2;
    float gx = calc_dist(p + vec3(delta, 0.0, 0.0)) - calc_dist(p - vec3(delta, 0.0, 0.0));
    float gy = calc_dist(p + vec3(0.0, delta, 0.0)) - calc_dist(p - vec3(0.0, delta, 0.0));
    float gz = calc_dist(p + vec3(0.0, 0.0, delta)) - calc_dist(p - vec3(0.0, 0.0, delta));
    return normalize(vec3(gx, gy, gz));
}

vec3 colorize(in vec3 p, in vec3 dir, in float dist)
{
    const vec3 kd = vec3(1.0, 0.3, 0.1);
    const vec3 ks = vec3(0.7, 0.7, 0.7);
    const vec3 ldir = normalize(vec3(-1.0, 1.0, -1.5));
    const vec3 vdir = vec3(0.0, 0.0, -1.0);

    vec3 diffuse = vec3(0.0, 0.0, 0.0);
    vec3 specular = vec3(0.0, 0.0, 0.0);
    
    vec3 n = calc_normal(p);
    vec3 hdir = normalize(ldir + vdir);

    float ndotl = max(dot(n, ldir), 0.0);
    float ndoth = max(dot(n, hdir), 0.0);
    
    diffuse += kd * ndotl;
    specular += ks * pow(ndoth, 50.0);
    
    float fog = clamp(300.0 / (dist * dist), 0.0, 1.0);

    return mix(backdrop(dir), diffuse + specular, fog);
}

vec3 backdrop(in vec3 dir)
{
    return vec3(0.5, 0.5, 0.7);
}

vec3 get_ray_dir(in vec2 p)
{
    float aspect = resolution.x / resolution.y;
    return vec3(aspect * (p.x * 2.0 - 1.0), p.y * 2.0 - 1.0, 1.0);
}
