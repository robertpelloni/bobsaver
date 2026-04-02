#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wdGSDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define M_PI 3.1415926535897932384626433832795

float kDiffuse = 0.8;
float kAmbient = 0.4;

vec3 kBackgroundColor = vec3(0.7, 0.75, 0.7);

vec3 kLightSource = vec3(-5.0, 10.0, -5.0);

float kInfinity = 1000000.0;

// TODO: for some reason, passing around Ray (instead of direction/source directly)
// causes the shader not to work on my android
/* struct Ray {
    vec3 direction;
    vec3 source;
}; */

struct Sphere {
    vec3 center;
    float radius;
    vec3 color;
};

// 23 fps
//const int kResolution = 50;
//const float kSphereRadius = 0.02;
//const int kLookRange = 13;

// 55 fps
    
const int kResolution = 30;
const float kSphereRadius = 0.05;
const int kLookRange = 8;

const float kRippleLength = 2.0 * M_PI / 8.0;

struct Ripple {
    vec2 center;
    float height;  
};

Ripple getRippleForIndex(in int ripple_i) {
    float[] heights = float[](0.22, -0.1, 0.2, -0.2);
    ripple_i = ripple_i % 8;
    Ripple ripple;
    
    if (ripple_i <= 1) {
        ripple.center = vec2(0.0, 0.0);
    } else if (ripple_i <= 3) {
        ripple.center = vec2(0.5, 0.0);
    } else if (ripple_i <= 5) {
        ripple.center = vec2(-0.5, 0.5);
    } else if (ripple_i <= 7) {
        ripple.center = vec2(0.5, 0.5);
    }
    if (ripple_i % 2 == 0) {
        ripple.height = heights[ripple_i / 2];
    } else {
        ripple.height = 0.0;
    }
    return ripple;
}

Ripple getRipple() {
    // Interpolate between the two ripples with a sigmoid function to make transitions smooth
    float ripple_f = time / kRippleLength;
    int ripple_i = int(ripple_f + 0.5);
    float d = ripple_f - float(ripple_i);
    Ripple r1 = getRippleForIndex(ripple_i - 1);
    Ripple r2 = getRippleForIndex(ripple_i);
    float k = 10.0;
    float s = 1.0 / (1.0 + exp(-k * d));
    Ripple ripple;
    ripple.center = r1.center * (1.0-s) + r2.center * s;
    ripple.height = r1.height * (1.0-s) + r2.height * s;
    
    return ripple;
}      

// Get the height at (u,v) for the current ripple
float getHeightForRipple(in Ripple ripple, in float u, in float v) {
    float d = length(vec2(u, v) - ripple.center);
    float y = ripple.height * cos(3.0 * d - 8.0 * time) - ripple.height;
    // make the ripple weaker as it goes away from the ripple center
    y /= (1.0 + d * 4.0);
    return y;
}

Sphere getSphere(in int i, in int j) {
    
    Ripple ripple = getRipple();
    float t = time;
    
    float u = (float(i) / float(kResolution)) * 2.0 - 1.0;
    float v = (float(j) / float(kResolution)) * 2.0 - 1.0;

    // baseline waves
    float y = 0.02 * sin(v * M_PI * 2.0 + 5.0 * time) + 0.02 * sin(u * M_PI * 2.0 + 5.0 * time);
    y += getHeightForRipple(ripple, u, v);
    
    Sphere sphere;
    sphere.center = vec3(u, y, v);
     sphere.radius = kSphereRadius;
    sphere.color = vec3(0.5 + 2.0*y + 0.1*u, 0.5 + 2.0*y + 0.1*v, 0.7 + 0.15 * u + 0.15 * v + 0.6 * y);
    return sphere;
}
    

void traceRayThroughSphere(
    in vec3 source, in vec3 direction, in Sphere sphere, out float hit_t) {
    
    hit_t = kInfinity;  

    vec3 v = source - sphere.center;

    float a = 1.0;
    float b = 2.0*dot(v, direction);
    float c = dot(v, v) - sphere.radius * sphere.radius;

    float det = b*b - 4.0*a*c;
    if (det >= 0.0) {
        float t1 = (-b + sqrt(det)) / (2.0 * a);
        float t2 = (-b - sqrt(det)) / (2.0 * a);            
        if (t1 > 0.0) {
            hit_t = t1;
        }
        if (t2 > 0.0) {
            hit_t = min(hit_t, t2);
        }
    }    
}

void traceRay(in vec3 source, in vec3 direction, out float mint, out vec3 hit_p, out vec3 over_p, out vec3 norm, out vec3 color, out bool is_hit) {
    mint = 99999.0;
    
    // The following is kind of hacky code to make collision checking more efficient
    // It checks collision of the ray with the y=0 plane and then only looks at spheres
    // with (u,v) indices around that point.
    // TODO: make more precise, taking into account current viewpoint and max/min height of
    // spheres.
    float plane_t = -source.y / direction.y;
    vec3 plane_hit = source + direction * plane_t;

    int hit_i = int((plane_hit.x + 1.0) * 0.5 * float(kResolution));
    int hit_j = int((plane_hit.z + 1.0) * 0.5 * float(kResolution));
    
    int start_i = clamp(hit_i - kLookRange, 0, kResolution - 1);
    int end_i = clamp(hit_i + kLookRange, 0, kResolution - 1);
    int start_j = clamp(hit_j - kLookRange, 0, kResolution - 1);
    int end_j = clamp(hit_j + kLookRange, 0, kResolution - 1);
    
    for (int sphere_i = start_i; sphere_i <= end_i; ++sphere_i) {
        for (int sphere_j = start_j; sphere_j <= end_j; ++sphere_j) { 
            Sphere sphere = getSphere(sphere_i, sphere_j);
            float cur_t;
            traceRayThroughSphere(source, direction, sphere, cur_t);
            if (cur_t < mint) {
                mint = cur_t;
                hit_p = cur_t * direction + source;
                norm = normalize(hit_p - sphere.center);
                color = sphere.color;
            }
        }
    }
    
    vec3 col = kBackgroundColor;

    is_hit = false;
    
    if (mint < 99998.0) {
        vec3 light_v = normalize(kLightSource - hit_p);
        vec3 light_reflect = light_v - 2.0 * norm * dot(light_v, norm);
        

        float cos_alpha = dot(norm, light_v);   
        if (cos_alpha < 0.0) cos_alpha = 0.0;

        col = kAmbient * color + kDiffuse * color * cos_alpha;
        
        is_hit = true;
    }
    
    color = col;
    over_p = hit_p + norm * 0.001;
}

void main(void)
{
    vec2 p = gl_FragCoord.xy / resolution.xy;  

    
    float camera_dist = 7.0;
    vec3 camera_p = vec3(sin(0.1*time) * camera_dist, 4.0, cos(0.1*time) * camera_dist);
    
    vec3 camera_look_at = vec3(0.0, 0.0, 0.0);
    vec3 camera_up = vec3(0.0, 1.0, 0.0);
    vec3 camera_forward = normalize(camera_look_at - camera_p);
    vec3 camera_right = cross(camera_forward, camera_up);
    
    float width = 2.0;
    float height = width / resolution.x * resolution.y;  // 1.125
    
    vec3 screen_p = camera_forward * 5.0 + camera_p;
    screen_p += (-width*0.5 + (p.x * width)) * camera_right;
    screen_p += (-height*0.5 + p.y * height) * camera_up;
    
    vec3 d = normalize(screen_p - camera_p);

    float mint = 99999.0;
    vec3 hit_p;
    vec3 over_p;
    vec3 norm;
    vec3 color;
    bool is_hit;
    traceRay(camera_p, d, mint, hit_p, over_p, norm, color, is_hit);
    
    glFragColor = vec4(color,1.0);
}

