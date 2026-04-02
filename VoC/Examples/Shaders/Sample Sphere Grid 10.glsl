#version 420

// original https://www.shadertoy.com/view/tsByRh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Ray marching limits
const float epsilon = 0.01;
const float maxDistance = 30.0; // This is per bounce rather than total
const int maxIterations = 100;

// Supersample 2x2 by default - TODO change ssDimension to 1 to speed up rendering
const int ssDimension = 2;
const int samplesPerPixel = ssDimension * ssDimension;
const float sampleWeight = 1.0 / float(samplesPerPixel);
const float ssIncrement = 1.0 / float(ssDimension);
const float ssOffset = ssIncrement / 2.0;

// Camera/Light
vec3 cameraPos; 
vec3 lightPos; 
const vec3 lightIntensity = vec3(1200.0);

// Light constants
const float kAmbient = 0.15;
const float kDiffuse = 1.0;
const float kSpecular = 1.0;
const float specularExponent = 8.0;

// Bounce
const int maxBounces = 3; // TODO change the number of bounces calculated
const float bounceWeight = 0.55; // Percentage of color that the new bounce will occupy

// Sphere at (0, 0, 0), r = 0.85
const vec3 spherePos = vec3(0.0, 0.0, 0.0);
const float sphereRadius = 1.45;
const float sphereCycle = 4.0; // Dimensions of repeating box
const vec3 sphereOffset = vec3(sphereCycle/2.0, sphereCycle/2.0, sphereCycle/2.0); // Offset from center to corner of repeating box
const vec3 sphereColor = vec3(0.1, 0.6, 1.0);

const vec3 fogColor = vec3(0.7, 0.8, 1.0);

// (Repeating) sphere signed distance function
float sphereSDF(vec3 point)
{
    // Calculate point within repeating box
    point += sphereOffset;
    point = mod(point, sphereCycle);
    point -= sphereOffset;
    return length(spherePos - point) - sphereRadius;
}

// Minimum distance to scene - currently just using spheres
float minDistance(vec3 point) {
     return sphereSDF(point);   
}

// Approximates the normal at an intersection by calculating the gradient
vec3 estimateNormal(vec3 point) {
    return normalize(vec3(
        minDistance(vec3(point.x + epsilon, point.y, point.z)) - minDistance(vec3(point.x - epsilon, point.y, point.z)),
        minDistance(vec3(point.x, point.y + epsilon, point.z)) - minDistance(vec3(point.x, point.y - epsilon, point.z)),
        minDistance(vec3(point.x, point.y, point.z  + epsilon)) - minDistance(vec3(point.x, point.y, point.z - epsilon))
    ));
}

// Linear interpolate a vec3 based on (clamped) decimal
// Lower weight shifts to a, higher weight shifts to b
vec3 lerp(vec3 a, vec3 b, float weight) {
    weight = clamp(weight, 0.0, 1.0);
    return (1.0 - weight) * a + weight * b;
}

// Returns the direction of a ray bounce based on the incident ray and surface normal
// Ray direction and normal should already be normalized by other parts of the code so they are
// assumed to be normal
vec3 getBounceDirection(vec3 incidentRay, vec3 normal) {
    // This calculation should result in a unit vector, so no need to normalize
     return incidentRay - 2.0 * normal * dot(incidentRay, normal);
}

// Returns the shaded color based on the original surface color
// Only does ambient and diffuse shading
vec3 shadePoint(vec3 point, vec3 normal, vec3 color) {
    vec3 result = vec3(0.0, 0.0, 0.0);
    
    // Ambient
    result += color * kAmbient;
    
    vec3 toLight = lightPos - point;  
    vec3 falloff = lightIntensity / dot(toLight, toLight);
    toLight = normalize(toLight);
    
    vec3 toCamera = normalize(cameraPos - point);
    vec3 viewAngleBisector = normalize(toLight + toCamera);
    
    // Diffuse
    result += kDiffuse * color * falloff * max(0.0, dot(normal, toLight));
    result += kSpecular * falloff * pow(max(0.0, dot(normal, viewAngleBisector)), specularExponent);
    
    return result;
}

// Returns the color of casting a ray from rayOrigin in rayDirection
// Normalizes ray direction
vec3 castRay(vec3 rayOrigin, vec3 rayDirection)
{
    vec3 color = fogColor;
    
    vec3 testPoint = rayOrigin; // Point to test distance function at
    rayDirection = normalize(rayDirection);
    
    // Result colors and distances for each cast
    vec3[maxBounces + 1] results;
    float[maxBounces + 1] distances;
    
    // The index of current cast
    int castIndex;
    int lastCastIndex;
    
    for (castIndex = 0; castIndex <= maxBounces; castIndex++)
    {
        lastCastIndex = castIndex;
        bool hit = false; // Flag to test if this iteration hit
        
        // The result color of this cast
        vec3 resultColor = fogColor;
        
        float tCurrent = 0.0; // Scalar of rayDirection from testPoint (i.e. t for current iteration)
        float tTotal = 0.0; // Scalar of rayDirection from rayOrigin (i.e. total t)
        
        for (int i = 0; i < maxIterations && tTotal < maxDistance; i++)
        {
            tCurrent = minDistance(testPoint);
            if(tCurrent < epsilon) // HIT
            { 
                hit = true;
                
                vec3 hitNormal = estimateNormal(testPoint);

                resultColor = shadePoint(testPoint, hitNormal, sphereColor); // shade result
                
                // Calculate new ray direction
                rayDirection = getBounceDirection(rayDirection, hitNormal);

                // March ray slightly more than the epsilon away from the hit point
                testPoint = testPoint + rayDirection * epsilon * 1.1;            

                break;
            }
            testPoint += tCurrent * rayDirection; // March ray
            tTotal += tCurrent;
        }
        // Store color and distance results
        results[castIndex] = resultColor;
        distances[castIndex] = tTotal;

        // Stop recursing if we don't hit anything
        if(!hit) {
            break;
        }
    }
    
    // Go backwards to calculate bounce colors with fog fades
    for(int i = lastCastIndex; i >= 0; i--)
    {
        float fogWeight = distances[i] / maxDistance;
        
        // Blend hit color with fog if we are at last cast,
        // otherwise do bounce blend then fog blend
        if(i == lastCastIndex) {
             color = lerp(results[i], fogColor, fogWeight);
        }
        else {
            vec3 colorWithBounce = lerp(results[i], color, bounceWeight);
            color = lerp(colorWithBounce, fogColor, fogWeight);
        }
    }
    return color;
}

void main(void)
{
    // CAMERA AND LIGHTS
    float zOffset = 0.9*time; // Move camera and lights backward over time
    
    // Move camera and light backward
    cameraPos = vec3(sphereOffset.xy, zOffset);
    lightPos = vec3(22.0, 22.0, zOffset + 22.0);

    // Assume camera is always upright and pointed in -z direction
    
    // Field of view in shortest axis
    float fov = 60.0;
    float scale = tan(radians(fov/2.0));
    float limit = min(resolution.x, resolution.y); // Limiting dimension for FOV
    
    // Initialize sample coord and color for supersampling
    vec2 sampleCoord = gl_FragCoord.xy + ssOffset;
    vec3 color = vec3(0.0);
    
    for(int j = 0; j < ssDimension; j++) {
        for(int i = 0; i < ssDimension; i++)
        {
            // Normaize pixel coordinate such that y is in [-1, 1]
            vec2 rayXY = (2.0 * sampleCoord + vec2(1.0, 1.0) - resolution.xy) / limit;

            // Scale coordinate based on camera FOV, then create ray pointing at -Z
            vec3 rayDirection = vec3(rayXY *= scale, -1.0);
            
            color += sampleWeight * castRay(cameraPos, rayDirection);
            sampleCoord.x += ssIncrement;
        }
        // Reset x, increment y
        sampleCoord.x = gl_FragCoord.xy.x + ssOffset;
        sampleCoord.y += ssIncrement;
    }
    glFragColor = vec4(color, 1.0);
}
