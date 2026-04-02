#version 420

// original https://www.shadertoy.com/view/wdyBRh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sceneMap(in vec3 p) {
    vec3 q = abs(p) - 1.0;
    return max(q.x, max(q.y, q.z));
}

vec3 colorMap(in vec3 p) {
    vec3 n = abs(p);
    float m = max(n.x, max(n.y, n.z));

    vec2 uv = p.xy;
    bool flip = false;
    if (m == n.z) {
        flip = p.z > 0.0;
    }

    if (m == n.x) {
        uv = p.yz;
        flip = p.x < 0.0;
    }

    if (m == n.y) {
        uv = p.xz;
        flip = p.y < 0.0;
    }

    uv *= 4.0;
    float fill = mod(floor(uv.x) + floor(uv.y), 2.0);
    if (flip) {
        fill = 1.0 - fill;
    }

    return vec3(fill);
}

vec3 raymarch(in vec3 ro, in vec3 rd, in float t) {
    float distTraveled = 0.0;
    for (int i=0; i < 100; i++) {
        vec3 pos = ro + rd * distTraveled;

        float time = mod(t, 4.5);

        float t1 = clamp(time * 3.0 - 3.0, 0.0, 6.28);
        t1 = pow(t1, 1.0 + sin(t1 * 0.5));
        float t2 = clamp(time - 3.34, 0.0, 1.0);
        float t3 = min(3.0, time * 3.0);

        pos.z += t3;
        pos.z -= t2 * 3.0;

        float c = cos(t1);
        float s = sin(t1);
        pos.xz = vec2(pos.x * c + pos.z * s, pos.x * s - pos.z * c);

        float tumble = t2 * 1.57;
        c = cos(tumble);
        s = sin(tumble);
        pos.yz = vec2(pos.y * c - pos.z * s, pos.y * s + pos.z * c);

        float dist = sceneMap(pos);
        if (dist < 0.001) {
            return colorMap(pos);
        }

        if (distTraveled > 1000.0) {
            break;
        }

        distTraveled += dist;
    }

    return vec3(0.5);
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    glFragColor = vec4(0.0, 0.0, 0.0, 1.0);

    float tSamples = 0.0;
    for (float tOffset=0.0; tOffset > -0.006; tOffset -= 0.001) {
        glFragColor.rgb += raymarch(vec3(0.0, 0.0, 3.0), normalize(vec3(uv, -1.0)), time + tOffset);
        tSamples += 1.0;
    }

    glFragColor /= tSamples;
}
