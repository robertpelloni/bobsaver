#version 420

// original https://www.shadertoy.com/view/MdSSRc

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

//// Structs
struct Material
{
    vec3 col;
    bool refl;
    bool refr;
    float n;
    float roughness;
    float fresnel;
    float density;
};

struct Sphere
{
    vec3 pos;
    float r;
    Material mat;
    int hit_id;
};

struct Plane
{
    vec3 pos;
    vec3 norm;
    Material mat;
    int hit_id;
};

struct Light
{
    vec3 pos;
    vec3 col;
    float intensity;
};

struct Ray
{
    vec3 pos;
    vec3 dir;
    float n;
};

struct Intersection
{
    vec3 pos;
    vec3 norm;
    float dist;
    Material mat;
    int hit_id;
    int hit_type;
};

//// Local variables
vec3 camera_pos = vec3(0.0, 2.5, 10.0);
vec3 camera_eye = vec3(0.0, 0.0, -1.0);
vec3 camera_up = vec3(0.0, 1.0, 0.0);
const int N = 3;
const float EPSILON = 1e-3;
const float PI = 3.14159;
const int SPHERES = 14;
const int PLANES = 6;
const int LIGHTS = 3;

//// Materials
Material mat_white_diffuse = Material(vec3(1.0, 1.0, 1.0), false, false, 1.0, 0.12, 1.0, 0.9);
Material mat_red_diffuse = Material(vec3(1.0, 0.0, 0.0), false, false, 1.0, 0.12, 1.0, 0.9);
Material mat_green_diffuse = Material(vec3(0.0, 1.0, 0.0), false, false, 1.0, 0.12, 1.0, 0.9);
Material mat_blue_diffuse = Material(vec3(0.0, 0.0, 1.0), false, false, 1.0, 0.12, 1.0, 0.9);
Material mat_white_reflective = Material(vec3(1.0, 1.0, 1.0), true, false, 1.0, 0.12, 1.0, 0.50);
Material mat_black_reflective = Material(vec3(0.0, 0.0, 0.0), true, false, 1.0, 0.50, 0.25, 0.25);
Material mat_red_reflective = Material(vec3(1.0, 0.0, 0.0), true, false, 1.0, 0.12, 1.0, 0.75);
Material mat_green_reflective = Material(vec3(0.0, 1.0, 0.0), true, false, 1.0, 0.12, 1.0, 0.9);
Material mat_blue_reflective = Material(vec3(0.0, 0.0, 1.0), true, false, 1.0, 0.12, 1.0, 0.82);
Material mat_yellow_reflective = Material(vec3(1.0, 1.0, 0.0), true, false, 1.0, 0.12, 1.0, 0.75);
Material mat_purple_reflective = Material(vec3(1.0, 0.0, 1.0), true, false, 1.0, 0.12, 1.0, 0.82);
Material mat_cyan_reflective = Material(vec3(0.0, 1.0, 1.0), true, false, 1.0, 0.12, 1.0, 0.50);
Material mat_white_refractive = Material(vec3(1.0, 1.0, 1.0), false, true, 1.0, 0.12, 1.0, 0.25);
Material mat_black_refractive = Material(vec3(0.0, 0.0, 0.0), false, true, 1.0, 0.50, 0.25, 0.25);
Material mat_red_refractive = Material(vec3(1.0, 0.0, 0.0), false, true, 1.25, 0.12, 1.0, 0.50);
Material mat_green_refractive = Material(vec3(0.0, 1.0, 0.0), false, true, 1.52, 0.12, 1.0, 0.62);
Material mat_blue_refractive = Material(vec3(0.0, 0.0, 1.0), false, true, 1.0, 0.12, 1.0, 0.50);
Material mat_purpe_refractive = Material(vec3(0.0, 1.0, 1.0), false, true, 1.0, 0.12, 1.0, 0.50);
Material mat_cyan_refractive = Material(vec3(0.0, 1.0, 1.0), false, true, 1.0, 0.12, 1.0, 0.37);

Material mat_floor = Material(vec3(0.5, 0.0, 1.0), true, false, 1.0, 0.12, 0.75, 0.9);
Material mat_ceiling = Material(vec3(1.0, 0.75, 0.0), false, false, 1.0, 0.12, 0.75, 0.9);
Material mat_wall0 = Material(vec3(0.67, 1.0, 0.0), true, false, 1.0, 0.12, 0.75, 0.95);
Material mat_wall1 = Material(vec3(1.0, 0.0, 0.0), true, false, 1.0, 0.12, 0.75, 0.95);

//// Arrays
Sphere scene_spheres[SPHERES];
Plane scene_planes[PLANES];
Light scene_lights[LIGHTS];

//// Init the scene
void sceneInit()
{
    scene_spheres[0] = Sphere(vec3(0.0, 2.0, -10.0), 2.0, mat_black_reflective, 10);
    scene_spheres[1] = Sphere(vec3(7.5, 2.0, -10.0), 2.0, mat_white_reflective, 11);
    scene_spheres[2] = Sphere(vec3(15.0, 2.0, -10.0), 2.0, mat_red_reflective, 12);
    scene_spheres[3] = Sphere(vec3(-7.5, 2.0, -10.0), 2.0, mat_green_reflective, 13);
    scene_spheres[4] = Sphere(vec3(-15.0, 2.0, -10.0), 2.0, mat_blue_reflective, 14);
    scene_spheres[5] = Sphere(vec3(0.0, 3.0, 30.0), 3.0, mat_cyan_reflective, 15);
    scene_spheres[6] = Sphere(vec3(7.5, 2.0, 30.0), 2.0, mat_yellow_reflective, 16);
    scene_spheres[7] = Sphere(vec3(15.0, 2.0, 30.0), 2.0, mat_purple_reflective, 17);
    scene_spheres[8] = Sphere(vec3(-7.5, 2.0, 30.0), 2.0, mat_cyan_reflective, 18);
    scene_spheres[9] = Sphere(vec3(-15.0, 2.0, 30.0), 2.0, mat_purpe_refractive, 19);
    scene_spheres[10] = Sphere(vec3(10.0, 2.0, 10.0), 2.0, mat_cyan_refractive, 20);
    scene_spheres[11] = Sphere(vec3(-10.0, 2.0, 10.0), 2.0, mat_purpe_refractive, 21);
    scene_spheres[12] = Sphere(vec3(16.0, 2.0, 10.0), 1.0, mat_green_diffuse, 22);
    scene_spheres[13] = Sphere(vec3(-16.0, 2.0, 10.0), 1.0, mat_blue_diffuse, 23);
    
    scene_planes[0] = Plane(vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), mat_floor, 25);
    scene_planes[1] = Plane(vec3(0.0, 10.0, 0.0), vec3(0.0, -1.0, 0.0), mat_ceiling, 51);
    scene_planes[2] = Plane(vec3(0.0, 0.0, -25.0), vec3(0.0, 0.0, 1.0), mat_wall0, 52);
    scene_planes[3] = Plane(vec3(0.0, 0.0, 50.0), vec3(0.0, 0.0, -1.0), mat_wall0, 53);
    scene_planes[4] = Plane(vec3(-50.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0), mat_wall1, 54);
    scene_planes[5] = Plane(vec3(50.0, 0.0, 0.0), vec3(-1.0, 0.0, 0.0), mat_wall1, 55);
    
    scene_lights[0] = Light(vec3(0.0, 5.0, 10.0), vec3(1.0, 1.0, 1.0), 0.50);
    scene_lights[1] = Light(vec3(16.0, 5.0, 10.0), vec3(0.0, 0.5, 1.0), 0.37);
    scene_lights[2] = Light(vec3(-16.0, 5.0, 10.0), vec3(0.5, 0.0, 1.0), 0.37);
}

//// Animate the scene
void sceneAnim()
{
    camera_pos.x = 5.0 * cos(time * 0.5);
    camera_pos.y = 2.75 + 2.5 * cos(time * 0.37);
    camera_pos.z = 10.0 + 10.0 * cos(time * 0.5);
    camera_eye.x = cos(time * 0.37);
    camera_eye.z = sin(time * 0.37);
    
    scene_lights[0].pos.x = 25.0 * cos(time * 0.25);
    
    scene_lights[1].pos.x = 16.0 + 5.0 * cos(time * 0.12);
    
    scene_lights[2].pos.x = -16.0 + 5.0 * sin(time * 0.20);
    
    scene_lights[1].pos.z = 10.0 + 12.5 * cos(time * 0.12);
    
    scene_lights[2].pos.z = -10.0 + 12.5 * sin(time * 0.20);
}

//// Ray -> Sphere intersection check method
bool iSphere(inout Ray r, in Sphere s, inout Intersection x)
{
    if (x.hit_id == s.hit_id)
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
    
    if (t < EPSILON || t > x.dist)
    {
        return false;
    }
    
    x.pos = r.pos + r.dir * t;
    x.norm = normalize(x.pos - s.pos);
    x.dist = t;
    x.mat = s.mat;
    x.hit_id = s.hit_id;
    x.hit_type = 1;
    
    return true;
}

//// Ray -> Plane intersection check method
bool iPlane(inout Ray r, in Plane p, inout Intersection x)
{
    if (x.hit_id == p.hit_id)
    {
        return false;
    }
    
    vec3 P;
    float d, t;
    
    P = p.pos - r.pos;
    d = dot(p.norm, r.dir);
    t = dot(P, p.norm) / d;
    
    if (t < EPSILON || t > x.dist)
    {
        return false;
    }
    
    x.pos = r.pos + r.dir * t;
    x.norm = normalize(p.norm);
    x.dist = t;
    x.mat = p.mat;
    x.hit_id = p.hit_id;
    x.hit_type = 2;
    
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

//// Test if a given ray and a light source has something intersectable between them or not
bool shadow(in Ray r, in Intersection x, in Light l)
{
    vec3 L = l.pos - x.pos;
    float distance = length(L);
    L = normalize(L);
    Ray shadowRay;
    Intersection lx = x;
    lx.dist = 1e6;
    shadowRay.pos = lx.pos;
    shadowRay.dir = L;
    iScene(shadowRay, lx);
    if (lx.dist < 1e6 && lx.dist < distance)
        return true;
    return false;
}

//// Color shading
//// References:
//// http://content.gpwiki.org/index.php/D3DBook:%28Lighting%29_Cook-Torrance
//// http://ruh.li/GraphicsCookTorrance.html
vec3 shadeCookTorrance(in Ray r, in Intersection x, in Light l)
{
    // Specify some variables
    float R = x.mat.roughness;
    float RR = R * R;
    if (R < EPSILON)
    {
        R = EPSILON;
        RR = R * R;
    }
    float F = x.mat.fresnel * l.intensity;
    float K = x.mat.density;
    vec3 VD = -r.dir;
    vec3 L = normalize(l.pos - x.pos);
    vec3 H = normalize(VD + L);
    float NdotL = clamp(dot(x.norm, L), 0.0, 1.0);
    float NdotH = clamp(dot(x.norm, H), 0.0, 1.0);
    float NdotV = clamp(dot(x.norm, VD), 0.0, 1.0);
    float VdotH = clamp(dot(H, VD), 0.0, 1.0);
    
    // Geometric attenuation
    float NH2 = 2.0 * NdotH / VdotH;
    float geo_b = NH2 * NdotV;
    float geo_c = NH2 * NdotL;
    float geo = min(1.0, min(geo_b, geo_c));
    
    // Roughness (Beckmann distribution function)
    float r1 = 1.0 / (4.0 * RR * pow(NdotH, 4.0));
    float r2 = (NdotH * NdotH - 1.0) / (RR * NdotH * NdotH);
    float roughness = r1 * exp(r2);
    
    // Fresnel
    float fresnel = pow(1.0 - VdotH, 5.0);
    fresnel *= (1.0 - F);
    fresnel += F;
    
    // Color calculations
    vec3 color_spec = vec3(0.0);
    if (NdotV * NdotL <= -EPSILON || NdotV * NdotL >= EPSILON)
        color_spec = vec3(fresnel * geo * roughness) / (NdotV * NdotL);
    vec3 color_final = NdotL * ((1.0 - K) * color_spec * l.intensity + K * l.intensity * x.mat.col) * l.col;
    return color_final;
}

//// Raytracing, using simple iterative recursion including reflections and refractions
vec3 trace(in Ray r)
{
    // Init colors
    vec3 color_null = vec3(0.0);
    vec3 color_ambient = vec3(0.1);
    vec3 color_final = color_null;
    
    // Init intersections
    Intersection iSection;
    Intersection iSectionInit;
    iSection.dist = 1e6;
    
    // Init other stuff
    float lastDensity = 1.0;
    
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
        
        // If the ray didn't intersect with anything,
        // no need for further recursion so break out from the loop
        if (iSection.dist >= 1e6)
        {
            break;
        }
        
        // Iterate through each lightsource and calculate the color
        for (int i = 0; i < LIGHTS; i++)
        {
            if (shadow(r, iSection, scene_lights[i]) == false)
            {
                vec3 color_temp = vec3(0.0);
                color_temp = smoothstep(vec3(0.0), vec3(1.0), shadeCookTorrance(r, iSection, scene_lights[i]));
                if (n > 0)
                    color_temp *= 1.0 - iSectionInit.mat.density;
                color_final += color_temp;
            }
        }
        
        // If the ray hit a diffuse surface,
        // no need for further recursion so break out from the loop
        if (iSection.mat.refl == false && iSection.mat.refr == false)
        {
            break;
        }
        
        // If the ray hit a reflective surface; reflect it (duh)
        if (iSection.mat.refl)
        {
            float NdotV = dot(iSection.norm, r.dir);
            vec3 refl = normalize(2.0 * iSection.norm * NdotV - r.dir);
            r.pos = iSection.pos;
            r.dir = -refl;
        }
        
        // If the ray hit a refractive surface, refract it
        if (iSection.mat.refr)
        {
            vec3 N = iSection.norm;
            float n = 1.0;
            if (r.n <= 1.0)
                n = r.n / iSection.mat.n;
               else
                n = iSection.mat.n / r.n;
            float NdotV = dot(N, r.dir);
            float cosT = 1.0 - n * n * (1.0 - NdotV * NdotV);
            if (cosT > 0.0)
            {
                vec3 T = normalize((n * r.dir) + (n * NdotV - sqrt(cosT)) * N);
                r.pos = iSection.pos;
                r.dir = T;
                if (r.n <= 1.0)
                    r.n = iSection.mat.n;
                else
                    r.n = 1.0;
            }
        }
        
        // Reset the intersection distance for a new round
        iSection.dist = 1e6;
    }
    
    // Return the final color
    return color_final;
}

void main()
{
    // Initialize the scene objects at first
    sceneInit();
    // Animate the scene
    sceneAnim();
    // Recalculate camera
    vec3 camera_right = normalize(cross(camera_eye, camera_up));
    // Get the current fragment's coordinate and normalize it to a range of 0 - 1
    float aspectRatio = resolution.x / resolution.y;
    float x_norm = ((gl_FragCoord.x - resolution.x / 2.0) / resolution.x) * aspectRatio;
    float y_norm = (gl_FragCoord.y - resolution.y / 2.0) / resolution.y;
    // Generate a Ray with origin pos and direction dir
    Ray primaryRay;
    primaryRay.pos = camera_pos;
    primaryRay.dir = normalize(((camera_right * x_norm) + (camera_up * y_norm) + (primaryRay.pos) + (camera_eye)) - primaryRay.pos);
    primaryRay.n = 1.0;
    // Calculate the color of the current fragment by casting a ray at the pixel's direction
    glFragColor = vec4(trace(primaryRay), 1.0);
}
