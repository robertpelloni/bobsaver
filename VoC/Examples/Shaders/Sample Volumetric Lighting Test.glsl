#version 420

// original https://www.shadertoy.com/view/3ddGzM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 normalToColor(vec3 normal) {
     return vec3(
        (normal.x + 1.0) / 2.0,
        (normal.y + 1.0) / 2.0,
        (normal.z + 1.0) / 2.0
    );
}

// The very lovely Iq's signed distance field functions.
float getSphereDistance(vec3 point, vec3 position, float radius) {
    return distance(point, position) - radius;
}

float getBoxDistance(vec3 point, vec3 position, vec3 b)
{
  vec3 d = abs(point - position) - b;
  return length(max(d,0.0))
         + min(max(d.x,max(d.y,d.z)),0.0);
}

float getCylinderDistance(vec3 point, vec3 position, float h, float r) {
  vec3 p = vec3(point.y, point.x, point.z) - vec3(position.y, position.x, position.z);
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float opUnion(float a, float b) { return min(a, b); }
float opSubtract(float a, float b) { return max(a, -b); }
                        
float getSceneDistance(vec3 point) {
    const vec3 corridorPosition = vec3(0.0, 0.0, 0.0);
    const vec3 corridorExtents = vec3(4.0, 3.0, 10.0);
    
    const vec3 interiorPosition = corridorPosition;
    const vec3 interiorExtents = corridorExtents - vec3(1.0, 1.0, 2.0);

    const vec3 cut0Position = corridorPosition + vec3(-1.0, 3.0, 5.0);
    const vec3 cut0Extents = vec3(interiorExtents.x / 1.25, 2.0, 1.2);
    
    const vec3 cut1Position = corridorPosition + vec3(1.0, 3.0, 3.0);
    const vec3 cut1Extents = vec3(interiorExtents.x / 1.25, 2.0, 1.0);
    
    const vec3 cut2Position = corridorPosition + vec3(4.0, 0.0, 3.0);
    const vec3 cut2Extents = vec3(2.0, 0.5, 1.0);
    
    const vec3 pipe0Position = corridorPosition + vec3(0.0, 0.75, 6.0);    
    const vec3 pipe1Position = corridorPosition + vec3(0.0, 0.75, 5.0);

    const vec3 cut3Position = corridorPosition + vec3(0.0, -1.7, 1.1);
    const vec3 cut3Extents = vec3(2.0, 0.6, 3.0); 
    
    float corridorDist = getBoxDistance(point, corridorPosition, corridorExtents);
    float interiorDist = getBoxDistance(point, interiorPosition, interiorExtents);
    float cut0Dist = getBoxDistance(point, cut0Position, cut0Extents);
    float cut1Dist = getBoxDistance(point, cut1Position, cut1Extents);
    float cut2Dist = getBoxDistance(point, cut2Position, cut2Extents);
    float pipe0Dist = getCylinderDistance(point, pipe0Position, 0.25, 3.0);
    float pipe1Dist = getCylinderDistance(point, pipe1Position, 0.25, 3.0);
    float ballDist = getSphereDistance(point, corridorPosition + vec3(0.0, sin(time), 4.5), 1.4);
    float cut3Dist = getBoxDistance(point, cut3Position, cut3Extents);

    float stage0 = opSubtract(corridorDist, interiorDist);
    float stage1 = opSubtract(stage0, cut0Dist);
    float stage2 = opSubtract(stage1, cut1Dist);
    float stage3 = opSubtract(stage2, cut2Dist);
    float stage4 = opUnion(stage3, pipe0Dist);
    float stage5 = opUnion(stage4, pipe1Dist);
    float stage6 = opUnion(stage5, ballDist);
    float stage7 = opSubtract(stage6, cut3Dist);
    return stage7;
}

vec3 getSceneNormal(vec3 point) {
     float epsilon = 0.01;
    vec3 xOff = vec3(epsilon, 0.0, 0.0);
    vec3 yOff = vec3(0.0, epsilon, 0.0);
    vec3 zOff = vec3(0.0, 0.0, epsilon);
    
    return normalize(vec3(
        getSceneDistance(point + xOff) - getSceneDistance(point - xOff),
        getSceneDistance(point + yOff) - getSceneDistance(point - yOff),
        getSceneDistance(point + zOff) - getSceneDistance(point - zOff)   
    ));
}

struct HitResult {
    bool hit;
    vec3 point;
    vec3 normal;
    float penumbra;
    float time;
};

HitResult getSceneHit(vec3 origin, vec3 direction) {
    // March to scene surface
    const float MAX_STEPS = 128.0;
    float time = 0.0;
    float penumbra = 1.0;
    vec3 testPoint;
    bool hit = false;
    for (float stepIndex = 0.0; stepIndex < MAX_STEPS; stepIndex += 1.0) {
        testPoint = origin + direction * time;
        float dist = getSceneDistance(testPoint);
        penumbra = min(penumbra, 2.0 * dist / time);
        time += dist + 0.0051;
        
        if (dist < 0.0001) {
            hit = true;
            penumbra = 0.0;
            break;
        }
    }
    
    if (!hit) {
        return HitResult(false, vec3(0.0), vec3(0.0), penumbra, 0.0);
    }
    
    return HitResult(true, testPoint, getSceneNormal(testPoint), penumbra, time);
}

float getSceneOcclusion(vec3 position, vec3 normal) {
    float occlusion = 0.0;
    float sca = 1.0;
    for (int index = 0; index < 5; index += 1) {
        float offset = 0.04 + 0.12 * float(index) / 4.0;
        vec3 aoPosition = normal * offset + position;
        float dist = getSceneDistance(aoPosition);
        occlusion += -(dist - offset) * sca;
        sca *= 0.65;
    }

    return clamp(1.0 - 3.0 * occlusion, 0.0, 1.0);
}

vec3 getLightEnergy(vec3 origin, vec3 direction) {
     HitResult result = getSceneHit(origin, direction);
    return vec3(result.penumbra) + 0.003;
}

vec3 getFogEnergy(vec3 origin, vec3 direction) {
    const float MAX_STEPS = 128.0;
    const float MAX_DISTANCE = 10.0;
    const float DELTA_TIME = MAX_DISTANCE / MAX_STEPS;
    
    float energy = 0.00;
    
    float time;
    vec3 testPoint;
    bool hit = false;
    for (time = 0.0; time < MAX_DISTANCE; time += DELTA_TIME) {
        testPoint = origin + direction * time;
        float dist = getSceneDistance(testPoint);
        
        float tx = cos(time);
        float tz = sin(time);
        HitResult lightResult = getSceneHit(testPoint, normalize(vec3(tx, 1.0, tz)));
        energy += lightResult.hit ? 0.0 : lightResult.penumbra * 0.01;
        
        if (dist < 0.001) {
            hit = true;
            break;
        }
    }
    
    return vec3(energy);
}

vec3 getPrimaryRayColor(vec3 origin, vec3 direction) {
    HitResult result = getSceneHit(origin, direction);
    
    if (result.hit) {
        float tx = cos(time);
        float tz = sin(time);
        vec3 lightDirection = normalize(vec3(tx, 1.0, tz));
         // Calculate lighting.
        vec3 fogEnergy = getFogEnergy(origin, direction);
        vec3 lightEnergy = getLightEnergy(result.point + result.normal * 0.1, lightDirection);
        float ao = getSceneOcclusion(result.point, result.normal);
        
        vec3 temp = normalToColor(-result.normal);
        vec3 diffuse = vec3((temp.x * 0.5 + temp.y * 2.0 + temp.z) / 3.0);
        return diffuse * ao * lightEnergy + fogEnergy;
    }
    
    return vec3(1.0);
}

vec3 getSceneColor(vec2 uv) {
    vec3 origin = vec3(0.0);
    vec3 direction = normalize(vec3(uv.x, uv.y, 0.35));
    return getPrimaryRayColor(origin, direction);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - (resolution.xy * 0.5)) / resolution.y;
    vec3 color = getSceneColor(uv);

    // Gamma correct.
    vec3 adjusted = pow(color, vec3(1.0 / 2.2));
    glFragColor = vec4(adjusted, 1.0);
}
