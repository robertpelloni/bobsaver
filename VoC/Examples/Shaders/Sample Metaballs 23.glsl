#version 420

// original https://www.shadertoy.com/view/3dGBDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
Recreation of "Blob" by Henrik Rydgard: https://webglsamples.org/blob/blob.html
I hope to recreate more too :)

No more fishy specular lighting now!
*/

#define NUMBER_OF_BLOBS 10.0

#define SIN_15 0.2588190451
#define COS_15 0.96592582628

// Inigo Quilez's polynomial smooth minimum from https://www.iquilezles.org/www/articles/smin/smin.htm:
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float mapScene(in vec3 p) {
    p.yz *= mat2(COS_15, SIN_15, -SIN_15, COS_15);
    float c = cos(0.25 * time), s = sin(0.25 * time);
    p.xz *= mat2(c, -s, s, c);

    vec3 q = abs(p + vec3(0.0, 3.0, 0.0)) - vec3(8.0, 0.25, 8.0);
    float scene = max(q.x, max(q.y, q.z));
    for (float blob=0.0; blob < NUMBER_OF_BLOBS; blob++) {
        float s1 = 0.2 * blob, s2 = cos(blob), s3 = sin(blob);
        vec3 position = 5.0 * vec3(sin(s1 * time) * cos(s1 * time), cos(s2 * time), sin(s3 * time));
        scene = smin(scene, length(p - position) - 1.5, 2.0);
    }

    return scene;
}

vec3 getNormal(in vec3 p) {
    return normalize(vec3(mapScene(p + vec3(0.001, 0.0, 0.0)) - mapScene(p - vec3(0.001, 0.0, 0.0)),
                          mapScene(p + vec3(0.0, 0.001, 0.0)) - mapScene(p - vec3(0.0, 0.001, 0.0)),
                          mapScene(p + vec3(0.0, 0.0, 0.001)) - mapScene(p - vec3(0.0, 0.0, 0.001))));
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    vec3 ro = vec3(0.0, 0.0, 10.0);
    vec3 rd = normalize(vec3(uv, -1.0));
    glFragColor = vec4(0.24375, 0.16125, 0.07875, 1.0);
    float dt = 0.0;
    for (int iter=0; iter < 250; iter++) {
        vec3 p = ro + rd * dt;
        float d = mapScene(p);
        if (d < 0.001) {
            vec3 n = getNormal(p);
            vec3 l = vec3(-0.58, 0.58, 0.58);
            vec3 r = reflect(l, n);
            glFragColor.rgb = 0.5 * max(0.0, dot(n, l)) + 0.5 * vec3(0.824, 0.706, 0.549);
            glFragColor.rgb += 0.5 * pow(max(0.0, dot(r, rd)), 16.0);
            break;
        }

        if (dt > 100.0) {
            break;
        }

        dt += d;
    }
}
