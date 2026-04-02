#version 420

// original https://www.shadertoy.com/view/tlcfWX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// AO (Ambient Occlusion) - by moranzcw - 2021
// Email: moranzcw@gmail.com
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define Epsilon 1e-2
#define PI 3.14159265359
#define Samples 48.0
#define AOradius 1.2

float seed = 0.0;
float rand() 
{
    return fract(sin(seed++)*43758.5453123);
}

struct Ray 
{ 
    vec3 origin, direction;
};

struct Sphere 
{
    float radius;
    vec3 position;
};

Sphere spheres[4];

void initSpheres()
{
    spheres[0] = Sphere(0.5, vec3(-1.7, 0.5, -1.6));
    spheres[1] = Sphere(1.0, vec3(1.8, 1.0, -0.5));
    spheres[2] = Sphere(2.0, vec3(0.0, 2.0, -2.8));
    spheres[3] = Sphere(1000.0, vec3(0.0, -1000.0, 0.0));
}

float intersect(Sphere sphere, Ray ray)
{
    vec3 op = sphere.position - ray.origin;
    float t1, t2 = Epsilon;
    float b = dot(op, ray.direction);
    float det = b * b - dot(op, op) + sphere.radius * sphere.radius;
    
    if (det < 0.0)
        return 0.0;
    else
        det = sqrt(det);
    
    t1 = b - det;
    t2 = b + det;
    if(t1 > Epsilon)
        return t1;
    if(t2 > Epsilon)
        return t2;
    return 0.0;
}

Ray cameraRay(vec3 camPosition, vec3 lookAt)
{
    vec2 uv = 2. * gl_FragCoord.xy / resolution.xy - 1.;

    vec3 cz = normalize(lookAt - camPosition);
    vec3 cx = normalize(cross(cz, vec3(0.0, 1.0, 0.0)));
    vec3 cy = normalize(cross(cx, cz));
    
    return Ray(camPosition, normalize(0.53135 * (resolution.x/resolution.y*uv.x * cx + uv.y * cy) + cz));
}

vec3 semiSpherePoint(vec3 normal)
{
    float theta = 2.0 * PI * rand();
    float cosPhi = rand();
    
    vec3 zAxis = normal;
    vec3 xAxis = normalize(cross(normal, vec3(1.0, 0.0, 0.0)));
    vec3 yAxis = normalize(cross(normal, xAxis));
    
    vec3 x = cos(theta) * xAxis;
    vec3 y = sin(theta) * yAxis;
    vec3 z = cosPhi * zAxis;
    
    return normalize(x + y + z);
}

float AO(vec3 point, vec3 normal)
{
    float count = Samples;
    for(float i=0.0; i<Samples; i++)
    {
        Ray ray = Ray(point, semiSpherePoint(normal));
        
        float t = 1e10;
        for(int i=0; i<4; i++)
        {
            float temp = intersect(spheres[i], ray);
            t = step(Epsilon, temp) * min(temp, t) + step(temp, Epsilon) * t;
        }
        count -= step(t, AOradius) * smoothstep(AOradius, 0.0, t);
    }
    return count / Samples;
}

vec3 background(float yCoord) 
{        
    return mix(vec3(0.1515, 0.2375, 0.5757), vec3(0.0546, 0.0898, 0.1953), yCoord);
}

void main(void)
{
    seed = time + 0.001 * gl_FragCoord.xy.x * gl_FragCoord.xy.y;
    initSpheres();
    
    // camera ray
    vec3 camPosition = mix(vec3(-2.0, 3.0, 6.0), vec3(2.0, 3.0, 6.0), sin(time*0.3));
    vec3 lookAt = vec3(0.0, 2.0, 0.0);
    Ray ray = cameraRay(camPosition, lookAt);
    
    vec3 color=vec3(0.0);
    
    // intersect
    float t = 1e10;
    int id;
    float hitAnything = 0.0;
    for(int i=0; i<4; i++)
    {
        float temp = intersect(spheres[i], ray);
        if(temp > Epsilon && temp < t)
        {
            t = temp;
            id = i;
            hitAnything = 1.0;
        }
    }
    
    // AO
    float ao = 0.0;
    if(hitAnything > 0.0)
    {
        vec3 point = ray.origin + t * ray.direction;
        vec3 normal = normalize(point - spheres[id].position);
        ao = AO(point, normal);
    }
    
    color = (1.0-hitAnything) * background(gl_FragCoord.xy.y/resolution.y) + hitAnything * vec3(0.9) * ao;
    
    color = pow(color,vec3(1.0/2.2)); // gamma
    glFragColor = vec4(color, 1.0);
}
