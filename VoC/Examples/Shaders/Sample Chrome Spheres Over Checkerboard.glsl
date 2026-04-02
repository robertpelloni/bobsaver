#version 420

// original https://www.shadertoy.com/view/4sVfDw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Various knobs to twiddle
#define LEVELS 8
#define OVERSAMPLE_PIX 4
#define OVERSAMPLE_PIX_WIDTH 0.001
#define OVERSAMPLE_TEX 16
#define LARGE_NUMBER 900000.0

// https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
float rand(vec2 n) { 
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}
vec3 hash33(vec3 p){ 
    float n = sin(dot(p, vec3(7, 157, 113)));    
    return fract(vec3(2097152, 262144, 32768) * n); 
}

// Trefoil knot positions
vec3 trefoil(float t) {
    return vec3(
        sin(t) + 2.0 * sin(2.0 * t),
        cos(t) - 2.0 * cos(2.0 * t),
        -sin(3.0 * t)
    );
}

// Ray-sphere and ray-plane intersections 
float sphere_intersect(vec3 pos, float radius, vec3 eye, vec3 ray) {
    vec3 pos_to_eye = eye - pos;
    float ray_dot_dir = dot(ray, pos_to_eye);
    float determ = ray_dot_dir * ray_dot_dir - dot(pos_to_eye, pos_to_eye) + radius * radius;
    if(determ < 0.0 || -ray_dot_dir - sqrt(determ) < 0.0) {
        return LARGE_NUMBER;   
    }
    return -ray_dot_dir - sqrt(determ);
}

float xzplane_intersect(float height, vec3 eye, vec3 ray) {
    float determ = (height - eye.y) / ray.y;
    if(determ <= 0.0) {
        return LARGE_NUMBER;   
    }
    return determ;
}

// View setup
void camera(vec2 coords, out vec3 eye, out vec3 ray) {
    // Calculate an eye position
    eye = vec3(sin(time) * 0.5, sin(time * 0.3) * 0.5 + 0.5, time * 16.0);
    
    // Camera as eye + imaginary screen at a distance
    vec3 lookat = vec3(0.0, 0.0, time * 16.0 + 2.0);
    vec3 lookdir = normalize(lookat - eye);
    vec3 left = normalize(cross(lookdir, vec3(0.0, 1.0, 0.0)));
    vec3 up = normalize(cross(left, lookdir));
    vec3 lookcenter = eye + lookdir;
    vec3 pixelpos = lookcenter + coords.x * left + coords.y * up;
    ray = normalize(pixelpos - eye);
}

// Raytrace the scene
vec3 sphere_pos(vec3 eye, float spherenum) {
    vec3 trefoil_offset = trefoil(3.14 * 2.0 * spherenum / 7.0 + time).xzy * 0.7;
    return eye + trefoil_offset + vec3(0.0, -1.0, 4.0);
}

vec4 trace(vec3 eye, vec3 ray) {
    float plane_hit = xzplane_intersect(-2.0, eye, ray);
    float hit_dist = plane_hit;
    
    vec3 sphere_c_a = sphere_pos(eye, 1.0);
    float sphere_hit_a = sphere_intersect(sphere_c_a, 0.5, eye, ray);
    hit_dist = min(hit_dist, sphere_hit_a);
    
    vec3 sphere_c_b = sphere_pos(eye, 2.0);
    float sphere_hit_b = sphere_intersect(sphere_c_b, 0.5, eye, ray);
    hit_dist = min(hit_dist, sphere_hit_b);
    
    vec3 sphere_c_c = sphere_pos(eye, 3.0);
    float sphere_hit_c = sphere_intersect(sphere_c_c, 0.5, eye, ray);
    hit_dist = min(hit_dist, sphere_hit_c);
    
    float hit_obj = -1.0;
    hit_obj = hit_dist == plane_hit ? 1.0 : hit_obj;
    hit_obj = hit_dist == sphere_hit_a ? 2.0 : hit_obj;
    hit_obj = hit_dist == sphere_hit_b ? 3.0 : hit_obj;
    hit_obj = hit_dist == sphere_hit_c ? 4.0 : hit_obj;
    hit_obj = hit_dist == LARGE_NUMBER ? -1.0 : hit_obj;
    
    return(vec4(eye + ray * hit_dist, hit_obj));
}

// Colour a non-hit
vec3 background(vec3 dir) {
    float rotval = atan(dir.x + 0.5, dir.y) + time * 0.1;
    float noiseval = mod(atan(dir.y, dir.z), 0.1);
    noiseval = rand(vec2(rotval, noiseval)) > 0.5 ? 1.0 : 0.8;
    float dirs = mod(rotval + 0.08, 0.4);
    float diry = mod(rotval, 0.2) < 0.04 ? 1.0 : abs(mod(rotval, 0.2) - 0.12) * 5.0;
    if(dirs > 0.2) {
        return vec3(diry, 0.0, diry) * noiseval;
    }
    else {
        return vec3(0.0, diry, diry) * noiseval;
    }
}

// Colour anything whatsoever
vec3 shade(vec3 pos, vec3 dir, float hit_obj, vec3 stack_color) {
    if(hit_obj == 1.0) {
        return vec3(mod(floor(pos.x) + floor(pos.z), 2.0));
    }
    if(hit_obj == LARGE_NUMBER) {
        return background(dir);
    }
       return stack_color;
}

// Oversample textures
vec3 shade_supersample(vec3 pos, vec3 dir, float hit_obj, vec3 stack_color) {
    vec3 ddx_a = pos - dFdx(pos);
    vec3 ddy_a = pos - dFdy(pos);
    vec3 ddx_b = pos + dFdx(pos);
    vec3 ddy_b = pos + dFdy(pos);
    
    vec3 shade_sum = vec3(0.0);
    for(int i = 0; i < OVERSAMPLE_TEX; i++) {
        vec2 samp_off = vec2(
            rand(vec2(length(pos * 1000.0), 2000.0 * float(i))),
            rand(vec2(length(pos * 7000.0), 3700.0 * float(i)))
        );
        vec3 samp_pos_x = mix(ddx_a, ddx_b, abs(samp_off.x)) * 0.5;
        vec3 samp_pos_y = mix(ddy_a, ddy_b, abs(samp_off.y)) * 0.5;
        shade_sum += shade(samp_pos_x + samp_pos_y, dir, hit_obj, stack_color);
    }
    return(shade_sum / float(OVERSAMPLE_TEX));
}

// One pixel
vec3 pixel(vec2 coords) {
    vec4 hit[LEVELS];
    vec3 ray[LEVELS];
    vec3 eye;
    
       camera(coords, eye, ray[0]);
    hit[0] = trace(eye, ray[0]);
    
    // Trace all hits
    for(int i = 1; i < LEVELS; i++) {
        // Hit sphere?
        if(hit[i - 1].w >= 2.0 && hit[i - 1].w < LARGE_NUMBER) {
            vec3 sphere_c = sphere_pos(eye, hit[i - 1].w  - 1.0);            
            vec3 sphere_n = normalize(hit[i - 1].xyz - sphere_c);
               ray[i] = reflect(ray[i - 1], sphere_n);
            hit[i] = trace(hit[i - 1].xyz + sphere_n * 0.1, ray[i]);
        }
        else {
             hit[i].w = LARGE_NUMBER;
        }
    }
    
    // Shade
    vec3 stackColor = vec3(0.1);
    for(int i = LEVELS - 1; i >= 0; i--) {
        vec3 dir = ray[0];
        if(i != 0) {
            dir = ray[i - 1];   
        }
        stackColor = shade_supersample(hit[i].xyz, dir, hit[i].w, stackColor);
    }
    return stackColor;
}

// Image
void main(void) {
    vec2 coords = (2.0 * gl_FragCoord.xy  - resolution.xy) / max(resolution.x, resolution.y);
    glFragColor.rgb = vec3(0.0);
    for(int i = 0; i < OVERSAMPLE_PIX; i++) {
        vec2 offset =  hash33(vec3(coords.x, coords.y, float(i))).xy;
        glFragColor.rgb += pixel(coords + offset * OVERSAMPLE_PIX_WIDTH);
    }
    glFragColor.rgb /= float(OVERSAMPLE_PIX);
}
