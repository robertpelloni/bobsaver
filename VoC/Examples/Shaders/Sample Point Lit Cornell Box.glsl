#version 420

// original https://www.shadertoy.com/view/3ldcD7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
I took a break from cheap directional lighting and started messing with point lights.
The cornell box was fun to model too. I really like how point lights look like little
fireflies :)

Apparently there is a better way to compute attenuation that is commonly used for
point lights so I have implemented it now.

Desmos graph of point light attenuation: https://www.desmos.com/calculator/ju4cfmbpyy
Desmos graph of transition functions: https://www.desmos.com/calculator/mg2c2blrim
*/

struct Light {
    vec3 pos; // Position of the light
    vec3 col; // Color of the light
    float Kc; // Constant attenuation term
    float Kl; // Linear attenuation term
    float Kq; // Quadratic attenuation term
};

vec3 getIllumination(in vec3 p, in Light light) {
    float d = length(p - light.pos);
    float b = 1.0 / (light.Kc + light.Kl * d + light.Kq * d * d);
    return light.col * b;
}

mat2 Rotate(in float a) {
    float rad = radians(a);
    float c = cos(rad), s = sin(rad);
    return mat2(c, -s, s, c);
}

#define t1 0.5 * time
#define t3 1.5 * time

#define c1 cos(t1) * 2.0
#define s1 sin(t1) * 2.0
#define c2 cos(time) * 2.0
#define s2 sin(time) * 2.0
#define c3 cos(t3) * 2.0
#define s3 sin(t3) * 2.0

#define blink round(fract(time * 3.0))
#define second fract(time)
#define bounce 4.0 * (second - second * second)

#define light1 Light(vec3(c1, c3, s2), vec3(1.0, 0.0, 0.0) * blink, 1.0, 0.0, 0.5)
#define light2 Light(vec3(s2, c1, s3), vec3(0.0, 1.0, 0.0) * bounce, 1.0, 0.0, 0.5)
#define light3 Light(vec3(s2, s3, c1), vec3(0.0, 0.0, 1.0), 1.0, 0.0, 0.5)

float mapScene(in vec3 p) {
    vec3 q = abs(p) - 2.5;
    float box1 = max(abs(max(q.x, max(q.y, q.z))) - 0.05, p.z - 2.0);

    p.xz *= Rotate(30.0);
    p -= vec3(0.25, -1.0, -2.0);
    q = abs(p) - vec3(0.75, 1.5, 0.75);
    float box2 = max(q.x, max(q.y, q.z));

    p -= vec3(0.8, -0.7, 2.0);
    p.xz *= Rotate(-55.0);
    q = abs(p) - 0.8;
    float box3 = max(q.x, max(q.y, q.z));

    p.y -= 1.3;
    float sphere1 = length(p) - 0.5;

    p -= vec3(-2.0, -1.0, 1.5);
    float sphere2 = length(p) - 1.0;

    return min(box1, min(box2, min(box3, min(sphere1, sphere2))));
}

vec3 getNormal(in vec3 p) {
    return normalize(vec3(mapScene(p + vec3(0.001, 0.0, 0.0)) - mapScene(p - vec3(0.001, 0.0, 0.0)),
                          mapScene(p + vec3(0.0, 0.001, 0.0)) - mapScene(p - vec3(0.0, 0.001, 0.0)),
                          mapScene(p + vec3(0.0, 0.0, 0.001)) - mapScene(p - vec3(0.0, 0.0, 0.001))));
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    glFragColor = vec4(0.0, 0.0, 0.0, 1.0);

    vec3 ro = vec3(0.0, 0.0, 5.0);
    vec3 rd = normalize(vec3(uv, -1.0));

    float t = 0.0;
    for (int i=0; i < 150; i++) {
        vec3 p = ro + rd * t;
        float d = mapScene(p);
        if (d < 0.001) {
            vec3 n = getNormal(p);

            vec3 l = normalize(light1.pos - p);
            float diffuse = max(0.0, dot(n, l));
            glFragColor.rgb += getIllumination(p, light1) * diffuse;

            l = normalize(light2.pos - p);
            diffuse = max(0.0, dot(n, l));
            glFragColor.rgb += getIllumination(p, light2) * diffuse;

            l = normalize(light3.pos - p);
            diffuse = max(0.0, dot(n, l));
            glFragColor.rgb += getIllumination(p, light3) * diffuse;

            l = normalize(vec3(-1.0, 1.0, 1.0));
            diffuse = max(0.1, dot(n, l));
            glFragColor.rgb += 0.25 * diffuse;

            break;
        }

        float ld1 = length(p - light1.pos) - 0.05;
        float ld2 = length(p - light2.pos) - 0.05;
        float ld3 = length(p - light3.pos) - 0.05;

        if (ld1 < 0.001) {
            glFragColor.rgb = light1.col;
        }

        if (ld2 < 0.001) {
            glFragColor.rgb = light2.col;
        }

        if (ld3 < 0.001) {
            glFragColor.rgb = light3.col;
        }

        if (t > 20.0) {
            break;
        }

        t += min(d, min(ld1, min(ld2, ld3)));
    }
}
