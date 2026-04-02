#version 420

// original https://www.shadertoy.com/view/mtdGD8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int num_iter = 255;
const float min_camera_dist = 0.0;
const float max_camera_dist = 1000.0;
const float epsilon = 0.01;

float sphereSDF(vec3 ro, float radius) {
    return length(ro) - radius;
}

// Polynomial smooth min (for copying and pasting into your shaders)
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5*(a-b)/k, 0.0, 1.0);
    return mix(a, b, h) - k*h*(1.0-h);
}

float sceneSDF(vec3 ro) {
    float dist = max_camera_dist;
    float k = 0.3*(0.5 + 0.5*sin(time/3.0))+0.4;
    
    float mod_size = 8.0;
    float mod_off = 4.0;
    vec3 mod_ro = mod(ro,mod_size) - vec3(mod_off, mod_off, mod_off);
    
    dist = smin(sphereSDF(mod_ro, 0.2), dist, k);
    float r = 0.1*(0.5+0.5*sin(time*3.)) + 0.5;
    int N = 5;
    for (int i = 0; i < N; i++) {
        float theta = float(i)*(2.*3.14)/float(N);
        dist = smin(sphereSDF(mod_ro+vec3(r*cos(time+theta),r*sin(time+theta),0.0), r/10.),dist, k);
    }
    
    return dist;
}

float diff(vec3 po, vec3 dir, float dx) {
    float fpdx = sceneSDF(po + (dx/2.)*dir);
    float fmdx = sceneSDF(po - (dx/2.)*dir);
    float df = fpdx - fmdx;
    return df;
}

vec3 grad(vec3 po, float dd) {
    vec3 x = vec3(1.0,0.0,0.0);
    vec3 y = vec3(0.0,1.0,0.0);
    vec3 z = vec3(0.0,0.0,1.0);
    
    float dfx = diff(po, x, dd);
    float dfy = diff(po, y, dd);
    float dfz = diff(po, z, dd);
    
    return normalize(vec3(dfx, dfy,dfz));
    
}

struct RayResult {
    vec3 diffuse_color;
    float dist;
    float min_dist;
};

RayResult marchRay(vec3 ro, vec3 rd) {
    float depth = min_camera_dist;
    RayResult outray;
    outray.dist = max_camera_dist;
    
 
    float min_dist = max_camera_dist;
    for (int i=0;i<num_iter;i++){
        float dist = sceneSDF(ro + depth * rd);
        if (dist < epsilon) {
          outray.dist = depth;
          break;
        }
        depth += dist;
        if (depth >= max_camera_dist) {
            outray.dist = max_camera_dist;
            depth = max_camera_dist;
            break;
        }
        
        min_dist = min(min_dist, dist);
    }
    vec3 diffuse_color = vec3(1.0, 1.0,0.85);
    vec3 normal = grad(ro + depth*rd, 0.001);
    vec3 light_color = vec3(1.0,0.9,0.7);
    //vec3 light_dir = normalize(vec3(3.+cos(time),3.*sin(time),3.*cos(time)+3.));
    vec3 light_dir = normalize(vec3(2,1,4));
    outray.diffuse_color = light_color*dot(light_dir,normal);
    //outray.diffuse_color = diffuse_color;
    outray.min_dist = min_dist;
    return outray;
}

vec3 initRay(float fov, vec2 size) {
    // Move to the center of the screen;
    vec2 xy = gl_FragCoord.xy - size / 2.0;
    // 
    float z = size.y / tan(radians(fov) / 2.0);
    return normalize(vec3(xy, -z));
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    vec3 dir = initRay(70.0, resolution.xy);
    vec3 camera_o = vec3(time,time,-3.*time+5.);
    vec3 col = vec3(0.0,0.0,0.0);
    
    RayResult res = marchRay(camera_o, dir);
    
    if (res.dist < max_camera_dist) {
        col = res.diffuse_color;
        
    } else {
        //col += vec3(1.0,1.0,0.4)*(1.-pow((res.min_dist),0.1));
    }
    // Time varying pixel color
    float f = clamp(40./res.dist, 0.0, 1.0);
    col = vec3(0.0,0.25,0.4)*(1.-f) + col*f;
    //col = clamp(col + vec3(1.0,1.0,0.4)*(1.-pow((res.min_dist),0.5)), 0.0,1.0);
    
    // Output to screen
    
    
    
    glFragColor = vec4(col,1.0);
}