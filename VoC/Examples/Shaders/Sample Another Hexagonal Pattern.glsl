#version 420

// original https://www.shadertoy.com/view/3lVcRK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

struct Surface {
    float dist;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    float gloss;
};

float sdHexLink(in vec3 p, in float radius, in float thickness) {
    p = abs(p);
    return max(abs(max(dot(p.xz, vec2(0.5, 0.86602540378)), p.x) - radius), p.y) - thickness;
}

Surface mapScene(in vec3 p) {
    p.xz = sin(mod(atan(p.z, p.x), 6.28 / 6.0) - 3.14 / 6.0 + vec2(1.57, 0.0)) * length(p.xz);
    float chain1 = sdHexLink(vec3(mod(p.x - 3.0, 6.0) - 3.0, p.yz), 2.0, 0.2);
    float chain2 = sdHexLink(vec3(mod(p.x - 6.0, 6.0) - 3.0, p.z, p.y), 2.0, 0.2);
    return Surface(min(chain1, chain2), vec3(0.0), vec3(1.0, 0.0, 0.0), vec3(1.0), 16.0);
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

    vec3 ro = vec3(cos(time), 2.0 + sin(0.5 * time), cos(1.5 * time)) * 5.0;

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
