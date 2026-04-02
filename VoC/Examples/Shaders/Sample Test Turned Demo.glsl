#version 420

// original https://www.shadertoy.com/view/WttczS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

struct Light {
    vec3 pos; // Position of the light
    vec3 col; // Color of the light
};

mat2 Rotate(in float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

float noise(in float x) {
    return fract(sin(x * 12.5673) * 573.123);
}

float snoise(in float x) {
    float r = 2.735;

    float y1 = noise(floor(x / r) * r);
    float y2 = noise(ceil(x / r) * r);
    float i = fract(x / r);
    i *= i * (3.0 - 2.0 * i);

    return mix(y1, y2, i);
}

float mapScene(in vec3 p) {
    p.xz = mod(p.xz - 2.0, 4.0) - 2.0;
    p.yz *= Rotate(-60.0);
    p.xz *= Rotate(time);

    vec3 q1 = abs(p) - 1.2;
    float box = max(q1.x, max(q1.y, q1.z));

    vec2 q2 = abs(p.xy) - 0.8;
    vec2 q3 = abs(p.xz) - 0.8;
    vec2 q4 = abs(p.yz) - 0.8;

    float tube1 = max(q2.x, q2.y);
    float tube2 = max(q3.x, q3.y);
    float tube3 = max(q4.x, q4.y);

    float sphere = length(p) - 2.0;

    float scene = max(mix(box, sphere, 0.5), -mix(min(tube1, min(tube2, tube3)), sphere, 0.5)) - 0.1;
    return scene * 0.6;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    glFragColor = vec4(0.0, 0.0, 0.0, 1.0);

    float t1 = 0.5 * time;
    float t3 = 1.5 * time;

    float c1 = cos(t1) * 2.0, s1 = sin(t1) * 2.0;
    float c2 = cos(time) * 2.0, s2 = sin(time) * 2.0;
    float c3 = cos(t3) * 2.0, s3 = sin(t3) * 2.0;

    Light lights[4] = Light[](Light(vec3(c1, c3, s2), vec3(1.0, 0.0, 0.0)),
                              Light(vec3(s2, c1, s3), vec3(0.0, 1.0, 0.0)),
                              Light(vec3(s2, s3, c1), vec3(0.0, 0.0, 1.0)),
                              Light(vec3(0.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0) * snoise(time * 15.0)));

    vec3 ro = vec3(s1, s2, c3) * 3.0;
    vec3 f = -normalize(ro);
    vec3 r = normalize(vec3(-f.z, 0.0, f.x));
    vec3 u = normalize(cross(r, f));
    vec3 rd = normalize(f + uv.x * r + uv.y * u);

    float t = 0.0;
    for (int i=0; i < 150; i++) {
        vec3 p = ro + rd * t;
        float d = mapScene(p);
        if (d < 0.001) {
            glFragColor.b += 0.25;
            break;
        }

        for (int l=0; l < lights.length(); l++) {
            glFragColor.rgb += 0.005 * lights[l].col * length(ro + f * dot(lights[l].pos - ro, f) - lights[l].pos);
        }

        if (t > 50.0) {
            break;
        }

        t += d;
    }
}
