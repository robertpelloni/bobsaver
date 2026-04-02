#version 420

// original https://www.shadertoy.com/view/7llBWs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 ray_dir(vec3 z_up, vec3 dir, float fov, float aspect, vec2 uv) {
    vec3 right = normalize(cross(z_up, dir));
    vec3 up = cross(dir, right);
    return normalize(dir + right * uv.x * aspect * fov + up * uv.y * fov);
}

float hash(ivec2 p) {
    ivec2 q = p * ivec2(1317301, 1712759);
    return fract(float((q.x ^ q.y)) * 0.0001);
}

float vmin(vec3 v) {
    return min(min(v.x, v.y), v.z);
}

float base_at(vec2 p) {
    return (sin(p.x * 0.1) + sin(p.y * 0.1) - 1.0) * 2.0;
}

const float WATER_LEVEL = -5.0;

// 0 = building
// 1 = park
// 2 = crossroad
// 3 = hroad
// 4 = vroad
// 5 = water
float height_at(vec2 p, out int kind) {
    float base = base_at(floor(p));
    if (base < WATER_LEVEL) {
        kind = 5;
        return WATER_LEVEL;
    } else if (base < WATER_LEVEL + 0.5) {
        kind = 1;
        return WATER_LEVEL + 0.05;
    }
    ivec2 grid = ivec2(p);
    if (grid.x % 4 == 0) {
        if (grid.y % 4 == 0) {
            kind = 2;
            return base + 0.1;
        } else {
            kind = 4;
            return base;
        }
    } else if (grid.y % 4 == 0) {
        kind = 3;
        return base;
    }
    float grass = hash(ivec2(floor(p) * 0.2));
    if (grass > 0.85) {
        kind = 1;
        return base;
    }
    kind = 0;
    return floor(base + 1.0 + pow(hash(ivec2(p)), 8.0) * 5.0);
}

const float PLANCK = 0.01;
const vec3 SKY_COLOR = vec3(0.1, 0.1, 0.3);
const vec3 SUN_DIR = normalize(vec3(-1, 0.5, -0.5));

vec3 grass_at(vec2 pos) {
    pos += sin(pos.yx * 3.0) * 0.3;
    if (fract(pos.x * 0.3) < 0.03 || fract(pos.y * 0.3) < 0.03) return vec3(1, 0.8, 0);
    return vec3(0.5, 1, 0) * (0.5 + hash(ivec2(floor(pos * 40.0))) * 0.5);
}

float wheight(vec2 pos) {
    return dot(sin(pos.yx * 30.0 + time * 3.0 + sin(pos.xy * 10.0 + time) * 2.0), vec2(1))
        + dot(sin(pos.yx * 30.0 - time * 3.0 + sin(pos.xy * 10.0 - time) * 2.0), vec2(1));
}

vec4 roof_col(vec2 p, vec2 pos, float h, int kind, inout vec3 norm, inout float spec) {
    float base = base_at(floor(pos));
    if (kind == 5) {
        float h00 = wheight(pos + vec2(0.0, 0.0) * 0.001);
        float h10 = wheight(pos + vec2(1.0, 0.0) * 0.001);
        float h01 = wheight(pos + vec2(0.0, 1.0) * 0.001);
        
        norm = normalize(vec3(
            (h10 - h00) / 0.3,
            (h01 - h00) / 0.3,
            1.0
        ));
        spec = 100.0;
        return vec4(vec3(0.1, 0.6, 1), 0.0);
    }
    if (kind == 1) {
        return vec4(grass_at(pos), 0.0);
    }
    if ((kind == 2 || kind == 4)) {
        float car = fract(p.y + time * 0.6 * -sign(p.x - 0.5));
        if (abs(fract(p.x * 2.0) - 0.5) < 0.15 && car < 0.2) {
            float c = sign(p.x - 0.5) < 0.0 ? (car / 0.2) : (1.0 - car / 0.2);
            if (c < 0.1 && abs(fract(p.x * 2.0) - 0.5) > 0.05) return vec4(vec3(1, 1, 0.5), 4.0);
            if (c > 0.9 && abs(fract(p.x * 2.0) - 0.5) > 0.05) return vec4(vec3(1, 0, 0), 4.0);
            return vec4(vec3(1, 0.2, 0.2), 0.0);
        };
        if (abs(fract(p.x * 2.0) - 0.5) < 0.05) {
            if (fract(p.y * 6.0) < 0.5) return vec4(vec3(1), 0.0);
        }
        if (abs(fract(p.x * 2.0) - 0.5) < 0.35) {
            return vec4(vec3(0.2), 0.0);
        }
    }
    if ((kind == 2 || kind == 3)) {
        float car = fract(p.x + time * 0.6 * -sign(p.y - 0.5));
        if (abs(fract(p.y * 2.0) - 0.5) < 0.15 && car < 0.2) {
            float c = sign(p.y - 0.5) < 0.0 ? (car / 0.2) : (1.0 - car / 0.2);
            if (c < 0.1 && abs(fract(p.y * 2.0) - 0.5) > 0.05) return vec4(vec3(1, 1, 0.5), 4.0);
            if (c > 0.9 && abs(fract(p.y * 2.0) - 0.5) > 0.05) return vec4(vec3(1, 0, 0), 4.0);
            return vec4(vec3(1, 0.2, 0.2), 0.0);
        };
        if (abs(fract(p.y * 2.0) - 0.5) < 0.05) {
            if (fract(p.x * 6.0) < 0.5) return vec4(vec3(1), 0.0);
        }
        if (abs(fract(p.y * 2.0) - 0.5) < 0.35) {
            return vec4(vec3(0.2), 0.0);
        }
    }
    if (h - base > 2.5) {
        p -= 0.5;
        p = abs(p);
        if ((length(p) > 0.3 && length(p) < 0.35) || (p.x < 0.15 && p.y < 0.05) || (p.x < 0.15 && p.x > 0.1 && p.y < 0.2)) {
            return vec4(vec3(2), 0.0);
        }
    }
    
    return vec4(vec3(0.5) * (0.4 + hash(ivec2(floor(p * 10.0))) * 0.6), 0.0);
}

vec4 wall_col(vec2 p, vec3 pos, float h, int kind, inout vec3 norm) {
    if (kind == 1) {
        norm = vec3(0, 0, 1);
        return vec4(grass_at(pos.xy), 0.0);
    }
    if (kind == 2 || kind == 3 || kind == 4) {
        norm = vec3(0, 0, 1);
        return vec4(vec3(0.3), 0.0);
    }
    //if (kind != 0) {
    //    return vec4(roof_col(fract(pos.xy), pos.xy, h, kind), 0.0);
    //}
    if (fract(p.x * 7.5) > 0.5) {
        vec2 wpos = p * vec2(7.5, 6.0) + floor(vec2(0.0, h * 50.0 + pos.x + pos.y));
        if (abs(fract(wpos.x) - 0.75) < 0.15 && abs(fract(wpos.y) - 0.5) < 0.2) {
            return vec4(vec3(1, 0.9, 0.4), max(0.0, hash(ivec2(wpos)) * 2.0) - 0.5);
        }
        return vec4(vec3(0.5), 0.0);
    }
    return vec4(vec3(0.3), 0.0);
}

// (color, t)
vec4 march(vec3 dir, int iter, inout vec3 pos, out bool hit, out vec3 norm, out float t, inout float spec) {
    spec = 20.0;
    vec2 dir2d = normalize(dir.xy);
    float invlen = 1.0 / length(dir.xy);
    t = 0.0;
    for (int i = 0; i < iter; i ++) {
        vec2 deltas = (step(vec2(0), dir2d.xy) - fract(pos.xy)) / dir2d.xy;
        float jmp = max(min(deltas.x, deltas.y) * invlen, PLANCK);
        
        int kind;
        float h = height_at(pos.xy, kind);
        float col_dist = (pos.z - h) / -dir.z;
        vec3 col_pos = pos + dir * col_dist;
        if (ivec2(floor(col_pos.xy)) == ivec2(floor(pos.xy)) && col_dist > 0.0 && dir.z < 0.0) {
            hit = true;
            norm = vec3(0, 0, 1);
            t += col_dist;
            pos = col_pos;
            return roof_col(fract(col_pos.xy), col_pos.xy, h, kind, norm, spec);
        } else if (pos.z < h) {
            hit = true;
            if (abs(round(pos).x - pos.x) < PLANCK) {
                norm = vec3(-sign(dir.x), 0.0, 0.0);
                return wall_col(vec2(fract(pos.y), pos.z - h), pos, h, kind, norm);
            } else {
                norm = vec3(0.0, -sign(dir.y), 0.0);
                return wall_col(vec2(fract(pos.x), pos.z - h), pos, h, kind, norm);
            }
        }
        
        t += jmp;
        pos += dir * jmp;
    }
    hit = false;
    return vec4(vec3(0.0), 0.0);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy * 2.0 - 1.0;
    
    vec3 cam_dir = vec3(0, 1, 0);
    vec3 cam_pos = vec3(0, 1.0 + time, 5);
    
    cam_dir.xy = vec2(sin(time * 0.2), cos(time * 0.15)) * 40.0 + 20.5;
    cam_dir.z = sin(time * 0.53) * 20.0 - 16.0;
    cam_dir = normalize(cam_dir);
    cam_pos.xy = vec2(sin(time * 0.05), cos(time * 0.1)) * 50.0 + 100.0;
    cam_pos.z = max(5.0 + base_at(cam_pos.xy), WATER_LEVEL + 0.1);

    vec3 dir = ray_dir(vec3(0, 0, 1), cam_dir, 0.8, 1.5, uv);
    
    bool hit;
    vec3 norm;
    float t;
    float spec;
    vec4 surf = march(dir, 250, cam_pos, hit, norm, t, spec);
    
    vec3 sky_color = mix(
        vec3(0.7, 0.3, 0.0),
        vec3(0, 0.1, 0.3),
        pow(max(dir.z + 0.2, 0.0), 0.9)
    );
    vec3 sun_col = vec3(0.7, 0.5, 0.5);
    
    vec3 col;
    if (hit) {
        float shadow_t;
        vec3 _norm;
        float _spec;
        cam_pos += norm * 0.1;
        march(-SUN_DIR, 50, cam_pos, hit, _norm, shadow_t, _spec);
    
        float unmist = min(1.0 / exp(t * 0.03), 1.0);
        float lambert = max(dot(-SUN_DIR, norm), 0.0);
        float shadow = shadow_t > 25.0 ? 1.0 : 0.0;
        float specular = pow(max(dot(-SUN_DIR, reflect(norm, -dir)), 0.0), spec) * spec * 0.05;
        vec3 light = surf.rgb * (((lambert + specular) * shadow + 0.1) * sun_col + surf.w * unmist);
        col = mix(sky_color, light, unmist);
    } else {
        col = sky_color
            + max(0.0, 1.0 - dot(abs(fract(normalize(dir + sin(dir.zxy * 5.0) * 0.1) * 30.0) - 0.5), vec3(1)) * 8.0)
            + sun_col * pow(max(dot(dir, -SUN_DIR), 0.0), 300.0) * 2.0;
    }

    // Output to screen
    glFragColor = vec4(col * min(time * 0.3, 1.0),1.0);
}
