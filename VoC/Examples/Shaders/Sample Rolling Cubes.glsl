#version 420

// Hauva Kukka 2014.

#extension GL_OES_standard_derivatives : enable

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define DISTANCE_EPSILON 0.01
#define NORMAL_DELTA 0.0001
#define OCCLUSION_DELTA 0.1
#define SCENE_RADIUS 500.0
#define STEP_SCALE 1.0

#define MAX_HIT_COUNT 5
#define ITERATION_COUNT 100

#define TYPE_NONE        0
#define TYPE_OPAQUE      1
#define TYPE_TRANSPARENT 2

#define MODE_OUTSIDE 0
#define MODE_INSIDE  1

#define N1 1.0
#define N2 2.0
 
#define R0(x, y) (((x - y) / (x + y)) * ((x - y) / (x + y)))
#define PI 3.1415

#define SHADOW
// lazy gigatron ;
#define fragCoord gl_FragCoord.xy
#define iTime time
#define iResolution resolution
#define fragColor glFragColor
// End Shadertoy

struct Material {
    vec3 color;
    float shininess;
    float opacity;
};

struct HitInfo {
    Material material;
    int type;
};
        
vec3 viewer;
vec3 target;

HitInfo hitInfo;

float clock;

vec3 mirrorRay(vec3 ray, vec3 normal) {
    float dot = dot(ray, normal);
    return 2.0 * dot * normal - ray;
}

float getPatternWeight(vec3 position) {
    if (mod(position.z, 1.788854) > 0.894427) position.x += 0.5;

    vec2 local = vec2(mod(position.x, 1.000000), mod(position.z, 0.894427));
    vec2 center = vec2(0.5, 0.447214);    

    vec2 delta = center - local;                  
    if (dot(delta, delta) > 0.18) return 0.0;
    else                          return 1.0;    
}

float getDistanceBox(vec3 position, vec3 boxRadius, float r) {
    vec3 delta = abs(position) - boxRadius;
    return min(max(delta.x, max(delta.y, delta.z)), 0.0) + length(max(delta, 0.0)) - r;
}

float getDistancePlaneXZ(vec3 position, float height) {
    return position.y - height;
}

mat2 getRotation(float r) {
     return mat2(cos(r), sin(r), -sin(r), cos(r));
}

float getDistanceSceneOpaque(vec3 position, bool saveHit) {
    float field = getDistancePlaneXZ(position, -0.5);  
    
    if (field < DISTANCE_EPSILON && saveHit) {
        hitInfo.type = TYPE_OPAQUE;
        hitInfo.material.color = mix(
            vec3(0.9, 0.8, 0.8),
            vec3(0.9, 0.2, 0.2),
            getPatternWeight(position)
        );
        
        hitInfo.material.shininess = 0.1;
        hitInfo.material.opacity = 1.0;
       }    

    return field;
}

float getDistanceSceneTransparent(vec3 position, bool saveHit) {   
    mat2 twirl = mat2(cos(-clock), sin(-clock), -sin(-clock), cos(-clock));
    vec3 local = position;
    
    local.xyz = position.xyz - vec3(target.x, sin(mod(clock, 0.5 * PI) + 0.25 * PI), 0.0);
    local.xy = getRotation(-clock) * local.xy;
    float field = getDistanceBox(local, vec3(1.0), 0.2);    

    local = position;
    local.x -= 1.0 * target.x + 2.5;
    local.y -= 0.5 *  sin(mod(2.0 * clock, 0.5 * PI) + 0.25 * PI);
    local.xy = twirl * twirl * local.xy;
    local.z -= 2.2;

    field = min(field, getDistanceBox(local, vec3(0.5), 0.1));
    
    local = position;
    local.x -= 1.0 * target.x + 0.5;
    local.y -= 0.5 *  sin(mod(2.0 * clock, 0.5 * PI) + 0.25 * PI);
    local.xy = twirl * twirl * local.xy;
    local.z -= 2.2;
    
    field = min(field, getDistanceBox(local, vec3(0.5), 0.1));

    if (field < DISTANCE_EPSILON && saveHit) {
        hitInfo.type = TYPE_TRANSPARENT;
        hitInfo.material.color = vec3(1.0, 0.9, 0.8);
        hitInfo.material.shininess = 7.0;
        hitInfo.material.opacity = 0.025;
    }

    return field;
}

float getDistanceScene(vec3 position, bool saveHit) {
    return min(
        getDistanceSceneOpaque(position, saveHit),
        getDistanceSceneTransparent(position, saveHit)
    );    
}
   
vec3 getNormalTransparent(vec3 position) {
    vec3 nDelta = vec3(
        getDistanceSceneTransparent(position - vec3(NORMAL_DELTA, 0.0, 0.0), false),
        getDistanceSceneTransparent(position - vec3(0.0, NORMAL_DELTA, 0.0), false),
        getDistanceSceneTransparent(position - vec3(0.0, 0.0, NORMAL_DELTA), false)
       );
    
    vec3 pDelta = vec3(
        getDistanceSceneTransparent(position + vec3(NORMAL_DELTA, 0.0, 0.0), false),
        getDistanceSceneTransparent(position + vec3(0.0, NORMAL_DELTA, 0.0), false),
        getDistanceSceneTransparent(position + vec3(0.0, 0.0, NORMAL_DELTA), false)
       );
     
    return normalize(pDelta - nDelta);
}

vec3 getNormalOpaque(vec3 position) {
    vec3 nDelta = vec3(
        getDistanceSceneOpaque(position - vec3(NORMAL_DELTA, 0.0, 0.0), false),
        getDistanceSceneOpaque(position - vec3(0.0, NORMAL_DELTA, 0.0), false),
        getDistanceSceneOpaque(position - vec3(0.0, 0.0, NORMAL_DELTA), false)
       );
    
    vec3 pDelta = vec3(
        getDistanceSceneOpaque(position + vec3(NORMAL_DELTA, 0.0, 0.0), false),
        getDistanceSceneOpaque(position + vec3(0.0, NORMAL_DELTA, 0.0), false),
        getDistanceSceneOpaque(position + vec3(0.0, 0.0, NORMAL_DELTA), false)
       );
     
    return normalize(pDelta - nDelta);
}

float getSoftShadow(vec3 position, vec3 normal) {
    position += DISTANCE_EPSILON * normal;
    
    float delta = 1.0;
    float minimum = 1.0;
    for (int i = 0; i < ITERATION_COUNT; i++) {
        float field = max(0.0, getDistanceSceneTransparent(position, false));
        if (field < DISTANCE_EPSILON) return 0.3;

        minimum = min(minimum, 8.0 * field / delta);

        vec3 rPos = position - target;
        if (dot(rPos, rPos) > SCENE_RADIUS) {
            return clamp(minimum, 0.3, 1.0);
        }        
        
        delta += 0.1* field;
        position += field * 0.25 * normal;
    }
    
    return clamp(minimum, 0.3, 1.0);
}

float getAmbientOcclusion(vec3 position, vec3 normal) {
    float brightness = 0.0;
    
    brightness += getDistanceScene(position + 0.5 * OCCLUSION_DELTA * normal, false);
    brightness += getDistanceScene(position + 2.0 * OCCLUSION_DELTA * normal, false);
    brightness += getDistanceScene(position + 4.0 * OCCLUSION_DELTA * normal, false);
    
    brightness = pow(brightness + 0.01, 0.5);    
    return clamp(1.0 * brightness, 0.5, 1.0);
}

vec3 getLightDiffuse(vec3 surfaceNormal, vec3 lightNormal, vec3 lightColor) {
    float power = max(0.0, dot(surfaceNormal, lightNormal));
    return power * lightColor;
}

vec3 getLightSpecular(vec3 reflectionNormal, vec3 viewNormal, vec3 lightColor, float power) {
    return pow(max(0.0, dot(reflectionNormal, viewNormal)), power) * lightColor;
}

float getFresnelSchlick(vec3 surfaceNormal, vec3 halfWayNormal, float r0) {
    return r0 + (1.0 - r0) * pow(1.0 - dot(surfaceNormal, halfWayNormal), 5.0);
}

vec3 computeLight(vec3 position, vec3 surfaceNormal, Material material) {
    vec3 lightPosition = target + vec3(-2.0, 4.0, 2.0);
    vec3 lightAmbient  = 1.0 * vec3(0.2, 0.2, 0.5);
    vec3 lightColor    = 100.0 * vec3(1.1, 0.9, 0.5);
    
    vec3 lightVector = lightPosition - position;
    float attenuation = 1.0 / dot(lightVector, lightVector);
    if (dot(surfaceNormal, lightVector) <= 0.0) return lightAmbient * material.color;
        
    vec3 lightNormal = normalize(lightVector);
    
#ifdef SHADOW
    if (hitInfo.type == TYPE_OPAQUE) {
        lightColor *= getSoftShadow(position, lightNormal);
    }
#endif
    
    vec3 viewNormal       = normalize(viewer - position);
    vec3 halfWayNormal    = normalize(viewNormal + lightNormal);
    vec3 reflectionNormal = mirrorRay(lightNormal, surfaceNormal);
        
    float fresnelTerm  = getFresnelSchlick(surfaceNormal, halfWayNormal, material.shininess);
    vec3 lightDiffuse  = getLightDiffuse(surfaceNormal, lightNormal, lightColor);    
    vec3 lightSpecular = getLightSpecular(reflectionNormal, viewNormal, lightColor, 16.0);
    
    float brightness = getAmbientOcclusion(position, surfaceNormal);
    
    return brightness * (
        lightAmbient + attenuation * (
            material.opacity * lightDiffuse + fresnelTerm * lightSpecular
        )
    ) * material.color;
}

vec3 traceRay(vec3 position, vec3 normal) {
       vec3 colorOutput = vec3(0.0);
       vec3 rayColor = vec3(1.0);
    
    float fogAccum = 0.0;
    
      int mode = MODE_OUTSIDE;
       for(int hitCount = 0; hitCount < MAX_HIT_COUNT; hitCount++) {
        hitInfo.type = TYPE_NONE;
        
        for (int it = 0; it < ITERATION_COUNT; it++) {            
            float field;
            
            if (mode == MODE_OUTSIDE) {
                field = getDistanceScene(position, true);            
                fogAccum += abs(field);
                if (field < DISTANCE_EPSILON) break;
            }
            else {
                field = getDistanceSceneTransparent(position, true);
                if (field > DISTANCE_EPSILON) break;
            }

            vec3 rPos = position - target;
            if (dot(rPos, rPos) > SCENE_RADIUS) {
                hitInfo.type = TYPE_NONE;
                break;
            }

            float march = max(DISTANCE_EPSILON, abs(field));
            position = position + STEP_SCALE * march * normal;
        }

         if (hitInfo.type == TYPE_OPAQUE) {
            colorOutput += rayColor * computeLight(
                position, 
                getNormalOpaque(position),
                hitInfo.material
            );
            
            break;
        } 
        else if (hitInfo.type == TYPE_TRANSPARENT) {
            vec3 surfaceNormal = getNormalTransparent(position);
            if (mode == MODE_INSIDE) surfaceNormal = -surfaceNormal;
            
            colorOutput += 0.02 * rayColor * computeLight(
                position, 
                surfaceNormal,
                hitInfo.material
            );
            
            rayColor *= hitInfo.material.color;
            normal = refract(normal, surfaceNormal, N1 / N2);
            
            if (mode == MODE_INSIDE) {
                if (dot(normal, surfaceNormal) < 0.0) mode = MODE_OUTSIDE;
                else                                  mode = MODE_INSIDE;
            }
            else mode = MODE_INSIDE;
        }
        else {
            break;
        }
     }
            
    vec3 dist = position - target;
    return vec3(1.0 / (dot(dist, dist) * 0.001 + 1.0)) * colorOutput;
}

vec3 createRayNormal(vec3 origo, vec3 target, vec3 up, vec2 plane, float fov, vec3 displacement) {
    vec3 axisZ = normalize(target - origo);
    vec3 axisX = normalize(cross(axisZ, up));
    vec3 axisY = cross(axisX, axisZ);

    origo += mat3(axisX, axisY, axisZ) * -displacement;
    
    vec3 point = target + fov * length(target - origo) * (plane.x * axisX + plane.y * axisY);
    return normalize(point - origo);
}

void main() {
    float cosCamera = cos(2.4 + 2.0 * cos(0.4 * iTime) + 0.0 * (fragCoord.y / iResolution.y));
    float sinCamera = sin(2.4 + 2.0 * cos(0.4 * iTime) + 0.0 * (fragCoord.y / iResolution.y));
    
    clock = mod(1.0 * iTime, 20.0 * PI);
    
    vec3 m = vec3(1.6 * -clock, 0.0, 1.0);
    
    float rot = 3.0 + 0.1 * cos(iTime);
    
    viewer = m + vec3(rot * cosCamera, 2.0 * sin(0.4 * iTime) + 2.5, rot * sinCamera);
    target = m + vec3(0.0, 0.5, 0.0);
    
    
    vec3 displacement = vec3(0.0);
    
    // Stereo.
    // if (mod(fragCoord.y, 2.0) > 1.0) displacement.x += 0.02; 
    // else                                displacement.x -= 0.02;
    
    vec3 normal = createRayNormal(
        viewer,
        target,
        vec3(0.0, 1.0, 0.0),
        (fragCoord.xy - 0.5 * iResolution.xy) / iResolution.y,
        1.6,
        displacement
    );
    
    hitInfo.type = TYPE_NONE;
        
    //mat2 r = getRotation(0.25 * length(fragCoord.xy - 0.5 * iResolution.xy) / iResolution.y);
    vec3 color = traceRay(viewer, normal);
    //color.rb = r * color.rg;
   
    fragColor = vec4(color, 1.0);
}
