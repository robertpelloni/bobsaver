#version 420

// original https://www.shadertoy.com/view/MttGD2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 dist(vec3 z) {
    float r;
    float time = time;
    float ang = 2.0 * 3.14159265358979 / (24.0 + sin(time * 0.7 + z.y * 0.4) * 16.0);
    float s = sin(ang);
    float c = cos(ang);
    float ang2 = 2.0 * 3.14159265358979 / (22.0 + cos(time * 0.9 + z.z * 0.7) * 16.0);
    float s2 = sin(ang2);
    float c2 = cos(ang2);
    float distAcc = 0.0;
    float offsetX = sin(time * 0.2) * 0.5;
    for (int n = 0; n < 13; n++) {
        if(z.x+z.y<0.0) z.xy = -z.yx;
        if(z.x+z.z<0.0) z.xz = -z.zx;
        if(z.y+z.z<0.0) z.zy = -z.yz;

        distAcc += length(z) * pow(2.0, -float(n + 1));

        if (length(z) > 8.0) {
            return vec2((length(z) - 1.0) * pow(2.0, -float(n + 1)), distAcc);
        }

        z = vec3(
            z.x * c - z.z * s,
            z.y,
            z.x * s + z.z * c
        );

        z = z * 2.0 - vec3(1, 1, 1);
        z.xyz = z.xzy;

        z = vec3(
            z.x * c2 - z.y * s2,
            z.x * s2 + z.y * c2,
            z.z
        );
        z.x += offsetX;
    }
    return vec2((length(z) - 1.0) * pow(2.0, -12.0), distAcc);
}

vec3 estimateNormal(vec3 p) {
    float eps = 0.00001;
    float base = dist(p).x;
    return normalize(vec3(
        dist(p + vec3(eps, 0.0, 0.0)).x - base,
        dist(p + vec3(0.0, eps, 0.0)).x - base,
        dist(p + vec3(0.0, 0.0, eps)).x - base
    ));
}

vec3 colorGen(vec3 base, vec3 amplitude, vec3 frequency, vec3 shift, float t) {
    return base + amplitude * cos(6.283185 * (frequency * t + shift));
}

void main(void) {
    vec2 screenPos = (gl_FragCoord.xy - resolution.xy * 0.5) / min(resolution.x, resolution.y);
    float screenZ = 0.6;
    vec3 rayDir = normalize(vec3(screenPos, screenZ));
    vec3 rayPos = vec3(0, 0, -2);

    float time = time;
    float ang = time * 0.08 + mouse.x*resolution.x / resolution.x * 10.0;
    float s = sin(ang);
    float c = cos(ang);
    rayDir = vec3(
        rayDir.x * c - rayDir.z * s,
        rayDir.y,
        rayDir.x * s + rayDir.z * c
    );
    rayPos = vec3(
        rayPos.x * c - rayPos.z * s,
        rayPos.y,
        rayPos.x * s + rayPos.z * c
    );

    if (dist(rayPos).x < 0.0) {
        glFragColor = vec4(1.0, 1.0, 1.0, 1.0);
        return;
    }

    vec3 color = vec3(0.0, 0.0, 0.0);
    float totalDist = 0.0;
    float hit = 0.0;
    float minDist = 1000000.0;

    for (int i = 0; i < 64; i++) {
        float d = dist(rayPos).x;
        minDist = min(d, minDist);
        rayPos += rayDir * d;
        totalDist += d;
        if (d < 0.01) {
            color = vec3(1.0, 1.0, 1.0) / (1.0 + totalDist * 0.0);
            hit = 1.0;
            break;
        }
    }
    if (hit > 0.5) {
        vec3 normal = estimateNormal(rayPos);
        vec3 lightDir = normalize(vec3(1.0, -1.0, 2.0));
        lightDir = vec3(
            lightDir.x * c - lightDir.z * s,
            lightDir.y,
            lightDir.x * s + lightDir.z * c
        );
        float ambient = 0.2;
        float diffuse = 0.8;
        float brightness = max(-dot(lightDir, normal), 0.0) * diffuse + ambient;
        float r = dist(rayPos).y;
        color = colorGen(vec3(0.6, 0.4, 0.6), vec3(0.6, 0.6, 0.4), vec3(1.5, 0.9, 0.2), vec3(0.7, 0.3, 0.25), 1.0 - r) * brightness;
    } else {
        color = colorGen(vec3(0.5), vec3(0.5), vec3(0.7, 0.2, 0.5), vec3(0.4, 0.3, 0.4), minDist * 2.0);
    }
    glFragColor = vec4(color, 1.0);
}
