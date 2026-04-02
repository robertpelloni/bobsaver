#version 420

// original https://www.shadertoy.com/view/3ldcR4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Shader by Xenation / HalfRed
// some signed distance functions from Inigo Quilez: https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
// most lighting code is based upon what I made in my experimental engine: https://github.com/Xenation/IonEngine

#define TWO_PI 6.28318530718
#define PI 3.14159265359
#define HALF_PI 1.5707963268
#define THIRD_PI 1.0471975512
#define QUARTER_PI 0.7853981634
#define DEG_TO_RAD 0.0174533

const float MAX_DISTANCE = 50.0;
const float EPSILON = 0.0001;

const float ROTATION_SPEED = 0.2;

// ---- UTILITIES ----
// Structures
struct CameraDescriptor {
    vec3 position;
    vec3 target;
};

struct Ray {
    vec3 origin;
    vec3 direction;
};

struct Light {
    vec3 position;
    vec3 intensity;
    int type; // 0: ambient, 1: directional, 2: point
};

struct Material {
    vec3 albedo;
    vec3 emissive;
    float metallic;
    float reflectance;
    float roughness;
};

struct SurfaceData {
    vec3 diffuse;
    float roughness;
    vec3 f0;
};

// Functions
float remap(float val, float inMin, float inMax, float outMin, float outMax) {
    return (val - inMin) / (inMax - inMin) * (outMax - outMin) + outMin;
}

mat3 ViewToWorld(CameraDescriptor cam) {
    vec3 up = vec3(0.0, 1.0, 0.0);
    
    vec3 f = normalize(cam.target - cam.position);
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat3(s, u, f);
    /*return mat4(
        vec4(s, 0.0),
        vec4(u, 0.0),
        vec4(-f, 0.0),
        vec4(0.0, 0.0, 0.0, 1.0)
    );*/
}

vec3 RayDirection(in float fov, in vec2 size, in vec2 gl_FragCoord2) {
    vec2 xy = gl_FragCoord2.xy - size / 2.0;
    float z = size.y / tan(radians(fov) / 2.0);
    return normalize(vec3(xy, z));
}

SurfaceData CreateSurfaceData(in Material material) {
    SurfaceData data;
    data.f0 = material.albedo * material.metallic + (material.reflectance * (1.0 - material.metallic));
    data.diffuse = (1.0 - material.metallic) * material.albedo;
    data.roughness = material.roughness * material.roughness;
    return data;
}

Material BlendMaterial(Material m1, Material m2, float w) {
    Material blendMat;
    blendMat.albedo = mix(m1.albedo, m2.albedo, w);
    blendMat.emissive = mix(m1.emissive, m2.emissive, w);
    blendMat.metallic = mix(m1.metallic, m2.metallic, w);
    blendMat.reflectance = mix(m1.reflectance, m2.reflectance, w);
    blendMat.roughness = mix(m1.roughness, m2.roughness, w);
    return blendMat;
}

// ---- SDFs ----
float sdSphere(vec3 pos, float radius) {
    return length(pos) - radius;
}

float sdBox(vec3 pos, vec3 b) {
  vec3 q = abs(pos) - b;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdTriPrism(vec3 pos, vec2 h) {
    vec3 q = abs(pos);
    return max(q.z - h.y, max(q.x * 0.866025 + pos.y * 0.5, -pos.y) - h.x * 0.5);
}

float sdFloor(vec3 pos, float height) {
    return pos.y - height;
}

float opUnion( float d1, float d2 ) { return min(d1,d2); }
float opSubtraction( float d1, float d2 ) { return max(-d1,d2); }
float opIntersection( float d1, float d2 ) { return max(d1,d2); }

float opSmoothUnion(float d1, float d2, float k) {
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0 - h);
}

vec3 opRepeat(in vec3 pos, in vec3 size) {
    return mod(pos + 0.5 * size, size) - 0.5 * size;
}

vec3 rotateY(in vec3 p, float t) {
    float co = cos(t);
    float si = sin(t);
    p.xz = mat2(co,-si,si,co)*p.xz;
    return p;
}

vec3 rotateX(in vec3 p, float t) {
    float co = cos(t);
    float si = sin(t);
    p.yz = mat2(co,-si,si,co)*p.yz;
    return p;
}
vec3 rotateZ(in vec3 p, float t) {
    float co = cos(t);
    float si = sin(t);
    p.xy = mat2(co,-si,si,co)*p.xy;
    return p;
}

float opSmoothUnionMat(float d1, float d2, Material m1, Material m2, float k, out Material blendMat) {
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    blendMat = BlendMaterial(m1, m2, h);
    return mix(d2, d1, h) - k * h * (1.0 - h);
}

// Scene
float sdScene(vec3 pos, out Material material) {
    Material matFloor;
    matFloor.albedo = vec3(0.1, 0.1, 0.1);
    matFloor.metallic = 0.0;
    matFloor.reflectance = 0.0;
    matFloor.roughness = 0.2;
    
    Material matShapes;
    matShapes.emissive = vec3(1.0, 0.1, 0.1);
    matFloor.roughness = 0.9;

    float boxDist = 0.0;
    vec3 boxPos = pos;
    vec3 subPos = opRepeat(pos, vec3(0.866025 * 2.0, 100, 3.0)) + vec3(0.0, 0.0, -1.00);
    
    boxDist = sdBox(boxPos, vec3(1000.0, 0.05, 1000.0));
    boxDist = opSubtraction(sdBox(rotateY(subPos + vec3(0.0, 0.0, -0.5), HALF_PI), vec3(0.05, 0.5, 5.0)), boxDist);
    boxDist = opSubtraction(sdBox(rotateY(subPos + vec3(0.0, 0.0, 1.0), HALF_PI), vec3(0.05, 0.5, 5.0)), boxDist);
    boxDist = opSubtraction(sdBox(rotateY(subPos + vec3(0.0, 0.0, 2.5), HALF_PI), vec3(0.05, 0.5, 5.0)), boxDist);
    boxDist = opSubtraction(sdBox(rotateY(subPos + vec3(0.433012, 0.0, 0.25), HALF_PI - THIRD_PI), vec3(0.05, 0.5, 5.0)), boxDist);
    boxDist = opSubtraction(sdBox(rotateY(subPos + vec3(-0.433012, 0.0, 0.25), HALF_PI + THIRD_PI), vec3(0.05, 0.5, 5.0)), boxDist);
    
    float finalDist = opSmoothUnionMat(boxDist, sdFloor(pos, 0.0), matShapes, matFloor, 0.05, material);
    
    return finalDist;
}

// ---- Lighting ----
vec3 EstimateNormal(vec3 pos) {
    Material dummyMat;
    return normalize(vec3(
        sdScene(vec3(pos.x + EPSILON, pos.y, pos.z), dummyMat) - sdScene(vec3(pos.x - EPSILON, pos.y, pos.z), dummyMat),
        sdScene(vec3(pos.x, pos.y + EPSILON, pos.z), dummyMat) - sdScene(vec3(pos.x, pos.y - EPSILON, pos.z), dummyMat),
        sdScene(vec3(pos.x, pos.y, pos.z  + EPSILON), dummyMat) - sdScene(vec3(pos.x, pos.y, pos.z - EPSILON), dummyMat)
    ));
}

float D_GGX(float NoH, float a) {
    float a2 = a * a;
    float f = (NoH * a2 - NoH) * NoH + 1.0;
    return a2 / (PI * f * f);
}

vec3 F_Schlick(float VoH, vec3 f0) {
    return f0 + (vec3(1.0) - f0) * pow(1.0 - VoH, 5.0);
}

float V_SmithGGXCorrelatedFast(float NoV, float NoL, float roughness) {
    float GGXV = NoL * (NoV * (1.0 - roughness) + roughness);
    float GGXL = NoV * (NoL * (1.0 - roughness) + roughness);
    return 0.5 / (GGXV + GGXL);
}

float Fd_Lambert() {
    return 1.0 / PI;
}

vec3 EnvironmentColor(vec3 direction) {
    float DoU = dot(direction, vec3(0.0, 1.0, 0.0));
    float s = clamp(remap(acos(DoU), 110.0 * DEG_TO_RAD, 90.0 * DEG_TO_RAD, 0.0, 1.0), 0.0, 1.0);
    return mix(vec3(0.10, 0.10, 0.10), vec3(0.85, 1.00, 1.00), s);
}

vec3 Environment(SurfaceData surfData, vec3 envColor) {
    envColor *= surfData.f0;
    envColor /= surfData.roughness + 1.0;
    return envColor;
}

vec3 BRDF(SurfaceData surfData, vec3 normal, vec3 lightDir, vec3 viewDir) {
    vec3 halfDir = normalize(viewDir + lightDir);

    float NoV = abs(dot(normal, viewDir)) + 1e-5;
    float NoL = clamp(dot(normal, lightDir), 0.0, 1.0);
    float NoH = clamp(dot(normal, halfDir), 0.0, 1.0);
    float LoH = clamp(dot(lightDir, halfDir), 0.0, 1.0);

    float a = NoH * surfData.roughness;

    float D = D_GGX(NoH, a);
    vec3 F = F_Schlick(LoH, surfData.f0);
    float V = V_SmithGGXCorrelatedFast(NoV, NoL, surfData.roughness);

    vec3 Fr = (D * V) * F;

    vec3 Fd = surfData.diffuse;// * Fd_Lambert(); // Removed Lambert to avoid huge diffuse loss

    return Fr + Fd + Environment(surfData, EnvironmentColor(reflect(-viewDir, normal)));
}

vec3 ComputeAmbient(vec3 pos, vec3 normal, Ray ray, SurfaceData surfData, Light light) {
    return surfData.diffuse * light.intensity;
}

vec3 ComputeDirectionalLight(vec3 pos, vec3 normal, Ray ray, SurfaceData surfData, Light light) {
    vec3 lightDir = normalize(-light.position);
    vec3 lightColor = light.intensity;

    float lightAtten = 1.0;
    float NoL = clamp(dot(normal, lightDir), 0.0, 1.0);
    vec3 radiance = lightColor.rgb * (lightAtten * NoL);
    return BRDF(surfData, normal, lightDir, -ray.direction) * radiance;
}

vec3 ComputePointLight(vec3 pos, vec3 normal, Ray ray, SurfaceData surfData, Light light) {
    vec3 lightDir = light.position - pos;
    float dist = sqrt(dot(lightDir, lightDir));
    float lightAtten = 1.0 / dist;
    lightDir /= dist;

    float NoL = clamp(dot(normal, lightDir), 0.0, 1.0);
    vec3 radiance = light.intensity * (lightAtten * NoL);
    return BRDF(surfData, normal, lightDir, -ray.direction) * radiance;
}

vec3 ComputeIllumination(vec3 pos, vec3 normal, Ray ray, SurfaceData surfData, Light light) {
    if (light.type == 0) {
        return ComputeAmbient(pos, normal, ray, surfData, light);
    } else if (light.type == 1) {
        return ComputeDirectionalLight(pos, normal, ray, surfData, light);
    } else if (light.type == 2) {
        return ComputePointLight(pos, normal, ray, surfData, light);
    }
}

// ---- Ray Marching ----
vec4 March(Ray ray, out Material material) {
    float rayDistance = 0.0;
    
    vec3 pos = ray.origin;
    while (rayDistance < MAX_DISTANCE) {
        pos = ray.origin + ray.direction * rayDistance;
        float dist = sdScene(pos, material);
        
        if (dist < EPSILON) {
            break;
        }
        
        rayDistance += dist;
    }
    
    return vec4(pos, rayDistance);
}

void main(void) {
    // Setting up the camera
    CameraDescriptor cam;
    cam.position = vec3(cos(time * ROTATION_SPEED - HALF_PI) * 5.0, 3.0, sin(time * ROTATION_SPEED - HALF_PI) * -5.0);
    cam.target = vec3(0.0);
    
    mat3 vtw = ViewToWorld(cam);
    
    // Setting up 4 rays per pixel with coords roughly similar to 4x MSAA sampling
    vec2 rayCoord = gl_FragCoord.xy - vec2(0.5);
    Ray rays[4];
    rays[0].origin = cam.position;
    rays[1].origin = cam.position;
    rays[2].origin = cam.position;
    rays[3].origin = cam.position;
    rays[0].direction = vtw * RayDirection(90.0, resolution.xy, rayCoord + vec2(0.4, 0.1));
    rays[1].direction = vtw * RayDirection(90.0, resolution.xy, rayCoord + vec2(0.9, 0.4));
    rays[2].direction = vtw * RayDirection(90.0, resolution.xy, rayCoord + vec2(0.6, 0.9));
    rays[3].direction = vtw * RayDirection(90.0, resolution.xy, rayCoord + vec2(0.1, 0.6));
    
    // Setting up lights
    Light ambient;
    ambient.type = 0;
    ambient.intensity = vec3(0.9, 1.0, 0.9) * 0.1;
    
    Light point;
    point.type = 2;
    point.position = vec3(0.0, 2.0, 0.0);
    point.intensity = vec3(1.0);
    
    Light dirLight;
    dirLight.type = 1;
    dirLight.position = vec3(-0.3, -1, 0.5);
    dirLight.intensity = vec3(0.5);
    
    // Raymarch each ray
    glFragColor = vec4(0.0);
    for (int i = 0; i < 4; i++) {
        Material material;
        vec4 marchResult = March(rays[i], material);
        vec3 pos = marchResult.xyz;
        float depth = marchResult.w;

        if (depth > MAX_DISTANCE) {
            glFragColor = vec4(0.0);
            return;
        }

        SurfaceData surfData = CreateSurfaceData(material);
        vec3 normal = EstimateNormal(pos);

        glFragColor.rgb += material.emissive;
        glFragColor.rgb += ComputeIllumination(pos, normal, rays[i], surfData, ambient);
        glFragColor.rgb += ComputeIllumination(pos, normal, rays[i], surfData, point);
        glFragColor.rgb += ComputeIllumination(pos, normal, rays[i], surfData, dirLight);
    }
    glFragColor.rgb /= 4.0;
}
