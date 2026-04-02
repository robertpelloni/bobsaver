#version 420

// original https://www.shadertoy.com/view/3lyczK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Hue to RGB function from Fabrice's shadertoyunofficial blog:
#define hue2rgb(hue) 0.6 + 0.6 * cos(6.3 * hue + vec3(0.0, 23.0, 21.0))

// Woah thats trippy!
//#define PSYCHO_MODE

struct Surface {
    float dist;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    float gloss;
};

float sdHexShape(in vec3 p, in float s) {
    const vec2 n = normalize(vec2(1.0, sqrt(3.0)));
    p = abs(p);
    vec2 p2 = vec2(max(dot(p.xz, n), p.x), p.y);

    #ifdef PSYCHO_MODE
    return max(length(p.xz) - 1.0, abs(p.y - s) - s);
    #else
    return max(abs(p2.x - s), p2.y) - 0.1;//max(dot(p2, n), p2.x) - s;
    #endif
}

Surface mapScene(in vec3 p) {
    vec2 rep = vec2(2.0, 3.46); // 1.73 ~ sqrt(3)
    vec2 hrep = 0.5 * rep;
    vec2 a = mod(p.xz, rep) - hrep;
    vec2 b = mod(p.xz - hrep, rep) - hrep;
    vec2 hexUv = dot(a, a) < dot(b, b) ? a : b;
    vec2 cellId = p.xz - hexUv;
    p.xz = hexUv;

    float oscPoint = 0.5;
    float freq = 0.5;
    float amp = 0.4;
    #ifdef PSYCHO_MODE
    oscPoint = 5.0;
    freq = 0.25;
    amp = 2.5;
    #endif

    float ripples = oscPoint + amp * sin(length(cellId) * freq - time * 4.0);
    return Surface(sdHexShape(p, ripples) * 0.25, vec3(0.2, 0.0, 0.0), hue2rgb(ripples * freq), vec3(1.0), 8.0);
}

vec3 getNormal(in vec3 p) {
    vec3 e = vec3(0.001, 0.0, 0.0);
    return normalize(vec3(mapScene(p + e.xyy).dist - mapScene(p - e.xyy).dist,
                          mapScene(p + e.yxy).dist - mapScene(p - e.yxy).dist,
                          mapScene(p + e.yyx).dist - mapScene(p - e.yyx).dist));
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    glFragColor = vec4(0.0, 0.0, 0.0, 1.0);

    float camDist = 5.0;
    #ifdef PSYCHO_MODE
    camDist = 20.0;
    #endif

    vec3 ro = vec3(cos(time), 2.0 + sin(0.5 * time), cos(1.5 * time)) * camDist;

    vec3 f = -normalize(ro);
    vec3 r = normalize(vec3(-f.z, 0.0, f.x));
    vec3 u = normalize(cross(r, f));
    vec3 rd = normalize(f + uv.x * r + uv.y * u);

    vec3 l = vec3(-0.58, 0.58, 0.58);

    float time = 0.5 * time;
    float c = cos(time), s = sin(time);
    l.xz *= mat2(c, s, -s, c);

    float t = 0.0;
    for (int i=0; i < 100; i++) {
        vec3 p = ro + rd * t;
        Surface scene = mapScene(p);
        if (scene.dist < 0.001) {
            vec3 n = getNormal(p);
            glFragColor.rgb += scene.ambient;

            float lambertian = max(0.0, dot(n, l));
            glFragColor.rgb += scene.diffuse * lambertian;

            if (lambertian > 0.0) {
                vec3 r = reflect(l, n);
                float specAngle = max(0.0, dot(r, rd));
                glFragColor.rgb += scene.specular * max(0.0, pow(specAngle, scene.gloss));
            }

            break;
        }

        if (t > 100.0) {
            break;
        }

        t += scene.dist;
    }
}
