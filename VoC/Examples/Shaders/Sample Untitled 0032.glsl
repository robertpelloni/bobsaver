#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//// Structs
struct Sphere
{
    vec3 pos;
    vec3 col;
    float r;
    int material;
    int id;
};

struct Plane
{
    vec3 pos;
    vec3 norm;
    vec3 col;
    int material;
    int id;
};

struct Light
{
    vec3 pos;
    vec3 col;
    float intensity_diff;
    float intensity_spec;
};

struct Ray
{
    vec3 pos;
    vec3 dir;
};

struct Intersection
{
    vec3 pos;
    vec3 norm;
    float dist;
    vec3 col;
    Sphere sphere;
    Plane plane;
    int material;
    int id;
    int type;
};

//// Variables
const int N = 6;
const int SPHERES = 5;
const int PLANES = 6;
const int LIGHTS = 4;
const float PI = 3.14;

vec3 camera_pos = vec3(0.0, 2.5, 0.0);
vec3 camera_eye = vec3(0.0, 0.0, -1.0);

//// Arrays
Sphere scene_spheres[SPHERES];
Plane scene_planes[PLANES];
Light scene_lights[LIGHTS];

//// Scene initialization method, why can't I init arrays here in shadertoy 'normally'?
//// Is that due to some compatibility stuff or what?
void initScene()
{
    scene_spheres[0] = Sphere(vec3(0.0, 1.0, -5.0), vec3(1.0, 1.0, 1.0), 1.0, 2, 100);
    scene_spheres[1] = Sphere(vec3(2.5, 1.0, -7.5), vec3(1.0, 1.0, 1.0), 1.0, 1, 101);
    scene_spheres[2] = Sphere(vec3(-2.5, 1.0, -7.5), vec3(0.0, 1.0, 0.0), 1.0, 0, 102);
    scene_spheres[3] = Sphere(vec3(-7.5, 1.0, -5.0), vec3(0.0, 0.5, 1.0), 1.0, 0, 109);
    scene_spheres[4] = Sphere(vec3(0.0, 0.0, 10.0), vec3(0.25, 0.75, 1.0), 2.0, 1, 110);
    
    scene_planes[0] = Plane(vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(1.0, 1.0, 1.0), 0, 103);
    scene_planes[1] = Plane(vec3(0.0, 20.0, 0.0), vec3(0.0, -1.0, 0.0), vec3(1.0, 1.0, 1.0), 1, 104);
    scene_planes[2] = Plane(vec3(0.0, 0.0, -20.0), vec3(0.0, 0.0, 1.0), vec3(1.0, 1.0, 1.0), 1, 105);
    scene_planes[3] = Plane(vec3(0.0, 0.0, 20.0), vec3(0.0, 0.0, -1.0), vec3(1.0, 1.0, 1.0), 1, 106);
    scene_planes[4] = Plane(vec3(-20.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0), 1, 107);
    scene_planes[5] = Plane(vec3(20.0, 0.0, 0.0), vec3(-1.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0), 1, 108);
    
    scene_lights[0] = Light(vec3(0.0, 5.0, 0.0), vec3(1.0, 1.0, 1.0), 2.5, 2.5);
    scene_lights[1] = Light(vec3(0.0, 5.0, 5.0), vec3(1.0, 1.0, 1.0), 2.0, 2.0);
    scene_lights[2] = Light(vec3(6.0, 1.0, -5.0), vec3(1.0, 0.0, 1.0), 2.0, 2.0);
    scene_lights[3] = Light(vec3(-6.0, 1.0, 0.0), vec3(0.0, 0.5, 1.0), 2.0, 2.0);
}

//// Animate the scene
void animScene()
{
    scene_lights[0].pos.x = 5.0 * cos(time);
    
    camera_pos.x = 7.5 * cos(time * 0.5);
    camera_pos.y = 1.25 + sin(time);
    
    camera_eye.x = cos(time * 0.25);
    camera_eye.z = sin(time * 0.25);
}

//// Ray -> Sphere intersection check method
bool iSphere(in Ray r, in Sphere s, inout Intersection x)
{
    if (x.id == s.id)
    {
        return false;
    }
    
    vec3 S;
    float squaredDistance;
    float b, d, t;
    
    S = r.pos - s.pos;
    squaredDistance = dot(S, S);
    if (squaredDistance <= s.r)
    {
        return false;
    }
    b = dot(-S, r.dir);
    d = (b * b) - dot(S, S) + (s.r * s.r);
    if (d < 0.0)
    {
        return false;
    }
    d = sqrt(d);
    t = b - d;
    if (t < 1e-5 || t > x.dist)
    {
        return false;
    }
    x.pos = r.pos + r.dir * t;
    x.norm = normalize(x.pos - s.pos);
    x.dist = t;
    x.col = s.col;
    x.sphere = s;
    x.material = s.material;
    x.id = s.id;
    x.type = 1;
    return true;
}

//// Ray -> Plane intersection check method
bool iPlane(in Ray r, in Plane p, inout Intersection x)
{
    if (x.id == p.id)
    {
        return false;
    }
    
    vec3 P;
    float d, t;
    
    P = p.pos - r.pos;
    d = dot(p.norm, r.dir);
    t = dot(P, p.norm) / d;
    if (t < 1e-5 || t > x.dist)
    {
        return false;
    }
    x.pos = r.pos + r.dir * t;
    x.norm = p.norm;
    x.dist = t;
    x.col = p.col;
    x.plane = p;
    x.material = p.material;
    x.id = p.id;
    x.type = 2;
    return true;
}

//// Method to test ray intersection with all scene objects
void iScene(in Ray r, inout Intersection x)
{
    // Intersect scene spheres
    for (int i = 0; i < SPHERES; i++)
    {
        iSphere(r, scene_spheres[i], x);
    }
        
    // Intersect scene planes
    for (int i = 0; i < PLANES; i++)
    {
        iPlane(r, scene_planes[i], x);
    }
}

//// Method to test ray intersection with all scene spheres
void iSceneSpheres(in Ray r, inout Intersection x)
{
    // Intersect scene spheres
    for (int i = 0; i < SPHERES; i++)
    {
        iSphere(r, scene_spheres[i], x);
    }
}

//// Simple phong shading, not sure if this is 'correct' though, probably not...
void phong(in Ray r, in Intersection x, in Light l, inout vec3 color_diffuse, inout vec3 color_specular)
{
    bool inShadow = false;
    vec3 L = l.pos - x.pos;
    float distance = length(L);
    L = normalize(L);
    Ray shadowRay;
    Intersection lx = x;
    lx.dist = 1e6;
    shadowRay.pos = lx.pos;
    shadowRay.dir = L;
    iSceneSpheres(shadowRay, lx);
    if (lx.dist < 1e6 && lx.dist < distance)
        inShadow = true;
    if (inShadow == false)
    {
        float NdotL = clamp(dot(x.norm, L), 0.0, 1.0);
        color_diffuse += (l.col * NdotL * l.intensity_diff) / distance;
        vec3 L_inv = x.pos - l.pos;
        vec3 R = normalize(2.0 * x.norm * dot(x.norm, L_inv) - L_inv);
        float RdotV = clamp(dot(R, r.dir), 0.0, 1.0);
        color_specular += (vec3(1.0) * pow(RdotV, 25.0) * l.intensity_spec) / distance;
    }
}

//// Raytracing, using simple iterative recursion including reflections and refractions
vec3 trace(in Ray r)
{
    // Init colors
    vec3 color_null = vec3(0.0);
    vec3 color_diffuse = color_null;
    vec3 color_specular = color_null;
    vec3 color_final = color_null;
    
    // Init intersections
    Intersection iSectionInit;
    Intersection iSection;
    iSection.dist = 1e6;
    
    // Recursively trace the scene
    for (int n = 0; n < N; n++)
    {
        // Intersect the ray with all scene objects
        iScene(r, iSection);
        
        // Get the information of the first hit surface
        if (n == 0)
        {
            iSectionInit = iSection;
        }
        
        // If the ray hit a diffuse surface or didn't intersect,
        // no need for further recursion so break out from the loop
        if (iSection.dist >= 1e6 || iSection.material == 0)
        {
            break;
        }
        
        // If the ray hit a reflective surface; reflect it (duh)
        if (iSection.material == 1)
        {
            float NdotV = dot(iSection.norm, r.dir);
            vec3 refl = normalize(2.0 * iSection.norm * NdotV - r.dir);
            r.pos = iSection.pos;
            r.dir = -refl;
        }
        
        // If the ray hit a refractive surface, refract it
        if (iSection.material == 2)
        {
            float NdotV = dot(iSection.norm, r.dir);
            float nIn;
            vec3 refr;
            if (NdotV < 0.0)
            {
                float nIn = 1.0 / 1.52;
            }
            else
            {
                float nIn = 1.52 / 1.0;
            }
            float c = sqrt(1.0 - (nIn * nIn) * (1.0 - (NdotV * NdotV)));
            refr = r.dir * nIn + iSection.norm * (nIn * NdotV - c);
            r.pos = iSection.pos;
            r.dir = normalize(refr);
        }
        
        // Reset the material of intersection for a new round
        iSection.dist = 1e6;
        iSection.material = 0;
    }
    
    // Calculate final color based on each light source and so on...
    if (iSectionInit.dist < 1e6)
    {
        for (int i = 0; i < LIGHTS; i++)
        {
            phong(r, iSection, scene_lights[i], color_diffuse, color_specular);
        }
        color_final += color_diffuse;
        color_final *= iSectionInit.col;
        color_final *= iSection.col;
        color_final += color_specular;
        return color_final;
    }
    
    // Return a null color if no intersection happened
    return color_null;
}

//// Main method
void main(void)
{
    // Initialize the scene
    initScene();
    
    // Animate the scene
    animScene();
    
    // Initialize camera
    vec3 camera_up = vec3(0.0, 1.0, 0.0);
    vec3 camera_right = normalize(cross(camera_eye, camera_up));
    
    // Calculate aspect ratio + normalize screenspace fragment coordinates
    float ar = resolution.x / resolution.y;
    float x_norm = ((gl_FragCoord.x - resolution.x / 2.0) / resolution.x) * ar;
    float y_norm = (gl_FragCoord.y - resolution.y / 2.0) / resolution.y;
    
    // Generate a ray
    Ray primaryRay;
    primaryRay.pos = camera_pos;
    primaryRay.dir = normalize(((camera_right * x_norm) + (camera_up * y_norm) + (primaryRay.pos) + (camera_eye)) - primaryRay.pos);
    
    // Raytrace!
    glFragColor = vec4(trace(primaryRay), 1.0);
}
