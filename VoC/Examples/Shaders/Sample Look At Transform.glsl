#version 420

// original https://www.shadertoy.com/view/WlKBDw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat3 lookAt(in vec3 pos, in vec3 target) {
    vec3 f = normalize(target - pos);         // Forward
    vec3 r = normalize(vec3(-f.z, 0.0, f.x)); // Right
    vec3 u = cross(r, f);                     // Up
    return mat3(r, u, f);
}

// Default position should be facing along the Z axis
float trackerObj(in vec3 p) {
    return max(abs(p.z) - 2.0, max(abs(p.x), abs(p.y)) - 0.25 + p.z * 0.25) * 0.4; // Woefully inexact
}

vec2 mapScene(in vec3 p) {
    float c = cos(time), s = sin(time);
    vec3 target = vec3(c * 5.0, 3.0 * s, c * s * 5.0) * 2.0;

    float targetShape = length(p - target) - 0.5;

    // Hexagonal tiling
    vec2 rep = vec2(6.0, 10.39);
    vec2 hrep = vec2(3.0, 5.195);
    vec2 a = mod(p.xz, rep) - hrep;
    vec2 b = mod(p.xz - hrep, rep) - hrep;
    vec2 local = dot(a, a) < dot(b, b) ? a : b;
    vec2 cell = p.xz - local;

    // Transform to local coordinates and apply look at transform
    p.xz = local;
    p *= lookAt(vec3(cell.x, 0.0, cell.y), target);
    float trackerShape = trackerObj(p);

    return vec2(min(targetShape, trackerShape), targetShape < trackerShape); // vec2(distance, id)
}

vec3 getNormal(in vec3 p) {
    vec3 e = vec3(0.001, 0.0, 0.0);
    return normalize(vec3(mapScene(p + e.xyy).x - mapScene(p - e.xyy).x,
                          mapScene(p + e.yxy).x - mapScene(p - e.yxy).x,
                          mapScene(p + e.yyx).x - mapScene(p - e.yyx).x));
}

void main(void) {
    vec2 center = 0.5 * resolution.xy;

    vec2 mouse = (mouse*resolution.xy.xy - center) / resolution.y * 3.14;
    vec2 uv = (gl_FragCoord.xy - center) / resolution.y;
    glFragColor = vec4(1.0);

    vec3 ro = vec3(0.0, 3.0, 10.0);
    vec3 rd = normalize(vec3(uv, -1.0));

    // Rotate with mouse
    float cy = cos(mouse.x), sy = sin(mouse.x);
    float cp = cos(mouse.y), sp = sin(mouse.y);

    ro.yz *= mat2(cp, -sp, sp, cp);
    ro.xz *= mat2(cy, -sy, sy, cy);
    rd.yz *= mat2(cp, -sp, sp, cp);
    rd.xz *= mat2(cy, -sy, sy, cy);

    float t = 0.0;
    for (int i=0; i < 250; i++) {
        vec3 p = ro + rd * t;
        vec2 d = mapScene(p);
        if (d.x < 0.001) {
            vec3 n = getNormal(p);
            vec3 l = normalize(vec3(-1.0, 1.0, 1.0));

            float diff = max(0.0, dot(n, l));
            glFragColor.rgb = d.y < 0.5 ? vec3(diff, 0.0, 0.0) : vec3(0.0, 0.0, diff);

            break;
        }

        if (t > 100.0) {
            break;
        }

        t += d.x;
    }
}
