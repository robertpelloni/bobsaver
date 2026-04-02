#version 420

// original https://www.shadertoy.com/view/WlV3zD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

My second attempt at raymarching. I think I am finally starting to grasp the concept.
Using this tutorial, I was able to create this neat animating sphere: http://www.michaelwalczyk.com/blog/2017/5/25/ray-marching
I used variables with clear names to make the code easier to understand & read for people new to raymarching.
Have fun messing around in here!

-TheCreator, 07/01/2020

*/

/*

Just a utility method I created to avoid code duplication. 
Allows me to control a cos curve's parameters for color changes over time

*/
float costime(float centerValue, float intensity, float offset) {
    return centerValue + intensity * cos(time + offset);
}

/*

Signed distance functions (short: SDFs) are functions which describe the shapes in a raymarched scene with math.
Opposed to that are meshes made out of trianges, which most 3D games rely on today.

You can find a list of functions for describing different shapes here: https://iquilezles.org/www/articles/distfunctions/distfunctions.htm

*/
float sphereSDF(vec3 samplePos, vec3 spherePos, float radius) {
    return length(samplePos - spherePos) - radius;
}

/*

The SDF for all objects in the world. Currently only a sphere with animated displacement is being rendered.

*/
float worldSDF(vec3 samplePos) {
    float displacement = sin(costime(4.0, 3.0, 0.0) * samplePos.x) * sin(costime(5.0, 2.0, 2.0) * samplePos.y) * sin(costime(3.0, 4.0, 3.0) * samplePos.z) * 0.25;
    float sphere0 = sphereSDF(samplePos, vec3(0.0), 1.0);
    
    return sphere0 + displacement;
}

/*

This function determines the surface normal. I don't fully understand how it works just yet.

*/
vec3 estimateNormal(vec3 pos) {
    vec3 smallStep = vec3(0.001, 0.0, 0.0);
    
    float gradientX = worldSDF(pos + smallStep.xyy) - worldSDF(pos - smallStep.xyy);
    float gradientY = worldSDF(pos + smallStep.yxy) - worldSDF(pos - smallStep.yxy);
    float gradientZ = worldSDF(pos + smallStep.yyx) - worldSDF(pos - smallStep.yyx);
    
    vec3 normal = vec3(gradientX, gradientY, gradientZ);
    
    return normalize(normal);
}

/*

The actual raymarch function. Takes a ray origin and a ray direction and marches along the ray using a
technique called "sphere tracing". The code checks for the nearest object using the world SDF and then
moves the next point that is checked to the edge of that sphere, ensuring the checked position is
either outside of the object or on the edge of it. This continues until the ray hits an object
or the maximum number of steps is reached. I might flesh out this explaination in the future, however
tutorials online with an illustration can explain sphere tracing far better than a thousand words ever could.

*/
vec3 raymarch(vec3 rayOrigin, vec3 rayDir) {
    float marchedDist = 0.0;
    int maxSteps = 128;
    float minHitDist = 0.001;
    float maxTraceDist = 1000.0;
    
    for(int i = 0; i < maxSteps; ++i) {
        vec3 marchPos = rayOrigin + marchedDist * rayDir;
        
        float sphereTraceDist = worldSDF(marchPos);
        
        if(sphereTraceDist < minHitDist) {
            vec3 normal = estimateNormal(marchPos);
            
            //Manually set light position for now
            vec3 lightPos = vec3(2.0, -5.0, 3.0);
            vec3 directionToLight = normalize(marchPos - lightPos);
            float diffuseIntensity = max(0.0, dot(normal, directionToLight));
            
            return vec3(costime(0.5, 0.5, 0.0), costime(0.5, 0.5, 2.0), costime(0.5, 0.5, 4.0)) * diffuseIntensity;
        }
        
        if(marchedDist > maxTraceDist) {
            return vec3(0.0);
        }
        
        marchedDist += sphereTraceDist;
    }
    
    return vec3(0.0);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    
    vec3 cameraPos = vec3(0.0, 0.0, -2.0);
    vec3 rayDirection = vec3(uv, 1.0);

    vec3 col = raymarch(cameraPos, rayDirection);

    glFragColor = vec4(col,1.0);
}
