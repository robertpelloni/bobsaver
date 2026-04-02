#version 420

// Shader by Nicolas Robert [NRX]
// Derived from http://glsl.heroku.com/e#14662

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

#define DELTA        0.01
#define RAY_LENGTH_MAX    1000.0
#define RAY_STEP_MAX    50
#define FADE_POWER    5.0
#define M_PI        3.1415926535897932384626433832795

vec3 vRotateZ (in vec3 p, in float angle) {
    float c = cos (angle);
    float s = sin (angle);
    return vec3 (c * p.x + s * p.y, c * p.y - s * p.x, p.z);
}

void main () {

    // Define the ray corresponding to this fragment
    vec2 frag = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec3 direction = normalize (vec3 (frag, 2.0));

    // Set the camera
    vec3 origin = vec3 (0.0, 0.0, time * 40.0);
    vec3 forward = vec3 (cos (time), sin (time), 3.0 + 5.0 * sin (time * 0.5));
    vec3 up = vRotateZ (vec3 (0.0, 1.0, 0.0), M_PI * sin (time * 0.5) * sin (time * 0.2));
    mat3 rotation;
    rotation [2] = normalize (forward);
    rotation [0] = normalize (cross (up, forward));
    rotation [1] = cross (rotation [2], rotation [0]);
    direction = rotation * direction;

    // Ray marching
    vec3 p = origin;
    vec3 q=vec3(0.0);
    float rayLength = 0.0;
    for (int rayStep = 0; rayStep < RAY_STEP_MAX; ++rayStep) {
        q = p + vec3 (4.0 * sin (p.z * 0.1), 10.0 * sin (p.z * 0.05) * sin (p.z * 0.01), 0.0);
        float dist = 20.0 - length (q.xy);
        rayLength += dist;
        if (dist < DELTA || rayLength > RAY_LENGTH_MAX) {
            break;
        }
        p += direction * dist;
    }

    // Compute the fragment color
    float angle = atan (q.y, q.x);
    vec3 color = 0.5 + 0.5 * vec3 (sin (q.z * 0.4), sin (angle * 4.0), sin (q.z * 0.2) * sin (angle * 8.0));
    color *= 0.5 + 0.5 * vec3 (sin (q.z * 0.05), sin (q.z * 0.07), sin (q.z * 0.03));
    color += max (0.0, sin (q.z * 0.03 - time * 3.0) - 0.95) * 10.0;
    color *= pow (1.0 - rayLength / RAY_LENGTH_MAX, FADE_POWER);

    // Set the fragment color
    glFragColor = vec4 (color, 1.0);
}
