#version 420

// original https://www.shadertoy.com/view/XdBGDd

// Shader by Nicolas Robert [NRX]
// Latest version: http://glsl.heroku.com/e#15072.8
// Forked from: https://www.shadertoy.com/view/XdBGDd

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

float iGlobalTime;
vec3 iResolution;

#define DELTA            0.01
#define RAY_LENGTH_MAX        150.0
#define RAY_STEP_MAX        200
#define LIGHT            vec3 (0.5, 0.0, -2.0)
#define AMBIENT            0.5
#define SPECULAR_POWER        4.0
#define SPECULAR_INTENSITY    0.2
#define FADE_POWER        3.0
#define OBJ_COUNT        4
#define M_PI            3.1415926535897932384626433832795
#define OPTIMIZED

int debugCounter1;
int debugCounter2;

mat3 mRotate (in vec3 angle) {
    float c = cos (angle.x);
    float s = sin (angle.x);
    mat3 rx = mat3 (1.0, 0.0, 0.0, 0.0, c, s, 0.0, -s, c);

    c = cos (angle.y);
    s = sin (angle.y);
    mat3 ry = mat3 (c, 0.0, -s, 0.0, 1.0, 0.0, s, 0.0, c);

    c = cos (angle.z);
    s = sin (angle.z);
    mat3 rz = mat3 (c, s, 0.0, -s, c, 0.0, 0.0, 0.0, 1.0);

    return rz * ry * rx;
}

vec3 vRotateX (in vec3 p, in float angle) {
    float c = cos (angle);
    float s = sin (angle);
    return vec3 (p.x, c * p.y + s * p.z, c * p.z - s * p.y);
}

vec3 vRotateY (in vec3 p, in float angle) {
    float c = cos (angle);
    float s = sin (angle);
    return vec3 (c * p.x - s * p.z, p.y, c * p.z + s * p.x);
}

vec3 vRotateZ (in vec3 p, in float angle) {
    float c = cos (angle);
    float s = sin (angle);
    return vec3 (c * p.x + s * p.y, c * p.y - s * p.x, p.z);
}

float sphere (in vec3 p, in float r) {
    return length (p) - r;
}

float box (in vec3 p, in vec3 b, in float r) {
    vec3 d = abs (p) - b + r;
    return min (max (d.x, max (d.y, d.z)), 0.0) + length (max (d, 0.0)) - r;
}

float plane (in vec3 p, in vec3 n, in float d) {
    return dot (p, normalize (n)) + d;
}

float planeZ (in vec3 p) {
    return p.z;
}

float torusX (in vec3 p, in float r1, in float r2) {
    vec2 q = vec2 (length (p.yz) - r1, p.x);
    return length (q) - r2;
}

float torusY (in vec3 p, in float r1, in float r2) {
    vec2 q = vec2 (length (p.xz) - r1, p.y);
    return length (q) - r2;
}

float torusZ (in vec3 p, in float r1, in float r2) {
    vec2 q = vec2 (length (p.xy) - r1, p.z);
    return length (q) - r2;
}

float cylinderX (in vec3 p, in float r) {
     return length (p.yz) - r;
}

float cylinderY (in vec3 p, in float r) {
     return length (p.xz) - r;
}

float cylinderZ (in vec3 p, in float r) {
     return length (p.xy) - r;
}

vec3 twistX (in vec3 p, in float k, in float angle) {
    return vRotateX (p, angle + k * p.x);
}

vec3 twistY (in vec3 p, in float k, in float angle) {
    return vRotateY (p, angle + k * p.y);
}

vec3 twistZ (in vec3 p, in float k, in float angle) {
    return vRotateZ (p, angle + k * p.z);
}

vec3 repeat (in vec3 p, in vec3 k) {
    if (k.x > 0.0) {
        p.x = mod (p.x, k.x) - 0.5 * k.x;
    }
    if (k.y > 0.0) {
        p.y = mod (p.y, k.y) - 0.5 * k.y;
    }
    if (k.z > 0.0) {
        p.z = mod (p.z, k.z) - 0.5 * k.z;
    }
    return p;
}

float fixDistance (in float d, in float correction, in float k) {
    correction = max (correction, 0.0);
    k = clamp (k, 0.0, 1.0);
    return min (d, max ((d - DELTA) * k + DELTA, d - correction));
}

vec4 getDistance (in vec3 p, in int objectIndex) {
    ++debugCounter2;

    vec4 q;
    q.xyz = p + vec3 (2.0 * sin (p.z * 0.2 + iGlobalTime * 2.0), sin (p.z * 0.1 + iGlobalTime), 0.0);
    if (objectIndex == 0) {
        float a = atan (q.y, q.x) * 6.0;
        q.w = fixDistance (-cylinderZ (q.xyz, 4.0) + 0.5 * sin (a) * sin (q.z), 0.4, 0.8);
    }
    else if (objectIndex == 1) {
        q.xyz = twistZ (repeat (q.xyz, vec3 (5.0, 5.0, 12.0)), 1.0, iGlobalTime);
        q.w = fixDistance (box (q.xyz, vec3 (0.6, 0.6, 1.5), 0.3), 0.4, 0.8);
    }
    else if (objectIndex == 2) {
        q.z += 12.0;
        q.xyz = repeat (vRotateZ (q.xyz, sin (iGlobalTime * 4.0)), vec3 (4.0, 4.0, 24.0));
        q.w = sphere (q.xyz, 0.7);
    }
    else if (objectIndex == 3) {
        q.z += 12.0;
        q.xyz = repeat (q.xyz, vec3 (0.0, 0.0, 24.0));
        q.w = fixDistance (torusZ (q.xyz, 3.5, 0.5), 0.4, 0.8);
    }
    else {
        q.w = RAY_LENGTH_MAX;
    }
    return q;
}

vec3 getNormal (in vec3 p, in int objectIndex) {
    vec2 h = vec2 (DELTA, 0.0);
    return normalize (vec3 (
        getDistance (p + h.xyy, objectIndex).w - getDistance (p - h.xyy, objectIndex).w,
        getDistance (p + h.yxy, objectIndex).w - getDistance (p - h.yxy, objectIndex).w,
        getDistance (p + h.yyx, objectIndex).w - getDistance (p - h.yyx, objectIndex).w
    ));
}

#ifndef OPTIMIZED
int getClosestObject (in vec3 p, out vec3 q, out float rayIncrement) {
    int closestObjectIndex = -1;
    rayIncrement = RAY_LENGTH_MAX;
    for (int objectIndex = 0; objectIndex < OBJ_COUNT; ++objectIndex) {
        vec4 objectInfo = getDistance (p, objectIndex);
        if (objectInfo.w < rayIncrement) {
            rayIncrement = objectInfo.w;
            closestObjectIndex = objectIndex;
            q = objectInfo.xyz;
        }
    }
    return closestObjectIndex;
}
#else
float distObject [OBJ_COUNT];

int getClosestObject (in vec3 p, out vec3 q, inout float rayIncrement, inout float minDist1) {
    int closestObjectIndex = -1;
    float minDist2 = RAY_LENGTH_MAX;
    for (int objectIndex = 0; objectIndex < OBJ_COUNT; ++objectIndex) {
        float dist = distObject [objectIndex];
        dist -= rayIncrement;
        if (dist < minDist1) {
            vec4 objectInfo = getDistance (p, objectIndex);
            dist = objectInfo.w;
            if (dist < minDist1) {
                minDist2 = minDist1;
                minDist1 = dist;
                closestObjectIndex = objectIndex;
                q = objectInfo.xyz;
            }
            else if (dist < minDist2) {
                minDist2 = dist;
            }
        }
        distObject [objectIndex] = dist;
    }
    rayIncrement = minDist1;
    minDist1 = minDist2;
    return closestObjectIndex;
}
#endif

int rayMarch (in vec3 origin, in vec3 direction, out vec4 objectInfo) {
    #ifdef OPTIMIZED
    for (int objectIndex = 0; objectIndex < OBJ_COUNT; ++objectIndex) {
        distObject [objectIndex] = 0.0;
    }
    float minDist = RAY_LENGTH_MAX;
    #endif

    vec3 p = origin;
    objectInfo.w = 0.0;
    float rayIncrement = RAY_LENGTH_MAX;
    int closestObjectIndex = -1;
    for (int rayStep = 0; rayStep < RAY_STEP_MAX; ++rayStep) {
        ++debugCounter1;

        #ifdef OPTIMIZED
        closestObjectIndex = getClosestObject (p, objectInfo.xyz, rayIncrement, minDist);
        #else
        closestObjectIndex = getClosestObject (p, objectInfo.xyz, rayIncrement);
        #endif
        objectInfo.w += rayIncrement;
        if (rayIncrement < DELTA || objectInfo.w > RAY_LENGTH_MAX) {
            break;
        }
        p = origin + direction * objectInfo.w;
    }
    return rayIncrement < DELTA ? closestObjectIndex : -1;
}

vec3 getColor (in vec3 origin, in vec3 direction) {

    // Get the object information
    vec4 objectInfo;
    int objectIndex = rayMarch (origin, direction, objectInfo);

    // Compute the fragment color
    vec3 color;
    if (objectIndex < 0) {
        color = vec3 (0.0);
    }
    else {
        vec3 p = origin + direction * objectInfo.w;
        vec3 normal = getNormal (p, objectIndex);

        // Object color
        color = vec3 (0.5 + 0.5 * sin (normal.x * M_PI), 0.5 + 0.5 * sin (normal.y * M_PI), 0.5 + 0.5 * sin (normal.z * M_PI));
        color *= 0.9 + 0.1 * sin (objectInfo.x * 10.0) * sin (objectInfo.y * 10.0) * sin (objectInfo.z * 10.0);

        // Lighting
        vec3 lightDirection = normalize (LIGHT);
        vec3 reflectDirection = reflect (direction, normal);
        float diffuse = max (0.0, dot (normal, lightDirection));
        float specular = pow (max (0.0, dot (reflectDirection, lightDirection)), SPECULAR_POWER) * SPECULAR_INTENSITY;
        float fade = pow (1.0 - objectInfo.w / RAY_LENGTH_MAX, FADE_POWER);
        color = ((AMBIENT + diffuse) * color + specular) * fade;

        // Special effect
        color *= max (1.0, 9.0 * sin (objectInfo.w * 0.3 - iGlobalTime * 4.0) - 6.0);
    }
    return color;
}

void main () {

    iGlobalTime = time;
    iResolution = vec3 (resolution, 0.0);

    // Initialize some debug variables
    debugCounter1 = 0;
    debugCounter2 = 0;

    // Define the ray corresponding to this fragment
    vec2 p = (2.0 * gl_FragCoord.xy - iResolution.xy) / iResolution.y;
    vec3 direction = normalize (vec3 (p.x, p.y, 2.0));

    // Set the camera
    vec3 origin = vec3 (0.0, 0.0, iGlobalTime * 6.0);
    vec3 forward = vec3 (0.2 * cos (iGlobalTime), 0.2 * sin (iGlobalTime), cos (iGlobalTime * 0.3));
    vec3 up = vRotateZ (vec3 (0.0, 1.0, 0.0), M_PI * sin (iGlobalTime) * sin (iGlobalTime * 0.2));
    mat3 rotation;
    rotation [2] = normalize (forward);
    rotation [0] = normalize (cross (up, forward));
    rotation [1] = cross (rotation [2], rotation [0]);
    direction = rotation * direction;

    // Get the color of this fragment
    vec3 color = getColor (origin, direction);
    vec3 debugColor = vec3 (float (debugCounter1) / float (RAY_STEP_MAX / 2), float (debugCounter2) / float (OBJ_COUNT * RAY_STEP_MAX / 2), 0.0);
    glFragColor = vec4 (mix (color, debugColor, 0.5 + 0.5 * sin (iGlobalTime * 0.3)), 1.0);
}
