#version 420

// original https://www.shadertoy.com/view/ttXfzl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Hold & drag on window to move view
#define PI 3.1415f
#define mandelbulb 1 //1 is Mandelbulb scene, 0 is spheres scene

//The shortest distance function of a plane
float GetPlaneSDF(vec3 point, vec3 normal, float height)
{
    return dot(point, normal) - height;
}

//The shortest distance function of a sphere
float GetSphereSDF(vec3 point, vec3 spherePos, float radius)
{
    return (length(point - spherePos) - radius);
}

//The shortest distance function of Mandelbulb
//http://blog.hvidtfeldts.net/index.php/2011/09/distance-estimated-3d-fractals-v-the-mandelbulb-different-de-approximations/
float GetMandelbulbSDF(vec3 pos)
{
    float power = 6.f + sin(time) * 0.1f;
    //float power = mouse*resolution.xy.x / (resolution.y*0.1f) + sin(time) * 0.1f;
    vec3 z = pos;
    float dr = 1.0;
    float r = 0.0;
    for (int i = 0; i < 128; i++)
    {
        r = length(z);
        if (r > 2.f) break;
        
        // convert to polar coordinates
        float theta = acos(z.z/r);
        float phi = atan(z.y, z.x);
        dr =  pow( r, power - 1.0) * power * dr + 1.0;
        
        // scale and rotate the point
        float zr = pow(r,power);
        theta = theta*power;
        phi = phi*power;
        
        // convert back to cartesian coordinates
        z = zr * vec3(sin(theta) * cos(phi), sin(phi) * sin(theta), cos(theta));
        z += pos;
    }
    return 0.5f * log(r) * r/dr;
}

//Following describes the scene
float GetSceneSDF(vec3 point)
{
    #if mandelbulb
    
    //Mandelbulb scene
    return GetMandelbulbSDF(point);
    
    #else
    
    //Other scene
    float sphereRadius = (sin(time) + 2.f) * 3.f;
    
    //Spheres
    float s1 = GetSphereSDF(point, vec3(0.f,0.f,20.f), sphereRadius * 0.75f);
    float s2 = GetSphereSDF(point, vec3(10.f,0.f,25.f), sphereRadius);
    float s3 = GetSphereSDF(point, vec3(-10.f,0.f,25), sphereRadius);
    float spheres = max(min(s2,s3), -s1);
    
    //Planes
    float p1 = GetPlaneSDF(point, vec3(0.f, 1.f, 0.f), -10.f);
    float planes = p1;
    
    //Total
    return min(spheres, planes);
    #endif
}

//Estimate the normal of a given point using the scene
vec3 GetNormal(vec3 point)
{
    //Get distance
    float dist = GetSceneSDF(point);
    vec2 e = vec2(.01, 0); //faster to type out
    
    //Obtain normal
    return normalize(dist + vec3(
        GetSceneSDF(point + e.xyy),
        GetSceneSDF(point + e.yxy),
        GetSceneSDF(point + e.yyx)));
}

//Perform the raymarching itself
float DoMarch(vec3 dir, vec3 origin)
{
    //Settings
     const int maxStep = 512;
    const float maxDistance = 512.f;
    const float minStep = 1.f / 8192.f;
    
    //Start
    float total = 0.f;
    float step = GetSceneSDF(origin);
    
    //March into the scene for a maximum amount of steps
    for(int i=0; i < maxStep; ++i)
    {
        vec3 point = origin + dir * total;
        step = GetSceneSDF(point);
        total += step;
        
        //If step was quite small, end
        if(step < minStep)
        {
            return total;
        }
    }
    
    //If too far, we didn't hit anything
    if(total > maxDistance)
    {
        return 0.f;
    }
    
    return total;
}

//Perform some lighting calculations
vec3 DoLight(vec3 pos, vec3 viewDir)
{
    //Different lights for different scenes
    #if mandelbulb
    vec3 lightDir = normalize(vec3(0.3f, -0.57f, -0.95f)); //light
    #else
    vec3 lightDir = normalize(vec3(sin(time), -0.57f, cos(time))); //light
    #endif
    
    vec3 normal = GetNormal(pos);
    float value = clamp(dot(-lightDir, normal), 0.f, 1.f);
    
    if(DoMarch(-lightDir, pos + normal * 0.01f) != 0.f) //No hit == sees light
    {
        value *= 0.2f;
    }
    
    vec3 col = vec3(value * 0.85f, value * 0.85f, value * 0.75f); //sun
    col += vec3(0.05f, 0.05f, 0.075f); //ambient
    
    //Phong
    vec3 refle = normalize( (normal * 2.f * (dot(normal, lightDir))) - lightDir);
    float spec = pow(max(dot(viewDir, refle), 0.f), 2.f);
    col.xyz += spec * 0.2f;
    
    //Return result
    return clamp(col, 0.f, 1.f);
}

//Creates the look at matrix for given cam pos and a target to look towards
mat4 LookAt(vec3 camPos, vec3 target)
{
    vec3 forward = normalize(target - camPos);
    vec3 right = normalize(cross(vec3(0.f, 1.f, 0.f), forward));
    vec3 up = normalize(cross(forward, right));
    
    return mat4(
        vec4(right, 0.f),
        vec4(up, 0.f),
        vec4(forward, 0.f),
        vec4(camPos, 1.f));
}

//The main program
void main(void)
{
    //Readjust fragcoords to have 0,0 in the middle
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    
    //Mouse remapped to -1, 1
    vec2 mouse = ((mouse*resolution.xy.xy-0.5f*resolution.xy)/resolution.xy) * 2.f;

    //Setup ray
    const float camDist = -2.5f;
    vec3 camPos = vec3(0.f, 0.f, 0.f)
        + vec3(sin(-mouse.x * PI), -mouse.y, cos(-mouse.x * PI)) * camDist;
    vec3 camTarget = vec3(0.f, 0.f, 0.f);
    
    //Direction of the ray for this fragment, rotated by the LookAt matrix
    vec3 dir = (LookAt(camPos, camTarget) * normalize(vec4(uv, 1.f, 0.f))).xyz;
    
    //March and obtain colour if there is a hit
    vec3 col = vec3(0.f, 0.f, 0.f);
    float dist = DoMarch(dir, camPos);
    if(dist != 0.f)
    {
        vec3 pos = camPos + dir * dist;
        vec3 viewDir = normalize(pos - camPos);
        col = DoLight(pos , viewDir);
    }
    
    //Display result
    glFragColor = vec4(col, 1.0);
}
