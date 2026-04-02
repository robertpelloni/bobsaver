#version 420

// original https://www.shadertoy.com/view/Wld3zM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// This work is licensed under the
// Creative Commons Attribution-NonCommercial-ShareAlike 4.0
// International License.

// Created by RobRob for display on shadertoy.com.

// Number of spheres that spawn randomly.
#define SPHERE_AMOUNT 14.

// Determines how quickly the camera moves through space.
#define MOVEMENT_SPEED 4.

// Determines how long it takes before the spectrum repeats itself.
// Values between [0, 1] make it go faster, values larger than 1 make it go slower.
#define SPECTRUM_SPEED 4.

// Determines how often colours repeat. Larger values will show more coloured 'stripes'.
#define SPECTRUM_REPETITION 2.

// All lights will spawn between [-interval, interval] on the x and y-axes.
#define INTERVAL 40.

// Repetition period per axis. Set to 0 for no repetitions.
// This case means repetition on the y and z axes.
#define REPEAT vec3(0., 5., 5.)

#define MAX_STEPS 50
#define MAX_DIST 1000.
#define SURF_DIST .02
#define Z_PLANE 15.
#define FLOAT_MAX 3.402823466e+38
#define WORLD_UP vec3(0., 1., 0.)
#define WHITE vec3(1.)

// Credits to David Hoskins for the hash21() function.
// Can be found at https://www.shadertoy.com/view/3t23DD
// Licensed under
// Creative Commons Attribution-ShareAlike 4.0 International Public License
// Note that the function in this shader was modified slightly.

// Take a float as input and return two random floats in range [0, 1].
vec2 hash21(float p)
{
    vec3 p3 = fract(vec3(p) * vec3(.2602, .0905, .2019));
    p3 += dot(p3, p3.yzx + 19.98);
    return fract((p3.xx + p3.yz) * p3.zy);

}

// Return the distance to the closest sphere from point p.
float GetSphereDist(vec3 p) {
    
    // All spheres will have this radius.
    // Note that there appear to be more spheres along the
    // z-axis due to the repeated rendering that we do below.
    
    // Radius will be in range [0.09, 0.99]
    float radius = (sin(time / 6.) + 1.1) * .09;
    
    float minDist = FLOAT_MAX;
    
    // Calculate the distance to the closest sphere.
    // Note that the position of the spheres is randomly generated
    // based on 'i' in the loop below.
    for (float i = 0.; i < SPHERE_AMOUNT; i++) {
        // Every sphere's 'real' position will be at z = Z_PLANE.
        // However, due to the repeated rendering (see below)
        // there appear to be many more spheres.
        vec3 pos = vec3(hash21(i), Z_PLANE);
        
        // Convert values from [0, 1] to [-interval, interval].
        pos.xy = pos.xy * INTERVAL * 2. - INTERVAL;
            
        // Repeater set-up based on Bekre's UFO shader, retrieved from:
        // https://www.shadertoy.com/view/4dXGD4
        vec3 repeater = mod(p - pos, REPEAT) - 0.5 * REPEAT;
        float dist = length(repeater) - radius;
        
        if (dist < minDist) {
            minDist = dist;
        }    
    }
    
    return minDist;
}

// Return (distance, distance to closest object,
// x-coordinate of hit, y-coordinate of hit).
// Distance is -1 if there is no hit.
vec4 RayMarch(vec3 origin, vec3 direction) {
    
    float distance = 0.;
    float closest = FLOAT_MAX;
    vec2 closestPoint = vec2(0.);
    
    for(int i = 0; i < MAX_STEPS; i++) {
        
        vec3 p = origin + direction * distance;        
        float sphereDistance = GetSphereDist(p);
        
        distance += sphereDistance;
        
        // If the calculated distance to the closest sphere
        // is smaller than what it was, update it and
        // update the hit point as well.
        if (sphereDistance < closest ) {
            closest = sphereDistance;
            closestPoint = p.xy;
        }
        
        if (distance > MAX_DIST) {
            // No hit
            return vec4(-1, closest, closestPoint);
        }
        
        if (sphereDistance < SURF_DIST) {
            // Sphere hit
            return vec4(distance, 0, closestPoint);
        }
    }
    
    // No hit
    return vec4(-1, closest, closestPoint);
}

// Starting point of the application.
void main(void)
{
    // Basic camera and raymarching setup adapated from
    // "ShaderToy Tutorial - CameraSystem"
    // found at https://www.shadertoy.com/view/4dfBRf
    // by Martijn Steinrucken aka BigWings/CountFrolic - 2017
    // Licensed under
    // Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
    
    // The middle pixel will become (0, 0).
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;    
    
    // Set the camera position.
    vec3 cameraPos = vec3(0., 1., time * MOVEMENT_SPEED);
    
    // Set the point we look at.
    float t = time / 4.;
    vec3 look = cameraPos + vec3(cos(t), sin(t), 3.);
    
    // Calculate the camera parameters.
    vec3 forward = normalize(look - cameraPos);
    vec3 right = normalize(cross(WORLD_UP, forward));
    vec3 up = normalize(cross(forward, right));
    
    // Calculate the 3D coordinate of the current pixel.
    vec3 intersection = cameraPos + forward + uv.x * right + uv.y * up;
    
    // Calculate the ray from the camera through this pixel.
    vec3 cameraDir = normalize(intersection - cameraPos);

    // Perform ray marching.
    vec4 rayMarch = RayMarch(cameraPos, cameraDir);
    
    // The distance from the camera to the object
    // if the ray hits, or -1 for no hit.
    float distance = rayMarch.x;
    
    if (distance == -1.) {
        // No hit, calculate bloom.
        
        // The coordinates of the point closest to the ray.
        vec2 xy = rayMarch.zw;
        
        // Convert the coordinates from [-interval, interval]
        // to [0, 1].
        xy = (xy + INTERVAL) / (2. * INTERVAL);
        
        // Calculate the bloom color based on the point's coordinates and the time.
        
        // Calculation based on defcon8's RGB Rainbow shader found at
        // https://www.shadertoy.com/view/MsByzV
        vec3 col =
            sin(
                SPECTRUM_REPETITION * (xy.x + xy.y + time / SPECTRUM_SPEED)
                + vec3(0, 2, 4)
            )
            * .5 + .5;
        
        // The distance from the ray to the closest point.
        float closest = rayMarch.y;
        
        // Bloom calculation adapted from takumifukasawa's
        // emissive cube shader found at
        // https://www.shadertoy.com/view/wd2SWD
        vec3 bloom = col * pow(closest + 1., -2.);
        
        glFragColor = vec4(bloom, 1.);        
    } else {
        // Hit a sphere, render white.
        glFragColor = vec4(WHITE, 1.);
    }
}
