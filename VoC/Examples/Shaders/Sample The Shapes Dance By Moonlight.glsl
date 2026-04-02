#version 420

// original https://www.shadertoy.com/view/ftXBWs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 ray_dir(vec3 z_up, vec3 dir, float fov, float aspect, vec2 uv) {
    vec3 right = normalize(cross(z_up, dir));
    vec3 up = cross(dir, right);
    return normalize(dir + right * uv.x * aspect * fov + up * uv.y * fov);
}

const float PLANCK = 0.01;

vec2 smin(float a, float b, float k, float n)
{
    float h = max(k - abs(a - b), 0.0) / k;
    float m = pow(h, n)*0.5;
    float s = m*k/n;
    
    vec2 inv = vec2(1.0) / vec2(a, b);
    float blend = inv.y / (inv.x + inv.y);
    
    return vec2((a<b) ? (a-s) : (b-s), blend);
}

vec4 sdf_union(vec4 a, vec4 b, float s) {
    vec2 min_blend = smin(a.w, b.w, s, 2.0);
    return vec4(mix(a.rgb, b.rgb, clamp(min_blend.y, 0.0, 1.0)), min_blend.x);
    //return a.w < b.w ? a : b;
}

float vmin(vec3 v) {
    return min(v.x, min(v.y, v.z));
}

float vmax(vec3 v) {
    return max(v.x, max(v.y, v.z));
}

float s;

vec4 sdf(vec3 pos) {
    vec3 p = pos;

    pos.xy = fract((pos.xy + 12.0) / 24.0) * 24.0 - 12.0;

    ivec2 chess = ivec2(floor(pos.xy));
    vec4 ground = vec4(
        mix(vec3(0.5), vec3(float((chess.x ^ chess.y) & 1)), clamp(10.0 / length(pos), 0.0, 1.0)),
       pos.z);
    
    float angle = time * sign(sin(p.y - pos.y) + 0.01) * 3.0 + sin(p.x - pos.x) * 10.0;
    vec2 dir = vec2(sin(angle), cos(angle));
    
    vec4 ball = vec4(vec3(1, 0, 0), length(pos + vec3(dir * 5.0, -2.0)) - 2.0);
    
    vec4 cube = vec4(vec3(0, 1, 0), length(max(vec3(0.0), abs(pos - vec3(dir * 5.0, 2)) - vec3(2, 2, 5))));

    vec4 sdf = sdf_union(sdf_union(ground, ball, s), cube, s);
    return vec4(sdf.rgb, min(sdf.w, 2.0)); // Hack
}

vec3 sdf_norm(vec3 pos) {
    float d000 = sdf(pos).w;
    float d100 = sdf(pos + vec3(PLANCK, 0.0, 0.0)).w;
    float d010 = sdf(pos + vec3(0.0, PLANCK, 0.0)).w;
    float d001 = sdf(pos + vec3(0.0, 0.0, PLANCK)).w;
    
    return normalize(d000 - vec3(d100, d010, d001));
}

const vec3 sky = vec3(0.2, 0.3, 0.6);
vec3 sun_dir;

vec3 color_ray(vec3 dir, inout vec3 pos, out bool hit) {
    for (int i = 0; i < 256; ++i) {
        vec4 col_dist = sdf(pos);
        float dist = col_dist.w;
        
        if (dist < PLANCK) {
            hit = true;
            return col_dist.rgb;
        }
        
        pos += dir * dist;
    }
    
    hit = false;
    return sky;
}

float shadow_ray(vec3 dir, inout vec3 pos) {
    vec3 p = pos;
    float min_shade = 1.0;
    
    // Throw in a bit of noise
    pos += dir * PLANCK * 1.0 * fract(dot(pos, vec3(1000.0)));
    
    float t = 0.0;
    float last_dist = 1e20;
    for (int i = 0; i < 256; ++i) {
        float dist = sdf(pos).w;
        
        // Approaching surface
        if (dot(sdf_norm(pos - dir * last_dist), dir) > 0.0) {
            float y = dist*dist/(2.0*last_dist);
            float d = sqrt(dist*dist-y*y);
            d = dist;

            min_shade = min(min_shade, d * 3.0 / t);
            
            if (dist < PLANCK) {
                min_shade = 0.0;
                break;
            }
        }
        
        last_dist = dist;
        t += dist;
        
        pos += dir * dist;
    }
    
    return min_shade;
}

vec3 ray_cast(vec3 dir, inout vec3 pos) {
    bool hit;
    vec3 p = pos;
    vec3 color = color_ray(dir, pos, hit);
    vec3 q = pos;
    
    vec3 light = vec3(0);
    if (hit) {
        vec3 norm = sdf_norm(pos);
        float lambert = max(dot(sun_dir, norm), 0.0);
        float specular = pow(max(dot(reflect(-sun_dir, norm), dir), 0.0), 120.0) * 3.0;
        float shade = min(lambert, clamp(shadow_ray(-sun_dir, pos), 0.0, 1.0));
        float ambient = 0.1;
        light = ((ambient + shade) * color + specular * shade) * sky * 2.0;
        light = mix(sky, light, min(1.0 / exp(0.01 * distance(p, q)), 1.0));
    } else {
        light = sky + pow(max(dot(dir, -sun_dir), 0.0), 250.0) * 1.0;
    }
    
    return light;
}

void main(void)
{
    sun_dir = normalize(vec3(vec2(sin(time), cos(time)) * sin(time * 0.2) * 5.0, -2.0));
    s = 16.0 * sin(time * 3.0) * 0.5 + 0.5;

    vec2 uv = gl_FragCoord.xy/resolution.xy - 0.5;
    
    vec2 angle = (mouse*resolution.xy.xy - resolution.xy / 2.0) * 0.01;
    vec3 cam_pos = vec3(vec2(sin(angle.x), cos(angle.x)) * 10.0, angle.y * 6.0 + 10.0);
    
    cam_pos.xy = vec2(sin(time * 0.5), cos(time * 0.8)) * 50.0;
    cam_pos.z = 6.0 + (sin(time * 1.5) * 0.5 + 0.5) * 30.0;
    
    vec3 cam_focus = vec3(-vec2(sin(time * 1.2), cos(time * 1.0 + 0.5)) * 50.0 + vec2(10.0, 15.0), 5.0);
    cam_pos.z = 7.5 + (sin(time * 1.3) * 0.5 + 0.5) * 30.0;
    vec3 cam_dir = -normalize(cam_pos - cam_focus);
    
    vec3 dir = ray_dir(vec3(0, 0, 1), cam_dir, 1.5, 1.5, uv);
    
    vec3 col = ray_cast(dir, cam_pos);

    // Output to screen
    glFragColor = vec4(col * min(time * 0.1, 1.0),1.0);
}
