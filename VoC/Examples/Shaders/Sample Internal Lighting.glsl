#version 420

// original https://www.shadertoy.com/view/4l33R4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
ALL OF THIS IS BORROWED :)
*/

#define MAXIMUM_STEPS 256
#define MAX_SECONDARY_RAY_STEPS 24
#define DISTANCE_THRESHOLD 0.0001
#define GRADIENT_STEP 0.0001
#define FAR_CLIP 25.0

const vec4 BACKGROUND_COLOUR = vec4(0.0, 0.0, 0.0, 1.0);
const vec4 AMBIENT_COLOUR = vec4(0.15, 0.2, 0.32, 1.0);
const vec3 LIGHT1_POSITION = vec3(-3.0, 3.0, -3.0);
const vec4 LIGHT1_COLOUR = vec4(1.0, 1.0, 1.0, 1.0);
const vec3 LIGHT2_POSITION = vec3(-3.0, 3.0, 3.0);
const vec3 LOXODROME_LIGHT_POSITION = vec3(0.0, 0.0, 0.0);
const float SLEW = 1.2;
const vec2 VE = vec2(0.02, 0.0);
const float PI = 3.14159265359;
const float INF = 123456789.0;

void rX(inout vec3 p, float a) {
    float c;
    float s;
    vec3 q = p;
    c = cos(a);
    s = sin(a);
    p.y = c * q.y - s * q.z;
    p.z = s * q.y + c * q.z;
}

void rY(inout vec3 p, float a) {
    float c;
    float s;
    vec3 q = p;
    c = cos(a);
    s = sin(a);
    p.x = c * q.x + s * q.z;
    p.z = -s * q.x + c * q.z;
}

void rZ(inout vec3 p, float a) {
    float c;
    float s;
    vec3 q = p;
    c = cos(a);
    s = sin(a);
    p.x = c * q.x - s * q.y;
    p.y = s * q.x + c * q.y;
}

float distanceToBox(vec3 position, vec3 box) {
    //signed
    vec3 d = abs(position) - box;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float distanceToCross(vec3 position) {
    float da = distanceToBox(position.xyz, vec3(INF, 1.0, 1.0));
    float db = distanceToBox(position.yzx, vec3(1.0, INF, 1.0));
    float dc = distanceToBox(position.zxy, vec3(1.0, 1.0, INF));
    return min(da, min(db, dc));
}

float distanceToBoxFrameInterior(vec3 position, float boxWidth) {
    float da = distanceToBox(position.xyz, vec3(boxWidth * 1.1, boxWidth * 0.8, boxWidth * 0.8));
    float db = distanceToBox(position.yzx, vec3(boxWidth * 0.8, boxWidth * 1.1, boxWidth * 0.8));
    float dc = distanceToBox(position.zxy, vec3(boxWidth * 0.8, boxWidth * 0.8, boxWidth * 1.1));
    return min(da, min(db, dc));
}

float distanceToBoxFrame(vec3 position, float boxWidth) {
    return max(-distanceToBoxFrameInterior(position, boxWidth), distanceToBox(position, vec3(boxWidth, boxWidth, boxWidth)));
}

float distanceToRotatingCubeFrames(vec3 position) {
    
    float msd = -1.0;

    vec3 rotation1 = position;
    rX(rotation1, time);
    rY(rotation1, time);

    vec3 rotation2 = position;
    rX(rotation2, time);
    rZ(rotation2, time);

    vec3 rotation3 = position;
    rY(rotation3, time);
    rZ(rotation3, time);

    msd =  distanceToBoxFrame(rotation1, 1.0);
    
    msd = min(msd, distanceToBoxFrame(rotation2, 0.7));

    msd = min(msd, distanceToBoxFrame(rotation3, 0.4));
    
    return msd;
}

//march a single ray
void marchRay(vec3 position, vec3 direction, out float depth, out int iteration) {

    depth = 0.0;
    iteration = 0;
    
    for (int i = 0; i < MAXIMUM_STEPS; ++i) {
        
        vec3 newRayPosition = position + direction * depth;
        float nearestSurface = distanceToRotatingCubeFrames(newRayPosition);
        depth += nearestSurface;
        
        if (nearestSurface < DISTANCE_THRESHOLD) {
            //hit surface
            iteration = i;
            break;
        }
        
        if (depth > FAR_CLIP) {
            //miss as we've gone past rear clip
            depth = -1.0;
            break;
        }

        iteration++;
    }
}

vec3 calculateSurfaceNormal(vec3 pos) {
    
    vec3 dx;
    vec3 dy;
    vec3 dz;
    
    dx = vec3(GRADIENT_STEP, 0.0, 0.0);
    dy = vec3(0.0, GRADIENT_STEP, 0.0);
    dz = vec3(0.0, 0.0, GRADIENT_STEP);
    
    return normalize(vec3(distanceToRotatingCubeFrames(pos + dx) - distanceToRotatingCubeFrames(pos - dx),
                          distanceToRotatingCubeFrames(pos + dy) - distanceToRotatingCubeFrames(pos - dy),
                          distanceToRotatingCubeFrames(pos + dz) - distanceToRotatingCubeFrames(pos - dz)));
}

float inverseMix(float a, float b, float x) {
    return (x - a) / (b - a);
}

float shadowDistanceField(vec3 position) {
    return distanceToRotatingCubeFrames(position);
}

float castSoftShadowRay(vec3 pos, vec3 lightPos, float k) {
    
    float res = 1.0;
    vec3 rayDir = normalize(lightPos - pos);
    float maxDist = length(lightPos - pos);
    
    vec3 rayPos = pos + 0.01 * rayDir;
    float distAccum = 0.1;
    
    for (int i = 1; i <= MAX_SECONDARY_RAY_STEPS; i++) {
        rayPos = pos + rayDir * distAccum;
        float dist = shadowDistanceField(rayPos);
        float penumbraDist = distAccum * k;
        res = min(res, inverseMix(-penumbraDist, penumbraDist, dist));
        distAccum += (dist + penumbraDist) * 0.5;
        distAccum = min(distAccum, maxDist);
    }
    res = max(res, 0.0);
    res = res * 2.0 - 1.0;
    return (0.5 * (sqrt(1.0 - res * res) * res + asin(res)) + (PI / 4.0)) / (PI / 2.0);
}

// Calculate the light intensity with soft shadows and return the color of the point
vec4 getShading(vec3 position, vec3 normal, vec3 lightPosition, vec4 lightColor, int internalLight) {
    
    float lightIntensity = 0.0;
    float shadow = 0.0;
    
    //shadow = getShadow(position, lightPosition, 16.0);
    shadow = castSoftShadowRay(position, lightPosition, 0.01);

    
    //are we visible
    if (shadow > 0.0) {
        vec3 lightDirection = normalize(lightPosition - position);
        lightIntensity = shadow * clamp(dot(normal, lightDirection), 0.0, 1.0);
    }
    
    return lightColor * lightIntensity + AMBIENT_COLOUR * (1.0 - lightIntensity);
}

vec4 calculatePixelColour(vec3 position, vec3 direction, float sceneDistance, int iterations) {
    
    vec4 pixelColour = vec4(0.0, 0.0, 0.0, 1.0);
    vec3 hitPoint;
    vec3 hitNormal;
    float hitDistance;
    
    if (iterations < MAXIMUM_STEPS && sceneDistance >= 0.0 && sceneDistance <= FAR_CLIP) {
        //hit scene object
        hitDistance = sceneDistance;
        hitPoint = position + direction * sceneDistance;
        hitNormal = calculateSurfaceNormal(hitPoint);
     
    } else {
        //missed floor and scene
        return BACKGROUND_COLOUR;
    }
    
    vec4 dynamicLightColour = vec4(1.0, 0.25, 0.35, 1.0); 
    vec3 dynamicLightPosition = LIGHT2_POSITION;
    rX(dynamicLightPosition, time * SLEW);
    rY(dynamicLightPosition, time * SLEW);
    dynamicLightPosition.z += sin(time * SLEW);

    pixelColour = (getShading(hitPoint, hitNormal, LOXODROME_LIGHT_POSITION, LIGHT1_COLOUR, 1) +
                   getShading(hitPoint, hitNormal, dynamicLightPosition, dynamicLightColour, 0)) / 2.0;

    //edge detection
    float d = distanceToRotatingCubeFrames(hitPoint);
    float d1 = distanceToRotatingCubeFrames(hitPoint - VE.xyy);
    float d2 = distanceToRotatingCubeFrames(hitPoint + VE.xyy);
    float d3 = distanceToRotatingCubeFrames(hitPoint - VE.yxy);
    float d4 = distanceToRotatingCubeFrames(hitPoint + VE.yxy);
    float d5 = distanceToRotatingCubeFrames(hitPoint - VE.yyx);
    float d6 = distanceToRotatingCubeFrames(hitPoint + VE.yyx);
    //the farther the initial estimate is from the average of the deltas the more of an edge it is
    d = abs(d - 0.5 * (d2 + d1)) + abs(d - 0.5 * (d4 + d3)) + abs(d - 0.5 * (d6 + d5));//edge finder
    vec4 edgeColour = vec4(0.0, 0.0, d * sin(time) * 200., 1.0);
            
    pixelColour = pixelColour + edgeColour;
        
    return pixelColour;
}

void main(void) {
    
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    
    //camera
    vec3 direction = normalize(vec3(uv, 2.));
    vec3 position = vec3(0, 0, -3.5);
    
    //rotate camera
    rY(position, 1. - sin(time));
    rY(direction, 1. -sin(time));
    rY(position, cos(time));
    rY(direction, cos(time));
    rZ(position, sin(time));
    rZ(direction, sin(time));

    //ray marching
    float depth;
    int iterations;
    
    marchRay(position, direction, depth, iterations);
    
    //glFragColor = vec4(uv,0.5+0.5*sin(time),1.0);
    glFragColor = calculatePixelColour(position, direction, depth, iterations);
}
