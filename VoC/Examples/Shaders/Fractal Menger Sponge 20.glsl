#version 420

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

const float MIN_AMBIANCE = 10.0;
const int   MAX_HITS = 3; 
const int   MARCH_STEPS = 256;
const float REFLECTIVENESS = 0.1;
const float EPS = 1.0 / (256.0);
const float MIN_REBOUNCE = EPS * 16.0;
const float PI = 3.14159265;
const float PHI = 1.61803398875;

const int SSAA_PHI_SAMPLE = 1;

const float LOOP = 3.0;

const vec3  ambientLightDir    = vec3(-0.2, 0.8, -0.2);
const vec4  ambientLightColor    = vec4(1.);

float angle = 75.;
float fov = angle * 0.5 * PI / 180.0;
vec3  cameraPos = vec3(1.0*sin(0.2 * time), 1.0*cos(0.2 * time), -10.0 + 0.20*time);

// Ext Math
float loop(float x, float l) {
    return x - floor(x / l) * l;    
}

vec3 loop(vec3 p) {
    p.x = loop(p.x + LOOP / 2.0, LOOP) - LOOP / 2.0;
    p.y = loop(p.y + LOOP / 2.0, LOOP) - LOOP / 2.0;
    p.z = loop(p.z + LOOP / 2.0, LOOP) - LOOP / 2.0;
    return p;
}

float crossDist(vec3 p) {
    vec3 absp = abs(p);
    // get the distance to the closest axis
    float maxyz = max(absp.y, absp.z);
    float maxxz = max(absp.x, absp.z);
    float maxxy = max(absp.x, absp.y);
    float cr = 1.0 - (step(maxyz, absp.x)*maxyz+step(maxxz, absp.y)*maxxz+step(maxxy, absp.z)*maxxy);
    // cube
    float cu = max(maxxy, absp.z) - 3.0;
    // remove the cross from the cube
    return max(cr, cu);
}

// Combining SDF's
float intersectSDF(float distA, float distB) {
    return max(distA, distB);
}

float unionSDF(float distA, float distB) {
    return min(distA, distB);
}

float differenceSDF(float distA, float distB) {
    return max(distA, -distB);
}

// Primitive SDFs
float sdfSphere(vec3 p, float r)
{
    return length(p) - r;
}

float udBox( vec3 p, vec3 b )
{
      return length(max(abs(p)-b,0.0));
}

float sdCylinder( vec3 p, vec3 c )
{
     return length(p.xz-c.xy)-c.z;
}

float fractal( vec3 p ) {
    float OVERALL_SCALE = 6.0;
    
    p *= OVERALL_SCALE;
    float scale = 1.0;
        float dist = 0.0;
        for (int i = 0 ; i < 4; i++) {
            dist = max(dist, crossDist(p)*scale);
            p = fract((p-1.0)*0.5)*6.0 - 3.0;
            scale /= 3.0;
        }
        return dist / OVERALL_SCALE;
}

// Main SDF
float sceneSDF(vec3 p){
    p = loop(p);
    
    return fractal(p);
    
    float sphere = sdfSphere(p, 0.5);
    float cube = udBox(p, vec3(0.4, 0.4, 0.4));
    float rcube = intersectSDF(sphere, cube);
    
    float cyly = sdCylinder(p.xyz, vec3(0,0,0.25));
    float cylx = sdCylinder(p.yzx, vec3(0,0,0.25));
    float cylz = sdCylinder(p.zxy, vec3(0,0,0.25));
    
    float cyl = unionSDF(cyly, cylx);
    cyl = unionSDF(cyl, cylz);
    cyl = unionSDF(cyl, sdfSphere(p, 0.35));
    
    float shell = differenceSDF(rcube, cyl);
    
    float tiny_sphere = sdfSphere(p, 0.1);
    
    // return sphere;

    // return rcube;
    return unionSDF(shell, tiny_sphere);
    
    // return cyl;
    
}

// Utils
vec4 getBackGroundColor(vec3 r){
    return vec4(vec3(dot(r, ambientLightDir)),1.0);
}

vec3 getNormal(vec3 p){
    p = loop(p);
    float n = 1.0 / 4.0;
    return normalize(vec3(
        sceneSDF(p + n * vec3(EPS, 0.0, 0.0)) - sceneSDF(p - n * vec3(EPS, 0.0, 0.0)),
        sceneSDF(p + n * vec3(0.0, EPS, 0.0)) - sceneSDF(p - n * vec3(0.0, EPS, 0.0)),
        sceneSDF(p + n * vec3(0.0, 0.0, EPS)) - sceneSDF(p - n * vec3(0.0, 0.0, EPS))
    ));
}

float halfLambart(vec3 normal, vec3 ambient_light_direc){
    float tmp = dot(normal, ambient_light_direc) * 0.5 + 0.5;
    return pow(tmp, 2.);
}

vec4 getDiffuseRadiance(vec3 p) {
    vec3 normal = getNormal(p);
    return vec4(vec3(halfLambart(normal, ambientLightDir)), 1.0);
}

vec4 getColor(vec2 p) {
    p = (2.0 * p) / min(resolution.x, resolution.y) - 1.0;
    
    // Ray Direction
    vec3 ray = normalize(vec3(sin(fov) * p.x, sin(fov) * p.y, cos(fov)));    
    
    int hits = 0;
    
    // Marching Loop
    float dist;
       float rLen = 0.0;
    vec3 cPos = cameraPos;
       vec3 rPos = cPos;
    vec4 diffuseColor = vec4(1., 1., 1., 1.);
    vec4 color = vec4(0.0);
    int sI = 0;
       for(int i = 0; i < MARCH_STEPS; i++){
        if(MAX_HITS < hits) {
            break;
        }
        
        rPos = cPos + ray * rLen;
        dist = sceneSDF(rPos);
        rLen += dist;
        
        
        // Hit Check
        if(abs(dist) < EPS && MIN_REBOUNCE < abs(rLen)){
            vec4 new_c = ambientLightColor * diffuseColor * getDiffuseRadiance(rPos);
            new_c *= MIN_AMBIANCE / max(MIN_AMBIANCE, float(i - sI));
            new_c.a = 1.0;
            color = (color) + (1.0 - REFLECTIVENESS) * new_c * (1.0 - color.a);
            
            hits += 1;
            cPos = loop(rPos);
            rLen = 0.0;
            
            vec3 norm = getNormal(cPos);
            float d = dot(ray, norm);
            
            ray = ray - 2.0 * d * norm;
            
        }
      }
    // No Hit
    vec4 new_c = getBackGroundColor(ray);
    color = color + new_c * (1.0 - color.a);
    return color;
}

vec4 avg(vec4 c) {
    return c / c.a;    
}

vec4 getSuperSamplePhiGrid(vec2 p) {
    vec4 sum = vec4(0.0,0.0,0.0,0.0);
    for(int i = 0; i < SSAA_PHI_SAMPLE; ++i) {
        float tx = p.x + loop(PHI * float(i), 1.0);
        float ty = p.y + float(i) / float(SSAA_PHI_SAMPLE);
        sum +=    getColor(vec2(tx, ty));
    }
    return avg(sum);
}

void main( void ) {
    // Fragment Position
    vec2 p = gl_FragCoord.xy;
    
    
    glFragColor = getSuperSamplePhiGrid(p);
     
}
