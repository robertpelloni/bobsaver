#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tdffzn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Christopher Wallis
#define PI 3.14
#define SCENE_MAX_T 900.0

#define CHECKER_FLOOR_MATERIAL_ID 0
#define LAMP_MATERIAL_ID 1
#define NUM_MATERIALS 2

#define NUM_LIGHTS 20

#define INVALID_MATERIAL_ID int(-1)
#define LARGE_NUMBER 1e20
#define EPSILON 0.0001

struct CameraDescription
{
    vec3 Position;
    vec3 LookAt;    

    float LensHeight;
    float FocalDistance;
};
    
struct OrbLightDescription
{
    vec3 Position;
    float Radius;
    vec3 LightColor;
};
    
CameraDescription Camera = CameraDescription(
    vec3(0, 20, -250),
    vec3(0, 5, 0),
    2.0,
    7.0
);

OrbLightDescription GetLight(int lightIndex)
{
    float theta = time * 0.2 * (float(lightIndex) + 1.0f);
    float radius = 10.0f + float(lightIndex) * 2.5;
    
    OrbLightDescription orbLight;
    orbLight.Position = vec3(radius * cos(theta), 3.0 + sin(theta * 2.0) * 2.5, radius * sin(theta));
    orbLight.LightColor = vec3(20.0, 10.0, 0.4);
    orbLight.Radius = 1.0f;

    return orbLight;
}

#define MATERIAL_IS_LIGHT_SOURCE 0x1

struct Material
{
    vec3 albedo;
    vec3 emissive;
    int flags;
};
    
Material NormalMaterial(vec3 albedo, int flags)
{
    return Material(albedo, vec3(0), flags);
}

bool IsLightSource(in Material m)
{
    return (m.flags & MATERIAL_IS_LIGHT_SOURCE) != 0;
}

Material GetMaterial(int materialID, vec3 position)
{
    Material materials[NUM_MATERIALS];
    materials[CHECKER_FLOOR_MATERIAL_ID] = NormalMaterial(vec3(0.6, 0.6, 0.7), 0);
    materials[LAMP_MATERIAL_ID] = NormalMaterial(GetLight(0).LightColor, MATERIAL_IS_LIGHT_SOURCE);
    
    Material mat;
    if(materialID < int(NUM_MATERIALS))
    {
        mat = materials[materialID];
    }
    else
    {
        // Should never get hit
           return materials[0];
    }
    
    if(materialID == CHECKER_FLOOR_MATERIAL_ID)
    {
        vec2 uv = position.xz / 13.0;
        uv = vec2(uv.x < 0.0 ? abs(uv.x) + 1.0 : uv.x, uv.y < 0.0 ? abs(uv.y) + 1.0 : uv.y);
        if((int(uv.x) % 2 == 0 && int(uv.y) % 2 == 0) || (int(uv.x) % 2 == 1 && int(uv.y) % 2 == 1))
        {
            mat.albedo = vec3(1, 1, 1) * 0.7;
        }
    }

    return mat;    
}

// https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-plane-and-ray-disk-intersection
float PlaneIntersection(vec3 rayOrigin, vec3 rayDirection, vec3 planeOrigin, vec3 planeNormal, out vec3 normal) 
{ 
    float t = -1.0f;
    normal = planeNormal;
    float denom = dot(-planeNormal, rayDirection); 
    if (denom > EPSILON) { 
        vec3 rayToPlane = planeOrigin - rayOrigin; 
        return dot(rayToPlane, -planeNormal) / denom; 
    } 
 
    return t; 
} 
    
float SphereIntersection(
    in vec3 rayOrigin, 
    in vec3 rayDirection, 
    in vec3 sphereCenter, 
    in float sphereRadius, 
    out vec3 normal)
{
      vec3 eMinusC = rayOrigin - sphereCenter;
      float dDotD = dot(rayDirection, rayDirection);

      float discriminant = dot(rayDirection, (eMinusC)) * dot(rayDirection, (eMinusC))
         - dDotD * (dot(eMinusC, eMinusC) - sphereRadius * sphereRadius);

      // If the ray doesn't intersect
      if (discriminant < 0.0) 
         return -1.0;

      float firstIntersect = (dot(-rayDirection, eMinusC) - sqrt(discriminant))
             / dDotD;
      
      float t = firstIntersect;
    
      // If the ray is inside the sphere
      if (firstIntersect < EPSILON) {
         t = (dot(-rayDirection, eMinusC) + sqrt(discriminant))
             / dDotD;
      }
    
      normal = normalize(rayOrigin + rayDirection * t - sphereCenter);
      return t;
}

void UpdateIfIntersected(
    inout float t,
    in float intersectionT, 
    in vec3 intersectionNormal,
    in int intersectionMaterialID,
    out vec3 normal,
    out int materialID
    )
{    
    if(intersectionT > EPSILON && intersectionT < t)
    {
        normal = intersectionNormal;
        materialID = intersectionMaterialID;
        t = intersectionT;
    }
}

float IntersectOpaqueScene(in vec3 rayOrigin, in vec3 rayDirection, out int materialID, out vec3 normal)
{
    float intersectionT = LARGE_NUMBER;
    vec3 intersectionNormal = vec3(0, 0, 0);

    float t = LARGE_NUMBER;
    normal = vec3(0, 0, 0);
    materialID = INVALID_MATERIAL_ID;

    for(int lightIndex = 0; lightIndex < NUM_LIGHTS; lightIndex++)
    {
        UpdateIfIntersected(
            t,
            SphereIntersection(rayOrigin, rayDirection, GetLight(lightIndex).Position, GetLight(lightIndex).Radius, intersectionNormal),
            intersectionNormal,
            LAMP_MATERIAL_ID,
            normal,
            materialID);
    }

    
    UpdateIfIntersected(
        t,
        PlaneIntersection(rayOrigin, rayDirection, vec3(0, 0, 0), vec3(0, 1, 0), intersectionNormal),
        intersectionNormal,
        CHECKER_FLOOR_MATERIAL_ID,
        normal,
        materialID);

    
    return t;
}

vec3 Diffuse(in vec3 normal, in vec3 lightVec, in vec3 diffuse)
{
    float nDotL = dot(normal, lightVec);
    return clamp(nDotL * diffuse, 0.0, 1.0);
}

void CalculateLighting(vec3 position, vec3 normal, vec3 reflectionDirection, Material material, bool shootShadowRays, inout vec3 color)
{
    for(int lightIndex = 0; lightIndex < NUM_LIGHTS; lightIndex++)
    {
        vec3 lightDirection = (GetLight(lightIndex).Position - position);
        float lightDistance = length(lightDirection);
        lightDirection /= lightDistance;

        // Manually tuned light falloff for what looked best
        vec3 lightColor = GetLight(lightIndex).LightColor / pow(lightDistance, 1.5); 

        color += 0.25 * lightColor * pow(max(dot(reflectionDirection, lightDirection), 0.0), 4.0);
        color += lightColor * Diffuse(normal, lightDirection, material.albedo);
    
    }
    color += material.emissive;
}

void Render( in vec3 rayOrigin, in vec3 rayDirection, out vec3 color)
{
    float depth = SCENE_MAX_T;
    color = vec3(0.0f);
    
    vec3 normal;
    float t;
    int materialID = INVALID_MATERIAL_ID;
    
    t = IntersectOpaqueScene(rayOrigin, rayDirection, materialID, normal);
    
    if( materialID != INVALID_MATERIAL_ID )
    {
        depth = t;
        vec3 position = rayOrigin + t*rayDirection;
        Material material = GetMaterial(materialID, position);
        if(IsLightSource(material))
        {
            color = min(material.albedo, vec3(1.0));
            return;
        }       
        
        vec3 reflectionDirection = reflect( rayDirection, normal);
        CalculateLighting(position, normal, reflectionDirection, material, true, color);
    }
}

mat3 GetViewMatrix(float xRotationFactor)
{ 
   float xRotation = ((1.0 - xRotationFactor) - 0.5) * PI * 0.4 + PI * 0.25;
   return mat3( cos(xRotation), 0.0, sin(xRotation),
                0.0,           1.0, 0.0,    
                -sin(xRotation),0.0, cos(xRotation));
}

float GetCameraPositionYOffset()
{
    return 250.0 * (mouse.y*resolution.y / resolution.y);
}

float GetRotationFactor()
{
    if(mouse.x*resolution.x <= 0.0)
    {
        // Default value when shader is initially loaded up
        return 0.65f;
    }
    
    return mouse.x*resolution.x / resolution.x;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    float aspectRatio = resolution.x /  resolution.y; 
    float lensWidth = Camera.LensHeight * aspectRatio;
    
    vec3 CameraPosition = Camera.Position + GetCameraPositionYOffset();
    
    vec3 NonNormalizedCameraView = Camera.LookAt - CameraPosition;
    float ViewLength = length(NonNormalizedCameraView);
    vec3 CameraView = NonNormalizedCameraView / ViewLength;

    vec3 lensPoint = CameraPosition;
    
    // Pivot the camera around the look at point
    {
        float rotationFactor = GetRotationFactor();
        mat3 viewMatrix = GetViewMatrix(rotationFactor);
        CameraView = CameraView * viewMatrix;
        lensPoint = Camera.LookAt - CameraView * ViewLength;
    }
    
    // Technically this could be calculated offline but I like 
    // being able to iterate quickly
    vec3 CameraRight = cross(CameraView, vec3(0, 1, 0));    
    vec3 CameraUp = cross(CameraRight, CameraView);

    vec3 focalPoint = lensPoint - Camera.FocalDistance * CameraView;
    lensPoint += CameraRight * (uv.x * 2.0 - 1.0) * lensWidth / 2.0;
    lensPoint += CameraUp * (uv.y * 2.0 - 1.0) * Camera.LensHeight / 2.0;
    
    vec3 rayOrigin = focalPoint;
    vec3 rayDirection = normalize(lensPoint - focalPoint);
    
    vec3 color;
    Render(rayOrigin, rayDirection, color);
    glFragColor=vec4( clamp(color, 0.0, 1.0), 1.0 );
}
