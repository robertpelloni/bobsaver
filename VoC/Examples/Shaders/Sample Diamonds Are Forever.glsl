#version 420

// original https://www.shadertoy.com/view/ldfXzn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define DELTA                0.01
#define RAY_COUNT            5
#define RAY_LENGTH_MAX        100.0
#define RAY_STEP_MAX        50
#define LIGHT                vec3 (1.0, 1.0, -1.0)
#define REFRACT_FACTOR        0.6
#define REFRACT_INDEX        1.2 // 2.417
#define AMBIENT                0.2
#define SPECULAR_POWER        3.0
#define SPECULAR_INTENSITY    0.5
#define FADE_POWER            1.0
#define M_PI                3.1415926535897932384626433832795

#define GLOW
//#define ATAN2

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

vec3 vRotateY (in vec3 p, in float angle) {
    float c = cos (angle);
    float s = sin (angle);
    return vec3 (c * p.x - s * p.z, p.y, c * p.z + s * p.x);
}

float atan2 (float y, float x) {
    #ifdef ATAN2
    // From http://www.deepdyve.com/lp/institute-of-electrical-and-electronics-engineers/full-quadrant-approximations-for-the-arctangent-function-tips-and-V6yJDoI0iF
    float t1 = abs (y);
    float t2 = abs (x);
    float t3 = min (t1, t2) / max (t1, t2);
    t3 = t3 / (1.0 + 0.28086 * t3 * t3);
    t3 = t1 > t2 ? M_PI / 2.0 - t3 : t3;
    t3 = x < 0.0 ?  M_PI - t3 : t3;
    t3 = y < 0.0 ? -t3 : t3;
    return t3;
    #else
    return atan (y, x);
    #endif
}

vec3 diamondColor;
vec3 normalTopA = normalize (vec3 (0.0, 1.0, 1.4));
vec3 normalTopB = normalize (vec3 (0.0, 1.0, 1.0));
vec3 normalTopC = normalize (vec3 (0.0, 1.0, 0.8));
vec3 normalBottomA = normalize (vec3 (0.0, -1.0, 1.6));
vec3 normalBottomB = normalize (vec3 (0.0, -1.0, 2.0));
float getDistance (in vec3 p) {
    float repeat = 20.0;
    vec3 q = mod (p + repeat * 0.5, repeat) - repeat * 0.5;
    vec3 k = floor ((p + repeat * 0.5) / repeat);
    p = mRotate (k + time) * q;
    diamondColor = clamp (sin (k * k), 0.2, 1.0);

    float topCut = p.y - 1.1;
    float angleStep = M_PI / max (1.0, 4.0 + k.x * k.y * k.z);
    float angle = angleStep * (0.5 + floor (atan2 (p.x, p.z) / angleStep));
    q = vRotateY (p, angle);
    float topA = dot (q, normalTopA) - 2.0;
    float bottomA = dot (q, normalBottomA) - 2.0;
    float topC = dot (q, normalTopC) - 1.8;
    q = vRotateY (p, -angleStep * 0.5);
    angle = angleStep * floor (atan2 (q.x, q.z) / angleStep);
    q = vRotateY (p, angle);
    float bottomB = dot (q, normalBottomB) - 1.95;
    float topB = dot (q, normalTopB) - 1.92;

    return max (topCut, max (topA, max (topB, max (topC, max (bottomA, bottomB)))));
}

vec3 getFragmentColor (in vec3 origin, in vec3 direction) {
    vec3 lightDirection = normalize (LIGHT);
    vec2 delta = vec2 (DELTA, 0.0);

    vec3 fragColor = vec3 (0.0, 0.0, 0.0);
    vec3 backColor = vec3 (0.0, 0.0, 0.1 + 0.2 * max (0.0, dot (-direction, lightDirection)));
    float intensity = 1.0;

    float distanceFactor = 1.0;
    float refractionRatio = 1.0 / REFRACT_INDEX;
    float rayStepCount = 0.0;
    for (int rayIndex = 0; rayIndex < RAY_COUNT; ++rayIndex) {

        // Ray marching
        float dist = RAY_LENGTH_MAX;
        float rayLength = 0.0;
        for (int rayStep = 0; rayStep < RAY_STEP_MAX; ++rayStep) {
            dist = distanceFactor * getDistance (origin);
            float distMin = max (dist, DELTA);
            rayLength += distMin;
            if (dist < 0.0 || rayLength > RAY_LENGTH_MAX) {
                break;
            }
            origin += direction * distMin;
            ++rayStepCount;
        }

        // Check whether we hit something
        if (dist >= 0.0) {
            fragColor = fragColor * (1.0 - intensity) + backColor * intensity;
            break;
        }

        // Get the normal
        vec3 normal = normalize (distanceFactor * vec3 (
            getDistance (origin + delta.xyy) - getDistance (origin - delta.xyy),
            getDistance (origin + delta.yxy) - getDistance (origin - delta.yxy),
            getDistance (origin + delta.yyx) - getDistance (origin - delta.yyx)));

        // Basic lighting
        vec3 reflection = reflect (direction, normal);
        if (distanceFactor > 0.0) {
            float relfectionDiffuse = max (0.0, dot (normal, lightDirection));
            float relfectionSpecular = pow (max (0.0, dot (reflection, lightDirection)), SPECULAR_POWER) * SPECULAR_INTENSITY;
            float fade = pow (1.0 - rayLength / RAY_LENGTH_MAX, FADE_POWER);
            vec3 localColor = (AMBIENT + relfectionDiffuse) * diamondColor + relfectionSpecular;
            localColor = mix (backColor, localColor, fade);

            fragColor = fragColor * (1.0 - intensity) + localColor * intensity;
            intensity *= REFRACT_FACTOR;
        }

        // Next ray...
        vec3 refraction = refract (direction, normal, refractionRatio);
        if (dot (refraction, refraction) < DELTA) {
            direction = reflection;
            origin += direction * DELTA * 2.0;
        }
        else {
            direction = refraction;
            distanceFactor = -distanceFactor;
            refractionRatio = 1.0 / refractionRatio;
        }
    }

    // Return the fragment color
    #ifdef GLOW
    fragColor += rayStepCount / float (RAY_STEP_MAX * RAY_COUNT) * 0.5;
    #endif
    return fragColor;
}

void main () {

    // Define the ray corresponding to this fragment
    vec2 frag = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec3 direction = normalize (vec3 (frag, 2.0));

    // Set the camera
    vec3 origin = vec3 ((15.0 * cos (time * 0.1)), 10.0 * sin (time * 0.2), 15.0 * sin (time * 0.1));
    vec3 forward = -origin;
    vec3 up = vec3 (sin (time * 0.3), 2.0, 0.0);
    mat3 rotation;
    rotation [2] = normalize (forward);
    rotation [0] = normalize (cross (up, forward));
    rotation [1] = cross (rotation [2], rotation [0]);
    direction = rotation * direction;

    // Set the fragment color
    glFragColor = vec4 (getFragmentColor (origin, direction)*2.0, 1.0);
}
