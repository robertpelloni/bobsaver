#version 420

// original https://www.shadertoy.com/view/tttfzB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sdBox(in vec3 p, in vec3 d) {
    vec3 q = abs(p) - d;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdBox2D(in vec2 p, in vec2 d) {
    vec2 q = abs(p) - d;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
}

vec2 pModPolar(in vec2 p, in float offs, in float reps) {
    float rep = 6.28 / reps, hRep = 0.5 * rep;
    return sin(mod(atan(p.y, p.x) + offs + hRep, rep) - hRep + vec2(1.57, 0.0)) * length(p);
}

float mapScene(in vec3 p) {
    float turn = time;

    float c = cos(turn), s = sin(turn);
    vec3 p1 = p, p2 = p;

    float cell = mod(floor(atan(p1.z, p1.x) / 6.28 * 6.0 + 0.5), 2.0);
    float dir = cell * 2.0 - 1.0, lock = cell * 0.157;
    p1.xz = pModPolar(p1.xz, 0.0, 6.0) - vec2(3.0, 0.0);
    p1.xy *= mat2(c, -s, s, c);

    float teeth1 = sdBox(vec3(pModPolar(p1.xz, turn * dir + lock, 20.0), p1.y).xzy - vec3(1.35, 0.0, 0.0), vec3(0.25, 0.175, 0.075));
    float ring1 = sdBox2D(vec2(length(p1.xz) - 1.1, p1.y), vec2(0.25));
    float gears1 = min(ring1, teeth1);

    cell = mod(floor(atan(p2.z, p2.x) / 6.28 * 6.0), 2.0);
    dir = cell * 2.0 - 1.0, lock = cell * 0.157;
    p2.xz = pModPolar(p2.xz, 0.52, 6.0) - vec2(2.75, 0.0);
    p2.xy *= mat2(c, -s, s, c);
    p2.xy = p2.yx;

    float teeth2 = sdBox(vec3(pModPolar(p2.xz, turn * dir + lock, 20.0), p2.y).xzy - vec3(1.35, 0.0, 0.0), vec3(0.25, 0.175, 0.075));
    float ring2 = sdBox2D(vec2(length(p2.xz) - 1.1, p2.y), vec2(0.25));
    float gears2 = min(ring2, teeth2);

    return min(gears1, gears2) - 0.025;
}

vec3 getNormal(in vec3 p) {
    vec3 e = vec3(0.01, 0.0, 0.0);
    return normalize(vec3(mapScene(p + e.xyy) - mapScene(p - e.xyy),
                          mapScene(p + e.yxy) - mapScene(p - e.yxy),
                          mapScene(p + e.yyx) - mapScene(p - e.yyx)));
}

void main(void) {
    vec2 screenCenter = 0.5 * resolution.xy;

    vec2 mouse = (mouse*resolution.xy.xy - screenCenter) / resolution.y * 3.14;
    vec2 uv = (gl_FragCoord.xy - screenCenter) / resolution.y;
    glFragColor = vec4(0.0, 0.0, 0.0, 1.0);

    vec3 ro = vec3(0.0, 0.0, 10.0);
    vec3 rd = normalize(vec3(uv, -1.0));

    vec2 rot = vec2(time, -0.6);
    //if (mouse*resolution.xy.z > 0.0) rot += mouse;

    float cy = cos(rot.x), sy = sin(rot.x);
    float cp = cos(rot.y), sp = sin(rot.y);

    ro.yz *= mat2(cp, -sp, sp, cp);
    rd.yz *= mat2(cp, -sp, sp, cp);

    ro.xz *= mat2(cy, -sy, sy, cy);
    rd.xz *= mat2(cy, -sy, sy, cy);

    float t = 0.0;
    for (float i=0.0; i < 100.0; i++) {
        vec3 p = ro + rd * t;
        float d = mapScene(p);
        if (d < 0.001) {
            vec3 n = getNormal(p);
            vec3 l = vec3(-0.58, 0.58, 0.58);

            l.yz *= mat2(cp, -sp, sp, cp);
            l.xz *= mat2(cy, -sy, sy, cy);

            float fogginess = 1.0 - exp(-t * 0.05);
            glFragColor.rgb = mix(vec3(max(0.0, dot(n, l))), vec3(0.25, 0.25, 1.0), fogginess);
            break;
        }

        if (t > 50.0) {
            glFragColor.rgb = mix(vec3(0.25, 0.25, 1.0), vec3(1.0), 0.5 + 0.5 * rd.y);
            break;
        }

        t += d;
    }
}
