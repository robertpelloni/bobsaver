#version 420

// original https://www.shadertoy.com/view/MsyXRy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_RAY_DIST 20.0
#define EPSILON 0.01
#define INFTY 1e20

#define PI 3.1415926535

#define AUTO_SPIN_SPEED 0.0
#define CAMERA_DIST 4.0
#define MOUSE_SPEED 0.01

#define ROT_X_90 mat3(1, 0, 0, 0, 0, -1, 0, 1, 0)
#define ROT_X_270 mat3(1, 0, 0, 0, 0, 1, 0, -1, 0)
#define ROT_Y_90 mat3(0, 0, 1, 0, 1, 0, -1, 0, 0)

/* From iq */
float sd_cone( vec3 p, vec2 c ) {
    // c must be normalized
    float q = length(p.xy);
    return dot(c,vec2(q,p.z));
}

/* From iq */
float sd_box( vec3 p, vec3 b ) {
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) +
         length(max(d,0.0));
}

float plane(float y) {
    return y;
}

/* From iq */
float sphere(in vec3 pos, in float radius) {
    return length(pos) - radius;
}

/* From iq */
float op_smin( float a, float b, float k ) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float op_union(in float d1, in float d2) {
    return min(d1, d2);
}

float op_intersect( float d1, float d2 ) {
    return max(d1,d2);
}

float op_subtract( float d1, float d2 )
{
    return max(d1,-d2);
}

float lava_map(in vec3 ro) {
    float d = INFTY;
    d = op_union(d, sphere(vec3(0.0, sin(time * 0.5), 0.0) - ro, 0.2));
    d = op_smin(d, sphere(vec3(0.5 * cos(time * 0.15), sin(time * 0.13), 0.0) - ro, 0.2), 0.1);
    d = op_smin(d, sphere(vec3(0.2 * sin(time * 0.2 + 3.14), sin(time * 0.27), 0.0) - ro, 0.2), 1.5);
    d = op_smin(d, sphere(vec3(0.0, -1.5, 0.5) - ro, 0.75), 1.5);
    return d;
}

float lamp_map(in vec3 ro) {
    float d = sd_cone(vec3(0.0, 0.0, 0.0) - ROT_X_90 * ro, normalize(vec2(2.0, 1.0)));
    d = op_intersect(d, sd_box(vec3(0.0, -1.0, 0.0) - ro, vec3(3.0, 0.5, 3.0)));
    return d;
}

float lamp_base_map(in vec3 ro) {
    float d = sphere(vec3(0.0, 0.0, 0.0) - ro, 1.9);
    d = op_subtract(d, sphere(vec3(0.0, 0.0, 0.0) - ro, 1.85));
    d = op_union(d, sphere(vec3(0.0, -2.0, 0.0) - ro, 1.0));
    d = op_intersect(d, sd_box(vec3(0.0, -1.1, 0.0) - ro, vec3(3.0, 0.9, 3.0)));
    return d;
}

float floor_map(in vec3 ro) {
    return plane(ro.y);
}

float map(in vec3 ro) {
    return op_union(op_union(op_union(lava_map(ro), 
                                      lamp_map(ro - vec3(0.0, 3.0, 0.0))),
                             lamp_base_map(ro + vec3(0.0, 0.5, 0.0))),
                    floor_map(ro + vec3(0.0, 2.5, 0.0)));
}

float glass_map(in vec3 ro) {
    vec3 orig_ro = ro;
    ro = orig_ro - vec3(0.0, 3.0, 0.0);
    float top = sd_cone(vec3(0.0, 0.0, 0.0) - ROT_X_90 * ro, normalize(vec2(2.0, 1.0)));
    top = op_intersect(top, sd_box(vec3(0.0, -2.6, 0.0) - ro, vec3(3.0, 1.1, 3.0)));
    ro = orig_ro + vec3(0.0, 4.0, 0.0);
    
    return top;
}

vec3 map_normal(in vec3 ro) {
    vec2 v = vec2(EPSILON, 0.0);
    return normalize(vec3(map(ro + v.xyy) - map(ro - v.xyy),
                          map(ro + v.yxy) - map(ro - v.yxy),
                          map(ro + v.yyx) - map(ro - v.yyx)));
}

float march(in vec3 ro, in vec3 rd) {
    float td = 0.0;
    float dist = EPSILON;
    for (int i = 0; i < 100; i++) {
        if (abs(dist) < EPSILON || td >= MAX_RAY_DIST) {
            break;
        }
        
        dist = map(ro);
        td += dist;
        ro += rd * dist;
    }
    
    if (abs(dist) < EPSILON) {
        return td;
    } else {
        return INFTY;
    }
}

float march_glass(in vec3 ro, in vec3 rd) {
    float td = 0.0;
    float dist = EPSILON;
    for (int i = 0; i < 100; i++) {
        if (abs(dist) < EPSILON || td >= MAX_RAY_DIST) {
            break;
        }
        
        dist = glass_map(ro);
        td += dist;
        ro += rd * dist;
    }
    
    if (abs(dist) < EPSILON) {
        return td;
    }
    
    return INFTY;
}

#define LIGHT_COUNT 2
vec3 light_at(in int idx) {
    if (idx < 1) {
        return vec3(5.0 * sin(time), 5.0, 5.0 * cos(time));
    } else if (idx < 2) {
        return vec3(5.0 * sin(time + PI), 5.0, 5.0 * cos(time + PI));
    }
    return vec3(0.0);
}

vec3 color_at(in vec3 ro) {
    return vec3(1.0);
}

float lighting(in vec3 ro, in vec3 rd) {
    vec3 normal = map_normal(ro);
    vec3 eye = -rd;
    
    float specular = 0.0;
    float diffuse = 0.0;
    
    for (int i = 0; i < LIGHT_COUNT; i++) {
        vec3 light_pos = light_at(i);
        vec3 light_dir = normalize(ro - light_pos);
        
        vec3 ref = reflect(light_dir, normal);
        diffuse = min(1.0, diffuse + dot(ref, eye));
        specular = pow(diffuse, 128.0);
        
    }
    
    return diffuse + specular;
}

void setup_camera(in vec2 uv, out vec3 ro, out vec3 rd) {
    float mouse_theta = mouse.x*resolution.x * MOUSE_SPEED;
    float theta = time * AUTO_SPIN_SPEED + mouse_theta;
    float mouse_rho = mouse.y*resolution.y * MOUSE_SPEED;
    
    ro = vec3(CAMERA_DIST * sin(theta), 1.5 * cos(mouse_rho) + 1.5, CAMERA_DIST * cos(theta));
    vec3 target = vec3(0.0);
    vec3 up = vec3(0.0, 1.0, 0.0);
    
    vec3 camera_dir = normalize(target - ro);
    vec3 camera_right = normalize(cross(up, ro));
    vec3 camera_up = cross(camera_right, camera_dir);
    
    rd = normalize(uv.x * camera_right + uv.y * camera_up + camera_dir);
}

void main(void) {
    vec2 uv = ((gl_FragCoord.xy / resolution.xy)  - vec2(0.5)) * vec2(2.0);
    uv.x *= resolution.x / resolution.y;
    
    vec3 ro, rd;
    setup_camera(uv, ro, rd);
    float dist = march(ro, rd);
    float glass_dist = march_glass(ro, rd);
    
    vec3 base_color = vec3(0.0);
    if (glass_dist < dist) {
        base_color += vec3(0.0, 0.2, 0.2);
    }
    
    if (dist < INFTY) {
        ro += rd * dist;
        base_color += color_at(ro) * lighting(ro, rd);
    }
    
    glFragColor = vec4(base_color, 1.0);
}
