#version 420

// original https://www.shadertoy.com/view/lldcRn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_DIST 40.0

float s_min(in float x, in float y, in float s) {

    float bridge =
        clamp(abs(x-y)/s, 0.0, 1.0);
    return min(x,y) - 0.25 * s * (bridge - 1.0) * (bridge - 1.0);
}

float s_max(in float x, in float y, in float s) {
    float bridge =
        clamp(abs(x-y)/s, 0.0, 1.0);
    return max(x,y) + 0.25 * s * (bridge - 1.0) * (bridge - 1.0);
}

float cone_sdf(in vec3 loc) {
    float cone_length = 
        abs(loc.x) + length(loc.yz);
    cone_length = 0.7 * (cone_length - 1.5);

    return cone_length;
}

float cyl_sdf(in vec3 loc) {
    float r = length(loc.yz) - 0.5;
    float cap1 = loc.x - 0.5;
    float cap2 = -0.75 - loc.x;
    return s_max(cap1, s_max(cap2, r, 0.2), 0.2);
}

float inv_sphere(in vec3 loc, in vec3 cent, in float rad) {
  return max(-rad, rad - length(cent - loc));
}

float vehicle_sdf(in vec3 loc) {
    float c = cone_sdf(loc);
    float p = -loc.y;
    float b = -loc.x + 0.2;
    float shell = s_max(c, b, 0.6);
    float back = s_max(cyl_sdf(loc), p, 0.1);
    shell = s_min(shell, back, 0.4);
    shell = s_max(shell,  p, 0.2);
    
    vec3 eye1 = vec3(0.7, 0.3, 0.3);
    vec3 eye2 = vec3(0.7, 0.3, -0.3);
    
    return shell 
        + 0.1 * smoothstep(0.2, 0.0, length(loc.zy - vec2(0.42, 0.0)))
        + 0.1 * smoothstep(0.2, 0.0, length(loc.zy + vec2(0.42, 0.0)))
        - 0.25 * smoothstep(0.41, 0.0, length(loc - eye1))
        - 0.25 * smoothstep(0.41, 0.0, length(loc - eye2))
        - 0.1 * smoothstep(0.2, -0.0, loc.y) * (1.0 + 0.2 * smoothstep(0.4, 0.6, abs(loc.z)));
}

vec3 vehicle_sdf_grad(in vec3 loc) {
    float dist = vehicle_sdf(loc);
    const float del = 0.01;
    return vec3(vehicle_sdf(loc + vec3(del, 0.0, 0.0)) - dist,
                vehicle_sdf(loc + vec3(0.0, del, 0.0)) - dist,
                vehicle_sdf(loc + vec3(0.0, 0.0, del)) - dist) / del;
}

vec3 perturb(in vec3 pt, in float dist) {
    return pt + 0.1 * sin(4.0 * pt.x + 8.0 * time) * vec3(0.0, 1.0, 0.0);
}

float cast_to_vehicle(in vec3 orig, in vec3 dir) {
    vec3 p = orig;
    float accum = 0.0;
    for (int i = 0; i < 256; ++i) {
        float remaining = 0.7 * vehicle_sdf(p);
        accum += remaining;
        p = orig + accum * dir;
        p = perturb(p, accum);
        if (remaining < 1.0e-3) {
            return accum;
        }
    }
    return max(accum, MAX_DIST + 1.0);
}

vec3 get_bounce(in vec3 pt, in vec3 dir) {
    vec3 norm = normalize(vehicle_sdf_grad(pt));
    return normalize(reflect(dir, norm));
}

vec4 castRay(in vec2 gl_FragCoord) {
    vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec3 ray_orig = vec3(0.0, 0.5, -5.0);
    vec3 ray_dir = normalize(vec3(uv, 5.0));
    
    float wiggle = abs(mod(0.2 * time, 4.0) - 2.0) - 1.0;
    wiggle = sign(wiggle) * smoothstep(0.0, 1.0, abs(wiggle));
    float ct = sin(wiggle);
    float st = cos(wiggle);
    mat3 twist = mat3(ct, 0.0, st,
                      0.0, 1.0, 0.0,
                      -st, 0.0, ct);
    ray_dir = twist * ray_dir;
    ray_orig = twist * ray_orig;
    
    float d = cast_to_vehicle(ray_orig, ray_dir);
    
    if (d < MAX_DIST) {
        vec3 pt = ray_orig + d * ray_dir;
        pt = perturb(pt, d);
        ray_dir = get_bounce(pt, ray_dir);
    }

    return vec4(abs(0.5 + 0.5 * ray_dir), 1.0);
}

void main(void)
{
    
    glFragColor = castRay(gl_FragCoord.xy);
}
