#version 420

// original https://www.shadertoy.com/view/WsySzw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Rotation of the planet
mat3 planetRotation;

struct Ray {
    vec3 origin; // Origin of the ray
    vec3 direction; // Direction of the ray, assume to be normalized
};
    
struct Material {
    vec3 color;
};
    
const Material waterMaterial = Material(vec3(0.0, 0.41, 0.58));
const Material groundMaterial = Material(vec3(0.1, 0.54, 0.1));
const Material dirtMaterial = Material(vec3(0.6, 0.46, 0.32));
const Material snowMaterial = Material(vec3(1.0, 1.0, 1.0));

Material mixMaterials(Material x, Material y, float a) {
    vec3 color = mix(x.color, y.color, a);
    return Material(color);
}

// Returns a point at distance units along the ray.
vec3 getPoint(Ray ray, float t) {
    return ray.origin + t * ray.direction;
}

float hash(float p) { p = fract(p * 0.011); p *= p + 7.5; p *= p + p; return fract(p); }

float noise(vec3 x) {
    const vec3 step = vec3(110, 241, 171);

    vec3 i = floor(x);
    vec3 f = fract(x);
 
    // For performance, compute the base input to a 1D hash from the integer part of the argument and the 
    // incremental change to the 1D based on the 3D -> 1D wrapping
    float n = dot(i, step);

    vec3 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix( hash(n + dot(step, vec3(0, 0, 0))), hash(n + dot(step, vec3(1, 0, 0))), u.x),
                   mix( hash(n + dot(step, vec3(0, 1, 0))), hash(n + dot(step, vec3(1, 1, 0))), u.x), u.y),
               mix(mix( hash(n + dot(step, vec3(0, 0, 1))), hash(n + dot(step, vec3(1, 0, 1))), u.x),
                   mix( hash(n + dot(step, vec3(0, 1, 1))), hash(n + dot(step, vec3(1, 1, 1))), u.x), u.y), u.z);
}

// Fractal Brownian Motion
float fbm6(vec3 x) {
    const int noise_octaves_count = 6;
    float v = 0.0;
    float a = 0.5;
    vec3 shift = vec3(100);
    for (int i = 0; i < noise_octaves_count; ++i) {
        v += a * noise(x);
        x = x * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

float pow3(float f) {
    return f * f * f;
}

// Signed distance function describing the scene.
float scene(vec3 p, out Material material) {
    vec3 surfaceLocation = normalize(p);
    float elevation = 1.0 - fbm6(surfaceLocation * 4.0);
    elevation = pow3(elevation) * 0.25 + 0.8;
    
    vec3 normal = normalize(cross(dFdx(surfaceLocation * elevation),
                                  dFdy(surfaceLocation * elevation)));
    
    const float water = 0.85;
    const float forestLine = 0.88;
    const float snowLine = 0.9;

    float baseWaterHeight = -(water - elevation) / 5.0 + water;
    float wave = (sin(time + 20. * surfaceLocation.x) + cos(time + 20. * surfaceLocation.y))
        * (water - elevation) / 10.;
    float waterHeight = baseWaterHeight + wave;
    
    
    if (elevation < waterHeight) {
        material = waterMaterial;
        return length(p) - waterHeight;
    } 
    
    if (elevation < forestLine) {
        material = groundMaterial;
    } else if (elevation < snowLine) {
        material = mixMaterials(groundMaterial, dirtMaterial, (elevation - forestLine) / (snowLine - forestLine));
    } else {
        material = snowMaterial;
    }
    
    float radius = elevation;
    return length(p) - radius;
}

// normal function from Graphics Codex
vec3 normal(vec3 p) {
    p = normalize(p);
    const float e = 1e-2;
    const vec3 u = vec3(e, 0, 0);
    const vec3 v = vec3(0, e, 0);
    const vec3 w = vec3(e, 0, e);
    
    Material mat;
    
    return normalize(vec3(
        scene(p + u, mat) - scene(p - u, mat),
        scene(p + v, mat) - scene(p - v, mat),
        scene(p + w, mat) - scene(p - w, mat)));
}

const vec3 eye = vec3(0.0, 0.0, 5.0);

vec3 blinnPhong(vec3 pos, vec3 normal, vec3 eye, vec3 color) {
    vec3 lightPos = vec3(0.0, 0.0, -5.0);
    
    // ambient
    vec3 ambient = 0.4 * color;
    // diffuse
    vec3 lightDir = normalize(lightPos - pos);
    float diff = max(dot(lightDir, normal), 0.0);
    vec3 diffuse = diff * color;
    // specular
    vec3 viewDir = normalize(eye - pos);
    vec3 reflectDir = reflect(-lightDir, normal);
    vec3 halfwayDir = normalize(lightDir + viewDir);  
    float spec = pow(max(dot(normal, halfwayDir), 0.0), 32.0);
    vec3 specular = vec3(0.3) * spec; // assuming bright white light color
    
    return ambient + diffuse + specular;
}

/*
 * Trace the ray
 * Returns true if something was hit
 * ray: the ray to trace
 * maxDist: the max distance before giving up
 * [out] radiance: the radiance of the intersection point
 * [out] distance: the distance from the ray to the closest intersection surface if hit
 */
bool traceRay(Ray ray, float maxDist, out vec3 radiance, out float distance) {
    const int maxIteration = 50;
    const float epsilon = 1e-3;

    float t = 0.;
    for (int i = 0; i < maxIteration; ++i) {
        vec3 p = planetRotation * getPoint(ray, t);
        Material mat;
        float dist = scene(p, mat);
        if (dist < epsilon) {
            distance = dist;
            radiance = blinnPhong(p, normal(p), eye, mat.color);
            return true;
        }
        t += dist;
        if (t >= maxDist) {
            return false;
        }
    }
    return false;
}            

vec3 rayDirection(float fieldOfView, vec2 size) {
    vec2 xy = gl_FragCoord.xy - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}

void main(void)
{
    float yaw   = -(0.1 * time);
    float pitch = ((resolution.y * 0.3) / resolution.y) * 2.5;
     planetRotation =
        mat3(cos(yaw), 0, -sin(yaw), 0, 1, 0, sin(yaw), 0, cos(yaw)) *
        mat3(1, 0, 0, 0, cos(pitch), sin(pitch), 0, -sin(pitch), cos(pitch));
    
    const float maxDist = 100.;
    
    vec3 dir = rayDirection(45.0, resolution.xy);
    Ray ray = Ray(eye, normalize(dir));
    
    float dist;
    vec3 radiance;
    if (traceRay(ray, maxDist, radiance, dist)) {
        glFragColor = vec4(radiance, 1.0);
        return;
    }
    
    // Didn't hit anything
    glFragColor = vec4(0.0, 0.0, 0.0, 0.0);
}
