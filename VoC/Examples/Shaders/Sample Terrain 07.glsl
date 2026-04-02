#version 420

// original https://www.shadertoy.com/view/WsS3zG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//terrain generation
#define NOISE_LAYERS 5
#define NOISE_Q 0.32
#define NOISE_MUL 2.6
#define NORMAL_NOISE_LAYERS 6
#define MAX_HEIGHT 8.0

//rendering settings
#define RAYS_COUNT 180
#define SHADOW_RAYS_COUNT 90
#define MAX_VIEW_DISTANCE 30.0
#define MAX_SHADOW_DISTANCE 30.0
#define SHADOW_BLUR_ANGLE 0.99
#define FAKE_SUN_LIFT -0.1

//lighting
#define LIGHT_HEIGHT 0.55
#define SUN_SIZE 4.0
#define LIGHT_COLOR vec3(1.0, 1.0, 1.0)

//camera
#define CAMERA_MOVEMENT_SPEED 0.0014
#define CAMERA_ROTATION_SPEED 0.1
#define A_LA_FOV 0.8
#define ZOOM_KEY_COORD vec2(90.0 / 256.0, 0.0)
#define ULTRA_ZOOM_KEY_COORD vec2(85.0 / 256.0, 0.0)

//Constant variables
#define EPSILON 0.001
#define TWO_PI 6.28
#define PI 3.14
#define INV_SQRT2 0.7072

//Colors
#define SKY_COLOR vec3(0.5, 0.8, 1.0)
#define SUNSET_COLOR vec3(0.9, 0.3, 0.2)

#define GROUND_COLOR vec3(0.7, 0.5, 0.3)
#define MOUNTAIN_COLOR vec3(0.4, 0.35, 0.3)
#define GRASS_COLOR vec3(0.2, 0.28, 0.16)

//Time
#define TIME_OFFSET 39.0
#define TIME_SCALE 1.0

//Useful functions
#define POW4(x) x*x*x*x
#define POW2(x) x*x

float hash(vec2 v)
{
     return fract(sin(dot(v, vec2(51.2838, 8.4117))) * 2281.2231); 
}

float getNoise(vec2 v)
{
     vec2 rootV = floor(v);
    vec2 f = smoothstep(0.0, 1.0, fract(v));

    vec4 n;
    n.x = hash(rootV);
    n.y = hash(rootV + vec2(0.0, 1.0));
    n.z = hash(rootV + vec2(1.0, 0.0));
    n.w = hash(rootV + vec2(1.0, 1.0));
    
    n.xy = mix(n.xz, n.yw, f.y);
    return mix(n.x, n.y, f.x);
}

//Mountain height
float getTerrainNoise(vec2 v, int layers)
{
    float bigNoise = (getNoise(v * 0.16));
    
    float smallNoise = smoothstep(0.7, 1.0, getNoise(v * 30.0));
    smallNoise *= POW4(smallNoise) * 0.003 * bigNoise;
    
     float noise = 0.0;
    float noiseStrength = 1.0;
    
    for(int i = 0; i < layers; i++)
    {
         noise += pow(getNoise(v), 2.5 - noiseStrength) * noiseStrength * sqrt(bigNoise);
        v *= NOISE_MUL;
        noiseStrength *= NOISE_Q;
    }
    
    noise *= (1.0 - NOISE_Q)/(1.0 - pow(NOISE_Q, float(NOISE_LAYERS)));

    bigNoise *= bigNoise;
    bigNoise *= (MAX_HEIGHT - 1.0);
    return (noise + bigNoise + smallNoise);
}

vec3 getNormal(vec2 p, int noiseLayers)
{    
     float v00 = getTerrainNoise(p, noiseLayers);
    float v10 = getTerrainNoise(p + vec2(EPSILON, 0.0), noiseLayers);
    float v01 = getTerrainNoise(p + vec2(0.0, EPSILON), noiseLayers);
    
    return normalize(cross(vec3(EPSILON, 0, v10 - v00), vec3(0, EPSILON, v01 - v00)));
}

//just for clear code
float terrainDist(vec3 p, vec2 rayDir)
{
    return p.z - getTerrainNoise(p.xy, NOISE_LAYERS);
}

//xyz - hit point, w distance
vec4 rayMarch(vec3 startPoint, vec3 direction, int iterations, float maxStepDist)
{
     vec3 point = startPoint;
    direction = normalize(direction);
    float distSum = 0.0;
    float shadowData = 1.0;
    float dist = 10.0;
    
    int i;
    for (i = 0; i < iterations && distSum < MAX_VIEW_DISTANCE && abs(dist) > EPSILON; i++)
    {
         dist = terrainDist(point, direction.xy);
        dist = min(dist, maxStepDist) * 0.4;
        distSum += dist;
        point += direction * dist;
    }
    
    return vec4(point.xyz, distSum);
}

//x - hard shadows, y - smooth shadows
vec2 shadowMarch(vec3 startPoint, vec3 direction, int iterations, float maxStepDist)
{
    vec3 point = startPoint;
    direction = normalize(direction);
    float dist = 10.0;
    float distSum = 0.0;
    float shadowData = 0.0;
    float shadow = 0.0;
    
    int i;
    for (i = 0; i < SHADOW_RAYS_COUNT && distSum < MAX_SHADOW_DISTANCE && abs(dist) > EPSILON * 0.5; i++)
    {
         dist = terrainDist(point, direction.xy);
        
        shadow = dot(normalize((point - vec3(0.0, 0.0, dist)) - startPoint), direction);
        if(shadow > shadowData) shadowData = shadow;
        
        dist = min(dist, 1.0);
        distSum += dist;
        point += direction * dist;     
    }
    
    return vec2(smoothstep(MAX_SHADOW_DISTANCE - EPSILON, MAX_SHADOW_DISTANCE, distSum), shadowData);
}

//Poor but works
float getClouds(vec2 v)
{
    v += vec2(time * TIME_SCALE * 5.0);
    return getNoise(v.xy * vec2(0.1, 0.2)) * pow(getNoise(v.xy * vec2(0.3, 0.24)), 2.0) * getNoise(v.xy * 0.05);
}

float getZoom()
{
     return 0.0;//texture(iChannel0, ZOOM_KEY_COORD).r * 2.0 + texture(iChannel0, ULTRA_ZOOM_KEY_COORD).r * 10.0;
}

//converts uv point (from (-1,-1) to (1,1)) to view space
vec3 renderPlanePoint(vec2 uv, float zoom) 
{ 
    return vec3(uv.x, A_LA_FOV + zoom, uv.y);
}

//Blending lens flares with screen
vec3 mixLens(vec3 screen, vec3 lens)
{
    float brightness = min(max(lens.r, max(lens.g, lens.b)), 1.0);
     return screen * (1.0 - brightness) + lens * 2.4;   
}

//Rotation matrices
mat4x4 getYawMatrix(float yaw)
{
     float c = cos(yaw);
    float s = sin(yaw);
    return mat4x4(c, s, 0.0, 0.0,
                  -s, c, 0.0, 0.0, 
                  0.0, 0.0, 1.0, 0.0,
                  0.0, 0.0, 0.0, 1.0); 
}

mat4x4 getPitchMatrix(float pitch)
{
    float c = cos(pitch);
    float s = sin(pitch);
    return mat4x4(1.0, 0.0, 0.0, 0.0,
                  0.0, c, s, 0.0, 
                  0.0, -s, c, 0.0,
                  0.0, 0.0, 0.0, 1.0);
}

mat4x4 getOffsetMatrix(vec3 offset)
{
    return mat4x4(1.0, 0.0, 0.0, 0.0,
                  0.0, 1.0, 0.0, 0.0,
                  0.0, 0.0, 1.0, 0.0,
                  offset.x, offset.y, offset.z, 1.0);
}

//ACTION!
void main(void)
{
    vec2 mouse;
    if(length(mouse*resolution.xy.xy) >= 1.0) mouse = (2.0 * mouse*resolution.xy.xy - resolution.xy) / resolution.xy;
    else mouse = vec2(0.0);
    
    float time = (time * TIME_SCALE) + TIME_OFFSET;
    
    vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.x;
    float zoom = getZoom();
    vec3 camPos;
    camPos.x = cos(-time * CAMERA_MOVEMENT_SPEED) * 300.0;
    camPos.y = sin(-time * CAMERA_MOVEMENT_SPEED) * 300.0;
    camPos.z = getTerrainNoise(camPos.xy, 1) + 1.2 + sin(time * 0.22) * 0.7;

    //Rotation around Z (world up) axis
    float zAngle = -time * CAMERA_ROTATION_SPEED + -mouse.x * PI * 3.0;
    float xAngle = sin(time * 0.17) * 0.1 - camPos.z / MAX_HEIGHT * 0.3 + mouse.y * PI * 0.5;

    //Final matrices
    mat4x4 viewToWorld = getOffsetMatrix(camPos) * getYawMatrix(zAngle) * getPitchMatrix(xAngle);
    mat4x4 worldToView = getPitchMatrix(-xAngle) * getYawMatrix(-zAngle) * getOffsetMatrix(-camPos);
    
    //Rays
    vec3 rayDir = normalize(mat3x3(viewToWorld) * renderPlanePoint(uv, zoom));
    vec3 centerRayDir = normalize(mat3x3(viewToWorld) * renderPlanePoint(vec2(0.0), zoom));
    
    //Raymarching
    vec4 rayMarched = rayMarch(camPos, rayDir, RAYS_COUNT, 1.5);
    vec3 hitPoint = rayMarched.xyz;
    float height = rayMarched.z / MAX_HEIGHT; //terrain height from 0 to 1
    
    //Initialize light variables
    float fog = smoothstep(0.0, MAX_VIEW_DISTANCE, rayMarched.w);
    fog = POW2(fog);
    vec3 lightDir = normalize(vec3(-sin(-time * 0.1), -cos(-time * 0.1), cos(time * 0.09 + 0.5) * 0.4 + LIGHT_HEIGHT));
    vec3 sunDir = normalize(lightDir + vec3(0, 0, FAKE_SUN_LIFT));
    float sunset = 1.0 - smoothstep(-1.4, 0.5, dot(rayDir, lightDir) + abs(rayDir.z) * 2.0);
    
    //Initialize colors
       vec3 col = vec3(0.0);    //main color that will be placed on screen   
    vec3 skyColor = mix(SKY_COLOR, SUNSET_COLOR * 0.3, (1.0 - lightDir.z));
    skyColor = mix(skyColor, SUNSET_COLOR, min(sunset * (1.0 - lightDir.z), 1.0));
    vec3 lightColor = mix(LIGHT_COLOR, SUNSET_COLOR, clamp((1.0 - lightDir.z), 0.0, 1.0));

    if (rayMarched.w < MAX_VIEW_DISTANCE)
    {
        //Terrain
        vec3 normal = getNormal(hitPoint.xy, NORMAL_NOISE_LAYERS);
        
        //Terrain color
        vec3 groundCol = GROUND_COLOR * (0.8 + getNoise(hitPoint.xy * 1000.0) * 0.2) * 0.8;
        vec3 mountainCol = MOUNTAIN_COLOR * (0.4 + getTerrainNoise(hitPoint.xy * 20.0, 3) / MAX_HEIGHT * 0.6);
        vec3 ground = mix(groundCol, mountainCol, smoothstep(0.0, 0.4, height)); 
        col = ground;
        
        float snowTresh = getNoise(hitPoint.xy * 0.31) * 0.15 + 0.1;
        vec3 snowCol = mix(GRASS_COLOR, vec3(1.5), smoothstep(snowTresh, snowTresh + 0.07, height));
        float snow = smoothstep(0.6 - height * 0.5, 1.0, getNormal(hitPoint.xy, 3).z * getNormal(hitPoint.xy, 7).z);
        col = mix(col, snowCol, sqrt(snow));
        
        
        //Lighting
        float light = max(dot(normal, lightDir), 0.0);
        vec3 halfWay = normalize((-rayDir + lightDir) * 0.5);
        float specLight = pow(max(dot(halfWay, normal), 0.0), 2.0);
        
        float energyConservation = (snow * height + 1.0) * 0.5;
        
        float cloudShadow = smoothstep(0.7, 1.7, 1.0 - getClouds(hitPoint.xy + lightDir.xy * 10.0)) + 0.7;
        vec2 shadowData = shadowMarch(hitPoint + normal * EPSILON * 4.0, lightDir, SHADOW_RAYS_COUNT, 1.0);
        float shadow = smoothstep(0.0, 1.0, 1.0 - smoothstep(SHADOW_BLUR_ANGLE, 1.0, shadowData.y)) * shadowData.x;

        col = col * (light * (1.0 - energyConservation) + specLight * energyConservation) * shadow * cloudShadow * 0.8 * lightColor 
            + col * skyColor * 0.2 + light * 0.02 * lightColor;
        col = mix(col, skyColor, fog);
    }
    else
    {
        //Sky
        col = mix(col, skyColor, fog);
        float sun = max(dot(rayDir, sunDir), 0.0);
        sun = smoothstep(0.9985, 0.9999, sun) + smoothstep(0.95, 1.1, sun) * 0.2;
        
        vec2 skyPoint = camPos.xy + (rayDir.xy / -rayDir.z) * -10.0;
        float cloud = getClouds(skyPoint.xy);
        cloud = mix(cloud, 0.0, smoothstep(0.2, -0.0, rayDir.z));
        col = mix(col, vec3(skyColor + 1.0) * 0.5, cloud);
        
        col = mix(col, max(lightColor, vec3(0.0)), sun);
    }
    
    //Lens flares
    vec2 shadowData = shadowMarch(camPos, lightDir, RAYS_COUNT, 1.0);
    float lensFlare = clamp(1.0 - smoothstep(SHADOW_BLUR_ANGLE, 1.0, shadowData.y), 0.0, 1.0) * shadowData.x;
    if(lensFlare > 0.01)
    {   

        //Calculating sun position on the screen
        vec3 viewSunDir = (worldToView * vec4(sunDir, 0.0)).xyz;
        vec2 sunUV = (viewSunDir.xz / viewSunDir.y) * (A_LA_FOV + zoom);

        float centerLight = dot(lightDir, centerRayDir);
        float lensStrength = smoothstep(0.5, 1.0, centerLight) * 0.15 * lensFlare;
        
        vec3 lensCol = vec3(0.0);
        
        lensCol += skyColor * 0.5;
        
        //Around the sun
        lensCol += (1.0 - smoothstep(0.0, 0.18, distance(uv, sunUV))) * vec3(1.0, 0.12, 0.12) * 4.0;
        lensCol += (1.0 - smoothstep(0.0, 0.013, abs(distance(uv, sunUV) - 0.16))) * vec3(1.0, 0.12, 0.12) * 1.5;
        
        
        lensCol += (1.0 - smoothstep(0.035, 0.043, distance(uv, sunUV * 0.3))) * vec3(1.0, 0.4, 0.12) * 1.0; //Yellow disc
        lensCol += (1.0 - smoothstep(0.0, 0.008, distance(uv, sunUV * 0.13))) * vec3(0.4, 1.0, 0.6) * 3.0; //Small green dot
        lensCol += (1.0 - smoothstep(0.0, 0.015, distance(uv, sunUV * -0.13))) * vec3(0.4, 1.0, 0.6) * 3.0; //Bigger small green dot
        lensCol += (1.0 - smoothstep(0.07, 0.09, distance(uv, sunUV * -0.3))) * vec3(1.0, 0.5, 0.12) * 0.5; //Big yellow disc
        lensCol += (1.0 - smoothstep(0.00, 0.05, abs(distance(uv, sunUV * -0.3) - 0.11))) * vec3(1.0, 0.5, 0.12) * 0.5; //Big yellow disc
        lensCol += (1.0 - smoothstep(0.00, 0.05, distance(uv, sunUV * -0.5))) * vec3(0.1, 0.1, 1.0) * 0.7; //Blue dot
        lensCol += (1.0 - smoothstep(0.05, 0.09, distance(uv, sunUV * -0.5))) * vec3(0.1, 0.9, 0.8) * 0.4; //Green disc
        lensCol += (1.0 - smoothstep(0.01, 0.05, abs(distance(uv, sunUV * -0.75) - 0.15))) * vec3(0.4, 0.9, 0.1) * 0.2; //Green circle
        
        
        col = mixLens(col, lensCol * lensStrength * skyColor);
    }
    
    col = pow(col, vec3(0.45));
    
    //postprocess
    float avgCol = max(col.r, max(col.g, col.b));
    col = smoothstep(0.05, 0.95, col);
    col = mix(col, vec3(avgCol), 0.3);

    glFragColor = vec4(col, 1.0);
}
