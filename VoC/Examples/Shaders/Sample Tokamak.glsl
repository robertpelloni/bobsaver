#version 420

// original https://www.shadertoy.com/view/ttV3Dt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 rotate(vec3 p, float angle, vec3 axis){
    vec3 a = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float r = 1.0 - c;
    mat3 m = mat3(
        a.x * a.x * r + c,
        a.y * a.x * r + a.z * s,
        a.z * a.x * r - a.y * s,
        a.x * a.y * r - a.z * s,
        a.y * a.y * r + c,
        a.z * a.y * r + a.x * s,
        a.x * a.z * r + a.y * s,
        a.y * a.z * r - a.x * s,
        a.z * a.z * r + c
    );
    return m * p;
}

const float THRESHOLD = 0.0001;
const float maiorRadius = 5.0;
const float minorRadius = 3.0;

// --------------------------------------------------------------------------

// distance estimators
float torusDist(vec3 p) {
    float f1 = min(abs(0.3 * sin(10.0 * atan(p.z, p.x))), 0.1);
    vec2 uv = vec2(-atan(p.z, p.x), atan(p.y, length(p.xz) - maiorRadius)) / 2.0 / 3.141592 + 0.5;
    float f2 = max(sin(200. * uv.x) * sin(200. * uv.y) - 0.95, 0.0);
    float dis1 = minorRadius - (f1 + f2) - length(vec2(length(p.xz) - maiorRadius, p.y));
    return dis1;
}

float tubesDist(vec3 p) {
    float d1 = length(vec2(length(p.xz) - (maiorRadius + minorRadius - 0.5), p.y - 1.3)) - 0.2;
    float d2 = length(vec2(length(p.xz) - (maiorRadius + minorRadius - 0.5), p.y + 1.3)) - 0.2;
    float d3 = length(vec2(length(p.xz) - (maiorRadius - minorRadius + 0.6), p.y + 1.5)) - 0.2;
    float d4 = length(vec2(length(p.xz) - (maiorRadius - minorRadius + 1.0), p.y + 2.0)) - 0.2;
    return min(min(d1, d2), min(d3, d4));
}

float floorDist(vec3 p) {
    return p.y + 2.7;
}

float ceilDist(vec3 p) {
    float f = max(sin(10. * atan(p.z, p.x)) - 0.6, 0.0);
    float d1 = length(vec2(length(p.xz) - maiorRadius + 1.0, p.y - minorRadius - 2.0)) - 2.5 - f;
    float d2 = length(vec2(length(p.xz) - maiorRadius - 1.0, p.y - minorRadius - 2.0)) - 2.5 - f;
    return min(d1, d2);
}

float protonsDist(vec3 p) {
    vec3 p1 = rotate(p, 10.0 * time, vec3(0., 1., 0.));
    float d1 = length(vec2(length(p1.xz) - maiorRadius, p1.y + 0.0)) - 0.1 * (sin(0.5 * atan(p1.z, p1.x)) + 1.0);
    return d1;
}

float sceneDist(vec3 p) {
    float v = min(min(torusDist(p), tubesDist(p)), min(floorDist(p), ceilDist(p)));
    return min(v, protonsDist(p));
}

// --------------------------------------------------------------------------

vec3 torusColor(vec3 p) {
    return vec3(0.9, 0.9, 1.0);
}

vec3 floorColor(vec3 p) {
    return vec3(max(sin(50.0 * p.x) - 0.5, 0.0) + max(sin(50.0 * p.z) - 0.5, 0.0));
}

vec3 ceilColor(vec3 p) {
    return vec3(0.9, 0.9, 1.0);
}

vec3 tubesColor(vec3 p) {
    return vec3(0.8, 0.9, 1.0);
}
    
// --------------------------------------------------------------------------

void main(void)
{
    vec2 p = ( gl_FragCoord.xy * 2. - resolution.xy ) / min(resolution.x, resolution.y);
    vec2 mo = mouse*resolution.xy.xy / resolution.xy - 0.5;

    vec3 cameraPos = vec3(0., -0.5, -7.);
    float screenZ = 2.0;
    vec3 rayDirection = normalize(vec3(p, screenZ));

    rayDirection = rotate(rayDirection, -0.05, vec3(0., 0., 1.));

    rayDirection = rotate(rayDirection, 2. * mo.x, vec3(0., 1., 0.));
    rayDirection = rotate(rayDirection, 2. * mo.y, vec3(1., 0., 0.));

    cameraPos = rotate(cameraPos, time, vec3(0., 1., 0.));
    rayDirection = rotate(rayDirection, time, vec3(0., 1., 0.));

    float depth = 0.0;
    vec3 col = vec3(1.0);
    vec3 rayPos;

    // ray marching
    int i = 0;
    for (i = 0; i < 99; i++) {
        rayPos = cameraPos + rayDirection * depth;
        float dist = sceneDist(rayPos);
        if (dist < THRESHOLD) {
            if      (torusDist(rayPos) < THRESHOLD) col = torusColor(rayPos);
            else if (floorDist(rayPos) < THRESHOLD) col = floorColor(rayPos);
            else if (ceilDist(rayPos)  < THRESHOLD) col = ceilColor(rayPos);
            else if (tubesDist(rayPos) < THRESHOLD) col = tubesColor(rayPos);
            if (protonsDist(rayPos) < THRESHOLD) col = vec3(100.0);
            break;
        }
        depth += dist;
    }

    col = col * (1.6 / (1.0 + 0.1 * depth)); // scurisce con la profondita'
    col = 0.1 * col * max(0.3 * float(i), 1.0); // effetto aura (schiarisce all'aumentare di i)
    col = mix(col, vec3(0.6, 0.5, 1.0), max(1.0 - minorRadius - rayPos.y, 0.0));

    // luce rossa lampeggiante
    float f = sin(6. * time) * 0.3 + 0.3;
    col = col * vec3(1., 1. - f, 1. - f);
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
