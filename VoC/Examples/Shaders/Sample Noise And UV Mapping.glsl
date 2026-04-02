#version 420

// original https://www.shadertoy.com/view/3dXBRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float FOVY = 3.14159 * 0.25;
const int RAY_STEPS = 256;
const float PI = 3.14159;
const float TWO_PI = 3.14159 * 2.0;
const vec3 matteWhite = vec3(0.85, 0.81, 0.78);
const vec3 matteRed = vec3(0.63, 0.065, 0.05);
const vec3 matteGreen = vec3(0.14, 0.45, 0.091);
vec3 center = vec3(-5.0, 2.0, -1.0);
const vec3 lightPos = vec3(-1.0, 6.5, -15);

//Intersection
struct Intersection
{
    float t;
    vec3 color;
    vec3 p;
    int object; // unique ID for every object
};    

// Box with side lengths b
float cube(vec3 p, vec3 b)
{
  return length(max(abs(p) - b, 0.0));
}

// SquarePlane SDF
float plane(vec3 p, vec4 n)
{
    n = normalize(n);
    return dot(p, n.xyz) + n.w;
}

// Sphere with radius r at center c
float sphere(vec3 p, float r, vec3 c)
{
    return distance(p, c) - r;
}

vec3 palette(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d)
{
    return a + b * cos(6.28318 * (c * t + d));
}

//Worley===============================================
// noise basis function
vec2 noiseBasis(vec2 p) {
    return fract(sin(vec2(dot(p,vec2(127.1, 161.979)),
                          dot(p, vec2(469.73, 837.43))))
                 *28347.4939);
}

// worleyNoise function
float worleyNoise(vec2 uv) {
    uv *= 0.1; //Now the space is 10x10 instead of 1x1. Change this to any number you want.
    vec2 uvInt = floor(uv);
    vec2 uvFract = fract(uv);
    float minDist = 1.0; //Minimum distance initialized to max.
    for(int y = -1; y <= 1; ++y) {
        for(int x = -1; x <= 1; ++x) {
            vec2 neighbor = vec2(float(x), float(y)); //Direction in which neighbor cell lies
            vec2 point = noiseBasis(uvInt + neighbor); //Get the Voronoi centerpoint for the neighboring cell
            
            point = 0.5 + 0.5 * sin(time + 6.2831 * point); // 0 to 1 range

            vec2 diff = neighbor + point - uvFract; //Distance between fragment coord and neighbor’s Voronoi point
            float dist = length(diff);
            minDist = min(minDist, dist);
        }
    }
    return minDist;
}

//FBM===============================================
//sphere 2d mapper
vec2 sphereMapper(vec3 p)
{
    float phi = atan(p.z, p.x);
    if (phi < 0.0) {
        phi += TWO_PI;
    }
    float theta = acos(p.y);
    
    float u = 1.0 - (phi / TWO_PI);
    float v = 1.0 - (theta / PI);

    return (vec2(u, v) + 0.1 * time) / 0.1; // 0 to 1 range
}

//noise basis function
float noiseFBM2D(vec2 n)
{
    return (fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453));
}

//interpNoise2D
float interpNoise2D(float x, float y)
{
    float intX = floor(x);
    float fractX = fract(x);
    float intY = floor(y);
    float fractY = fract(y);

    float v1 = noiseFBM2D(vec2(intX, intY));
    float v2 = noiseFBM2D(vec2(intX + 1.0, intY));
    float v3 = noiseFBM2D(vec2(intX, intY + 1.0));
    float v4 = noiseFBM2D(vec2(intX + 1.0, intY + 1.0));

    float i1 = mix(v1, v2, fractX);
    float i2 = mix(v3, v4, fractX);
    return mix(i1, i2, fractY);
}

//fbm function
float fbm(float x, float y)
{
    float total = 0.0;
    float persistence = 0.5;
    float octaves = 4.0;

    for(float i = 1.0; i <= octaves; i++) {
        float freq = pow(2.0, i);
        float amp = pow(persistence, i);

        total += interpNoise2D(x * freq, y * freq) * amp;
    }
    return total;
}

//Perlin===============================================
vec3 random3(vec3 p) {
    return fract(sin(vec3(dot(p,vec3(127.1, 315.6, 382.919)),
                          dot(p,vec3(739.5, 283.3, 732.14)),
                          dot(p, vec3(838.69, 283.2,109.21))))
                 *74738.3207);
}

float surflet(vec3 p, vec3 gridPoint) {
    // Compute the distance between p and the grid point along each axis, and warp it with a
    // quintic function so we can smooth our cells
    vec3 t2 = abs(p - gridPoint);
    vec3 t = vec3(1.0) - 6.0 * pow(t2, vec3(5.0)) + 15.0 * pow(t2, vec3(4.0)) - 10.0 * pow(t2, vec3(3.0));
    // Get the random vector for the grid point (assume we wrote a function random2
    // that returns a vec2 in the range [0, 1])
    vec3 gradient = random3(gridPoint) * 2. - vec3(1., 1., 1.);
    // Get the vector from the grid point to P
    vec3 diff = p - gridPoint;
    // Get the value of our height field by dotting grid->P with our gradient
    float height = dot(diff, gradient);
    // Scale our height field (i.e. reduce it) by our polynomial falloff function
    return height * t.x * t.y * t.z;
}

float perlinNoise3D(vec3 p) {
    float surfletSum = 0.0;
    // Iterate over the four integer corners surrounding uv
    p = (p + (time + 721.22913)) * 0.5; // 0 to 1 range
    for(int dx = 0; dx <= 1; ++dx) {
        for(int dy = 0; dy <= 1; ++dy) {
            for(int dz = 0; dz <= 1; ++dz) {
                surfletSum += surflet(p, floor(p) + vec3(dx, dy, dz));
            }
        }
    }
    return surfletSum;
}

#define BACK_WALL 0
#define LEFT_WALL 1
#define RIGHT_WALL 2
#define FLOOR 3
#define SPHERE1 4
#define SHORT_CUBE 5
#define BIG_CUBE 6
#define BACK_WALL_SDF plane(pos, vec4(0.0, 0.0, -1.0, 10.0))
#define LEFT_WALL_SDF plane(pos, vec4(1.0, 0.0, 0.0, 5.0))
#define RIGHT_WALL_SDF plane(pos, vec4(-1.0, 0.0, 0.0, 5.0))
#define CEILING_SDF plane(pos, vec4(0.0, -1.0, 0.0, 7.5))
#define FLOOR_SDF plane(pos, vec4(0.0, 1.0, 0.0, 4.0))
#define SPHERE1_SDF sphere(rotateY(pos, 15.0 * 3.14159 / 180.0), 3.5, vec3(-5.0, 2.0, -1.0))
#define SHORT_CUBE_SDF cube(rotateY(pos + vec3(-2, 1.5, -0.75), -17.5 * 3.14159 / 180.0), vec3(2.2, 3, 2.2))

vec3 rotateY(vec3 p, float a)
{
    return vec3(cos(a) * p.x + sin(a) * p.z, p.y, -sin(a) * p.x + cos(a) * p.z);   
}

// function to create whole scene
void sceneMap3D(vec3 pos, out float t, out int obj)
{
    t = BACK_WALL_SDF;
    obj = BACK_WALL;
    
    float t2;
    if ((t2 = FLOOR_SDF) < t) {
        t = t2;
        obj = FLOOR;
    }
    if ((t2 = SPHERE1_SDF) < t) {
        t = t2;
        obj = SPHERE1;
    }
    if ((t2 = SHORT_CUBE_SDF) < t) {
        t = t2;
        obj = SHORT_CUBE;
    }
}

float sceneMap3D(vec3 pos)
{
    float t = BACK_WALL_SDF;
    
    float t2;
    if ((t2 = FLOOR_SDF) < t) {
        t = t2;
    }
    if ((t2 = SPHERE1_SDF) < t) {
        t = t2;
    }
    if ((t2 = SHORT_CUBE_SDF) < t) {
        t = t2;
    }
    return t;
}

void march(vec3 origin, vec3 dir, out float t, out int hitObj)
{
    t = 0.001;
    for (int i = 0; i < RAY_STEPS; ++i) {
        vec3 pos = origin + t * dir;
        float m;
        sceneMap3D(pos, m, hitObj);
        if (m < 0.001) {
            return;
        }
        t += m;
    }
    t = -1.0;
    hitObj = -1;
}

vec3 computeMaterial(int hitObj, vec3 p, vec3 n, vec3 lightVec, vec3 view)
{
    float lambert = dot(lightVec, n);
    switch(hitObj) {
        case BACK_WALL:
        return lambert * palette(worleyNoise(p.xy), vec3(0.8,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,0.7,0.4),vec3(0.0,0.15,0.20));
        break;
        case FLOOR:
        return lambert * palette(worleyNoise(p.xz), vec3(0.8,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,0.7,0.4),vec3(0.0,0.15,0.20));
        break;
        case SPHERE1:
        return lambert * palette(fbm(sphereMapper(normalize(p-center)).x, sphereMapper(normalize(p-center)).y), vec3(0.1,0.5,0.5), vec3(0.5), vec3(1.0), vec3(0.00, 0.10, 0.20));
        break;
        case SHORT_CUBE:
        return lambert * palette(perlinNoise3D(p), vec3(0.5,0.8,0.8),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.3,0.20,0.20));
        break;
        case -1:
        return vec3(0, 0, 0) * lambert;
        break;
    }
    return vec3(0, 0, 0) * lambert;
}

vec3 computeNormal(vec3 pos)
{
    vec3 epsilon = vec3(0.0, 0.001, 0.0);
    return normalize(vec3(sceneMap3D(pos + epsilon.yxx) - sceneMap3D(pos - epsilon.yxx),
                         sceneMap3D(pos + epsilon.xyx) - sceneMap3D(pos - epsilon.xyx),
                         sceneMap3D(pos + epsilon.xxy) - sceneMap3D(pos - epsilon.xxy)));
}

Intersection sdf3D(vec3 dir, vec3 eye)
{
    float t;
    int hitObj;
    march(eye, dir, t, hitObj);
    
    vec3 isect = eye + (t * dir);
    
    vec3 nor = computeNormal(isect);
    vec3 lightDir = normalize(lightPos - isect);
    vec3 surfaceColor = computeMaterial(hitObj, isect, nor, lightDir, normalize(eye - isect));
    
    return Intersection(t, surfaceColor, isect, hitObj);
}

// Returns direction of ray
vec3 rayCast(vec3 eye, vec3 ref, vec2 ndc)
{
    vec3 F = ref - eye;
    vec3 R = normalize(cross(vec3(0, 1, 0), F));
    vec3 U = normalize(cross(R, -F));
    
    vec3 V = U * length(F) * tan(FOVY * 0.5);
    vec3 H = R * length(F) * tan(FOVY * 0.5) * float(resolution.x) / resolution.y;
    
    vec3 p = ref + ndc.x * H + ndc.y * V;
    
    return normalize(p - eye);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    // Convert range to [-1, 1]
    uv = uv * 2.0 - vec2(1.0, 1.0);
    
    vec3 eye = vec3(7, 5.5, -16);
    vec3 ref = vec3(-2, 1.5, 0);
    
    vec3 rayDir = rayCast(eye, ref, uv);
    
    Intersection isect = sdf3D(rayDir, eye);
    
    glFragColor = vec4(isect.color, 1.0);
}
