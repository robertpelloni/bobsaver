#version 420

// original https://www.shadertoy.com/view/Ms2yDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int MAX = 8;
const float PI = 3.1415927;
const vec3 BGCOLOR = vec3(0.0);
const float INF =  9999999.0;
vec3 LIGHT_DIR = vec3(0.0, 1.0, 0.5);

struct Sphere {
    vec3 p;
    float r;
};

struct Ray {
    vec3 o;
    vec3 d;
};

Sphere sphereContainer[MAX];
int sphereCnt = 0;

mat3 rotationMatrix(vec3 axis, float angle) {
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c);
}

// Src - http://blog.hvidtfeldts.net/index.php/2011/06/distance-estimated-3d-fractals-part-i/
float MandelBulbDE(vec3 pos) {
    vec3 z = pos;
    float dr = 1.0;
    float r = 0.0;
    int Iterations = 4;
    float Bailout = 4.0;
    float Power = 8.0;
    for (int i = 0; i < Iterations ; i++) {
        r = length(z);
        if (r>Bailout) break;
        
        // convert to polar coordinates
        float theta = acos(z.z/r);
        float phi = atan(z.y,z.x);
        dr =  pow(r, Power-1.0)*Power*dr + 1.0;
        
        // scale and rotate the point
        float zr = pow( r,Power);
        theta = theta*Power;
        phi = phi*Power;
        
        // convert back to cartesian coordinates
        z = zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
        z+=pos*(cos(time) / 2.0 + 1.0);
    }
    return 0.5*log(r)*r/dr;
}

float traceDE(Ray ray) {
    float totalDistance = 0.0;
    int steps;
    int MaximumRaySteps = 40;
    int MaxRaySteps = 40;
    float MinimumDistance = 0.0005;
    for (steps=0; steps < MaximumRaySteps; steps++) {
        vec3 p = ray.o + totalDistance * ray.d;
        float distance = MandelBulbDE(p);
        totalDistance += distance;
        if (distance < MinimumDistance) break;
    }
    return 1.0-float(steps)/float(MaxRaySteps);
}

float iSphere(Ray ray, Sphere sphere, out vec3 color) {
    float dx = ray.o.x - sphere.p.x;
    float dy = ray.o.y - sphere.p.y;
    float dz = ray.o.z - sphere.p.z;
    
    float a = ray.d.x * ray.d.x + ray.d.y * ray.d.y + ray.d.z * ray.d.z;
    float b = 2.0 * (ray.d.x * dx + ray.d.y * dy + ray.d.z * dz);
    float c = dx * dx + dy * dy + dz * dz - sphere.r * sphere.r;
    float d = b * b - 4.0 * a * c;

    if (d > 0.0) {
        float t0 = (-b + sqrt(d)) / 2.0;
        float t1 = (-b - sqrt(d)) / 2.0;
        float t = max(t0, t1);
        vec3 ip = ray.o + ray.d * t;
        vec3 normal = normalize(ip - sphere.p);

        vec3 sphereColor = vec3(1.0, 1.0, 0.0);
        color = clamp(vec3(sphereColor) * dot(normal, LIGHT_DIR), vec3(0.0), vec3(1.0));
        color += sphereColor * vec3(0.1);
        return t;
    }

    return INF;
}

void setupScene() {
    Sphere sphere0;
    sphere0.p = vec3(0.0, 0.0, 0.0);
    sphere0.r = 1.0;
    
    sphereContainer[0] = sphere0;
    sphereCnt = 1;
    LIGHT_DIR.x = sin(time);
    LIGHT_DIR.y = cos(time);
}

Ray getRay(vec2 uv) {
    Ray ray;
    mat3 rot = rotationMatrix(vec3(sin(time), cos(time), 1.0), time / 1000.0);
    ray.o = vec3(-3.0, 0.0, 0.0) * rot;
    ray.d = normalize(vec3(1.0, uv)) * rot;
    
    return ray;
}

vec3 trace(Ray ray) {
    vec3 closestColor = BGCOLOR;
    float closestDist = INF;
    
    for(int i = 0;i < sphereCnt;++i) {
        vec3 currentColor;
        float currentDist = iSphere(ray, sphereContainer[i], currentColor);
        if (closestDist > currentDist) {
            closestDist = currentDist;
            closestColor = currentColor;
        }
    }
    return closestColor;
}

void main(void) {
    float ar = resolution.x / resolution.y;
    vec2 uv = gl_FragCoord.xy / resolution.y - vec2(ar * 0.5, 0.5);

    /*
    setupScene();
    vec3 colorSum = vec3(0.0);
    float kernelSize = 2.0;
    for(float x = 0.0;x < kernelSize;++x) {
        for(float y = 0.0;y < kernelSize;++y) {
            vec2 ruv = uv + vec2(x / kernelSize, y / kernelSize) / resolution.xy;
            Ray ray = getRay(ruv);
            colorSum += trace(ray);
        }
    }
    colorSum /= kernelSize * kernelSize;
    */
    
    Ray ray = getRay(uv);
    float mandelbulbColor = traceDE(ray) * 1.1 + 0.1;
    
    glFragColor = vec4(vec3(1.0, 0.0, 0.5) * mandelbulbColor, 1.0);
}
