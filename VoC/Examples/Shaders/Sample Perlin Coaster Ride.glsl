#version 420

// original https://www.shadertoy.com/view/sddXWf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define FAR 200.0
#define EPSILON 1e-3
#define ID(func, nid) dist = func(pos); if (dist < closest) { closest = dist; id = nid; }

vec2 rand2d(vec2 uv) {
    return fract(sin(vec2(dot(uv, vec2(12.34, 45.67)),
        dot(uv, vec2(78.9, 3.14)))) * 12345.67) * 2.0 - 1.0;
}

float perlin(vec2 uv) {
    vec2 u = floor(uv);
    vec2 f = fract(uv);
    vec2 s = smoothstep(0.0, 1.0, f);
    
    vec2 a = rand2d(u);
    vec2 b = rand2d(u + vec2(1.0, 0.0));
    vec2 c = rand2d(u + vec2(0.0, 1.0));
    vec2 d = rand2d(u + vec2(1.0, 1.0));
    
    return mix(mix(dot(a, f), dot(b, f - vec2(1.0, 0.0)), s.x),
        mix(dot(c, f - vec2(0.0, 1.0)), dot(d, f - vec2(1.0, 1.0)), s.x), s.y);
}

float sol(vec3 pos) {
    vec2 uv = pos.xz;
    return pos.y - perlin(uv);
}

float ball(vec3 pos) {
    return length(pos) - 0.5;
}

vec2 map(vec3 pos) {
    float closest = 1000.0;
    float id = -1.0;
    float dist = 0.0;

    ID(sol, 0.5);

    return vec2(closest, id);
}

vec3 objectColor(vec3 pos, float id) {
    if (id > 0.0 && id < 1.0) {
        vec2 u = mod(floor(pos.xz), 2.0);
        vec3 color = max(vec3(abs(u.x - u.y)), 0.8);
        
        return color;
    }
    if (id > 1.0 && id < 2.0) {
        return vec3(0.5, 1.0, 0.0);
    }
    return vec3(1.0, 0.0, 0.0);
}

vec2 trace(vec3 ro, vec3 rd) {
    float depth = 0.0;
    float id = -1.0;
    for (int i = 0; i < 800; i++) {
        vec2 info = map(ro + depth * rd);
        if (info.x < EPSILON) {
            id = info.y;
            break;
        }
        depth += info.x;
        if (depth > FAR) {
            break;
        }
    }
    return vec2(depth, id);
}

vec3 getNormal(vec3 pos) {
    float mapped = map(pos).x;
    
    return normalize(vec3(
        mapped - map(pos - vec3(EPSILON, 0.0, 0.0)).x,
        mapped - map(pos - vec3(0.0, EPSILON, 0.0)).x,
        mapped - map(pos - vec3(0.0, 0.0, EPSILON)).x));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy / resolution.xy) * 2.0 - 1.0;
    float aspect = resolution.x / resolution.y;
    uv.x *= aspect;
    
    vec3 ro = vec3(0.0, perlin(vec2(0.0, time)) + 0.2, time);
    vec3 center = ro + vec3(0.0, perlin(vec2(0.0, ro.z + 1.0)), 1.0);
    vec3 worldUp = getNormal(vec3(ro.x, ro.y - 0.2, ro.z));
//    vec3 center = vec3(0.0, 0.1, 0.0);
    vec3 front = normalize(center - ro);
    vec3 right = normalize(cross(front, worldUp));
    vec3 up = normalize(cross(right, front));
    mat4 lookAt = mat4(
        vec4(right, 0.0),
        vec4(up, 0.0),
        vec4(front, 0.0),
        vec4(0.0, 0.0, 0.0, 1.0));
    vec3 rd = vec3(lookAt * normalize(vec4(uv, 1.0, 1.0)));
    
    vec2 info = trace(ro, rd);
    
    vec3 sky = mix(vec3(0.78, 0.9, 1.0), vec3(1.0), 1.0 - uv.y);
    
    if (info.y > 0.0) {
        vec3 pos = ro + info.x * rd;
        vec3 color = objectColor(pos, info.y);
        
        // Lighting calculations
        vec3 norm = getNormal(pos);
        
        // World lights
        vec3 ambient = 0.1 * vec3(1.0);
        vec3 skyColor = clamp(dot(norm, vec3(0.0, 1.0, 0.0)), 0.0, 1.0) * vec3(1.0);
        // Light 1
         
        glFragColor = vec4(
            (ambient + skyColor) * color, 
            1.0);
        
        // Falloff begins at depth > 5 and goes all the way to 10.0
        float falloff = min(max(info.x - 5.0, 0.0) / 5.0, 1.0);
        glFragColor = mix(glFragColor, vec4(sky, 1.0), falloff);
    } else {
        glFragColor = vec4(sky, 1.0);
    }
}
