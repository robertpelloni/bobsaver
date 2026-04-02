#version 420

// original https://www.shadertoy.com/view/MlfGR4

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;

out vec4 glFragColor;

#define dist dist_OPTIMIZED // choose between CLASSIC and OPTIMIZED
#define SHADOW
//#define SHADERTOY

#define CAMERA_FOCAL_LENGTH    1.5
#define DELTA                0.001
#define RAY_LENGTH_MAX        100.0
#define RAY_STEP_MAX        100
#define AMBIENT                0.3
#define SPECULAR_POWER        3.0
#define SPECULAR_INTENSITY    0.3
#define FADE_POWER            1.0
#define GAMMA                0.8
#define PI                    3.14159265359
#define SQRT3                1.73205080757

// Distance to the voxel (rounded box)
float distVoxel (in vec3 p) {
    const float d = 0.45;
    const float r = 0.25;
    return length (max (abs (fract (p + 0.5) - 0.5) - d + r, 0.0)) - r;
}

// Distance to the scene (pac-man & ground)
float distScene (in vec3 p) {
    float r1 = length (p);
    float r2 = length (vec3 (abs (p.x) - 6.0, p.yz - 10.0));
    float ground = p.y + 20.0;
    float body = max (r1 - 16.0, 14.0 - r1);
    float eyes = 3.0 - r2;
    float mouthMove = cos (time * 8.0);
    float mouthTop = 2.0 - p.y + (0.15 + 0.15 * mouthMove) * p.z;
    float mouthBottom = p.y - 3.0 + (0.6 + 0.6 * mouthMove) * p.z;
    return min (ground, max (max (body, eyes), min (mouthTop, mouthBottom)));
}

// Distance to the voxelized scene (classic)
vec2 dist_CLASSIC (inout vec3 p, in vec3 ray) {
    vec3 raySign = sign (ray);
    vec3 rayIncrement = raySign / ray;
    vec3 rayTime = (0.5 + raySign * (0.5 - fract (p + 0.5))) * rayIncrement;
    vec3 rayPosition = floor (p + 0.5);
    vec3 rayAxis = vec3 (0.0);
    float time = min (rayTime.x, min (rayTime.y, rayTime.z));
    for (int rayStep = 0; rayStep < RAY_STEP_MAX; ++rayStep) {
        rayAxis = step (rayTime.xyz, rayTime.yzx) * step (rayTime.xyz, rayTime.zxy);
        rayPosition += rayAxis * raySign;
        rayTime += rayAxis * rayIncrement;
        float timeNext = min (rayTime.x, min (rayTime.y, rayTime.z));
        if (distScene (rayPosition) < 0.0) {
            vec3 pp = p + ray * time;
            for (int i = 0; i < 20; ++i) {
                float d = distVoxel (pp);
                if (d < DELTA) {
                    p = pp;
                    return vec2 (d, time);
                }
                pp += ray * d;
                time += d;
                if (time > timeNext) {
                    break;
                }
            }
        }
        time = timeNext;
        if (time > RAY_LENGTH_MAX) {
            break;
        }
    }
    return vec2 (1.0);
}

// Distance to the voxelized scene (optimized)
vec2 dist_OPTIMIZED (inout vec3 p, in vec3 ray) {
    vec3 raySign = sign (ray);
    vec3 rayIncrement = raySign / ray;
    float rayTimeOut = 0.0;
    float rayLength = 0.0;
    for (int rayStep = 0; rayStep < RAY_STEP_MAX; ++rayStep) {
        float d;
        if (rayTimeOut <= 0.0) {
            d = distScene (p);
            if (d < SQRT3 * 0.5) {
                if (distScene (floor (p + 0.5)) < 0.0) {
                    vec3 rayTime = (0.5 - raySign * (0.5 - fract (p + 0.5))) * rayIncrement;
                    rayTimeOut = min (rayTime.x, min (rayTime.y, rayTime.z));
                    d = -rayTimeOut;
                    rayTime = rayIncrement - rayTime;
                    rayTimeOut += min (rayTime.x, min (rayTime.y, rayTime.z));
                } else {
                    vec3 rayTime = (0.5 + raySign * (0.5 - fract (p + 0.5))) * rayIncrement;
                    d = DELTA + min (rayTime.x, min (rayTime.y, rayTime.z));
                }
            } else {
                d *= 0.7; // correction needed... (to be checked)
            }
        } else {
            d = distVoxel (p);
            if (d < DELTA) {
                return vec2 (d, rayLength);
            }
            rayTimeOut -= d;
        }
        rayLength += d;
        if (rayLength > RAY_LENGTH_MAX) {
            break;
        }
        p += d * ray;
    }
    return vec2 (1.0);
}

// PRNG
// From https://www.shadertoy.com/view/4djSRW
float rand (in vec3 seed) {
    seed = fract (seed * vec3 (5.3983, 5.4427, 6.9371));
    seed += dot (seed.yzx, seed.xyz + vec3 (21.5351, 14.3137, 15.3219));
    return fract (seed.x * seed.y * seed.z * 95.4337);
}

// HSV to RGB
vec3 rgb (in vec3 hsv) {
    hsv.yz = clamp (hsv.yz, 0.0, 1.0);
    return hsv.z * (1.0 + hsv.y * clamp (abs (fract (hsv.xxx + vec3 (0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 2.0, -1.0, 0.0));
}

// Main function
void main () {

    // Define the ray corresponding to this fragment
    vec3 ray = normalize (vec3 ((2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y, CAMERA_FOCAL_LENGTH));

    // Set the camera
    float cameraDist = 30.0 + 10.0 * cos (time * 0.2);
    float cameraAngle = PI * (0.25 + 0.15 * cos (time * 2.0));
    #ifdef SHADERTOY
    cameraAngle += 2.0 * PI * mouse.x / resolution.x;
    #endif
    vec3 origin = cameraDist * vec3 (cos (cameraAngle), 0.5 + 0.5 * cos (time * 0.5), sin (cameraAngle));
    vec3 cameraForward = -origin;
    vec3 cameraUp = vec3 (0.2 * cos (time * 0.7), 1.0, 0.0);
    mat3 cameraRotation;
    cameraRotation [2] = normalize (cameraForward);
    cameraRotation [0] = normalize (cross (cameraUp, cameraForward));
    cameraRotation [1] = cross (cameraRotation [2], cameraRotation [0]);
    ray = cameraRotation * ray;

    // Compute the distance to the voxelized scene
    vec2 d = dist (origin, ray);

    // Set the background color
    vec3 fragColor = rgb (vec3 (0.1 * cos (time * 0.2), 1.0, 1.0));
    if (d.x < DELTA) {

        // Set the object color
        float id = rand (floor (origin + 0.5));
        vec3 color = rgb (vec3 ((0.4 + 0.2 * id) / 3.0, 1.0, 1.0));

        // Compute the fade factor
        float fade = pow (1.0 - d.y / RAY_LENGTH_MAX, FADE_POWER);

        // Get the normal
        vec2 h = vec2 (DELTA, 0.0);
        vec3 normal = normalize (vec3 (
            distVoxel (origin + h.xyy) - distVoxel (origin - h.xyy),
            distVoxel (origin + h.yxy) - distVoxel (origin - h.yxy),
            distVoxel (origin + h.yyx) - distVoxel (origin - h.yyx)));

        // Check whether the light is visible
        vec3 lightDirection = normalize (vec3 (2.0 * cos (time * 0.2), 1.0, 1.0));
        #ifdef SHADOW
        origin += normal * 0.5;
        float light = step (DELTA, dist (origin, lightDirection).x);
        #else
        float light = 1.0;
        #endif

        // Lighting
        float diffuse = light * max (0.0, dot (normal, lightDirection));
        float specular = light * pow (max (0.0, dot (reflect (ray, normal), lightDirection)), SPECULAR_POWER) * SPECULAR_INTENSITY;
        fragColor = mix (fragColor, (AMBIENT + diffuse) * color + specular, fade);
    }

    // Set the fragment color
    fragColor = pow (fragColor, vec3 (GAMMA));
    glFragColor = vec4 (fragColor, 1.0);
}
