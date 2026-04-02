#version 420

// original https://www.shadertoy.com/view/3sc3z4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//drag the window LR to control roughness

//--graphics setting (lower = better fps)---------------------------------------------------------------------
#define AVERAGECOUNT 16
#define MAX_BOUNCE 32

//--scene data---------------------------------------------------------------------
#define SPHERECOUNT 6
//xyz = pos, w = radius
const vec4 AllSpheres[SPHERECOUNT]=vec4[SPHERECOUNT](
    vec4(0.0,0.0,0.0,2.0),//sphere A
    vec4(0.0,0.0,-1.0,2.0),//sphere B
    vec4(0.0,-1002.0,0.0,1000.0),//ground
    vec4(0.0,0.0,+1002,1000.0),//back wall
    vec4(-1004.0,0.0,0.0,1000.0),//left wall    
    vec4(+1004.0,0.0,0.0,1000.0)//right wall
);
//-----------------------------------------------------------------------
float raySphereIntersect(vec3 r0, vec3 rd, vec3 s0, float sr) {
    // - r0: ray origin
    // - rd: normalized ray direction
    // - s0: sphere center
    // - sr: sphere radius
    // - Returns distance from r0 to first intersecion with sphere,
    //   or -1.0 if no intersection.
    float a = dot(rd, rd);
    vec3 s0_r0 = r0 - s0;
    float b = 2.0 * dot(rd, s0_r0);
    float c = dot(s0_r0, s0_r0) - (sr * sr);
    if (b*b - 4.0*a*c < 0.0) {
        return -1.0;
    }
    return (-b - sqrt((b*b) - 4.0*a*c))/(2.0*a);
}
//-----------------------------------------------------------------------
struct HitData
{
    float rayLength;
    vec3 normal;
};
HitData AllObjectsRayTest(vec3 rayPos, vec3 rayDir)
{
    HitData hitData;
    hitData.rayLength = 999999.0;

    for(int i = 0; i < SPHERECOUNT; i++)
    {
        vec3 sphereCenter = AllSpheres[i].xyz;
        float sphereRadius = AllSpheres[i].w;
        //----hardcode sphere pos animations-------------------------------------
        if(i == 0)
        {
            float t = fract(time * 0.7);
            t = -4.0 * t * t + 4.0 * t;
            sphereCenter.y += t * 0.7;
            
            sphereCenter.x += sin(time) * 2.0;
            sphereCenter.z += cos(time) * 2.0;
        }
             
        if(i == 1)
        {
            float t = fract(time*0.47);
            t = -4.0 * t * t + 4.0 * t;
            sphereCenter.y += t * 1.7;
            
            sphereCenter.x += sin(time+3.14) * 2.0;
            sphereCenter.z += cos(time+3.14) * 2.0;
        }             
        //---------------------------------------
                
        float resultRayLength = raySphereIntersect(rayPos,rayDir,sphereCenter,sphereRadius);
        if(resultRayLength < hitData.rayLength && resultRayLength > 0.001)
        {
            //if a shorter(better) hit ray found, update
            hitData.rayLength = resultRayLength;
            vec3 hitPos = rayPos + rayDir * resultRayLength;
            hitData.normal = normalize(hitPos - sphereCenter);
        }
    }
    
    //all test finished, return shortest(best) hit data
    return hitData;
}
//--random functions-------------------------------------------------------------------
float rand01(float seed) { return fract(sin(seed)*43758.5453123); }
vec3 randomInsideUnitSphere(vec3 rayDir,vec3 rayPos, float extraSeed)
{
    return vec3(rand01(time * (rayDir.x + rayPos.x + 0.357) * extraSeed),
                rand01(time * (rayDir.y + rayPos.y + 16.35647) *extraSeed),
                rand01(time * (rayDir.z + rayPos.z + 425.357) * extraSeed));
}
//---------------------------------------------------------------------
vec3 calculateFinalColor(vec3 cameraPos, vec3 cameraRayDir, float AAIndex)
{
    //init
    vec3 finalColor = vec3(0.0);
    float absorbMul = 1.0;
    vec3 rayStartPos = cameraPos;
    vec3 rayDir = cameraRayDir;
    
    //can't write recursive function in GLSL, so write it in a for loop
    //will loop until hitting any light source / bounces too many times
    for(int i = 0; i < MAX_BOUNCE; i++)
    {
        HitData h = AllObjectsRayTest(rayStartPos + rayDir * 0.0001,rayDir);//+0.0001 to prevent ray already hit @ start pos
        if(h.rayLength > 99999.0)
        {
            vec3 skyColor = vec3(0.7,0.85,1.0);//hit nothing = hit sky color
            finalColor = skyColor * absorbMul;
            break;
        }   
               
        absorbMul *= 0.8; //every bounce absorb some light(more bounces = darker)
        
        //update rayStartPos for next bounce
        rayStartPos = rayStartPos + rayDir * h.rayLength; 
        //update rayDir for next bounce
        float rougness = 0.05 + mouse.x*resolution.x / resolution.x; //hardcode "drag the window LR to control roughness"
        rayDir = normalize(reflect(rayDir,h.normal) + randomInsideUnitSphere(rayDir,rayStartPos,AAIndex) * rougness);
    }
    return finalColor;
}
//-----------------------------------------------------------------------
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    uv = uv * 2.0 - 1.0;//transform from [0,1] to [-1,1]
    uv.x *= resolution.x / resolution.y; //aspect fix

    vec3 cameraPos = vec3(sin(time * 0.47) * 4.0,sin(time * 0.7)*8.0+6.0,-25.0);//camera pos animation
    vec3 cameraFocusPoint = vec3(0,0.0 + sin(time),0);//camera look target point animation
    vec3 cameraDir = normalize(cameraFocusPoint - cameraPos);
    
    //TEMPCODE: fov & all ray init dir, it is wrong!!!!
    //----------------------------------------------------
    float fovTempMul = 0.2 + sin(time * 0.4) * 0.05;//fov animation
    vec3 rayDir = normalize(cameraDir + vec3(uv,0) * fovTempMul);
    //----------------------------------------------------

    vec3 finalColor = vec3(0,0,0);
    for(int i = 1; i <= AVERAGECOUNT; i++)
    {
        finalColor+= calculateFinalColor(cameraPos,rayDir, float(i));
    }
    finalColor = finalColor/float(AVERAGECOUNT);//brute force AA & denoise
    finalColor = pow(finalColor,vec3(1.0/2.2));//gamma correction
    
    //result
    glFragColor = vec4(finalColor,1.0);
}
