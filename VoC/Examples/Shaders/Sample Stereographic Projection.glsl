#version 420

// original https://www.shadertoy.com/view/wsGXWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define EPSILON 1e-2
#define INFTY 1e6

// complex numbers
const vec2 c1 = vec2(1.0, 0.0); //1
const vec2 c0 = vec2(0.0); //0

const float sphereSize = 1.0;

// coordinate change 
vec2 xy2pol(vec2 z) {   //(Re(z),Im(z))->(arg,rad)
    return vec2(atan(z.x, z.y), length(z));
}
vec2 pol2xy(vec2 z) {   //(arg,rad)->(Re(z),Im(z))
    return vec2(z.y * cos(z.x), z.y * sin(z.x));
}

// operations of complex numbers
vec2 cMult(vec2 z, vec2 w) {    //z*w
    return vec2(z.x * w.x - z.y * w.y, z.y * w.x + z.x * w.y);
}
vec2 cPow(vec2 z, float n) {    //z^n
    z = xy2pol(z);
    z = vec2(n * z.x, pow(z.y, n));
    return pol2xy(z);
}
vec2 cConj(vec2 z) {    //bar{z}
    return vec2(z.x, - z.y);
}
vec2 cInv(vec2 z) { //z^{-1}
    return (1.0 / pow(length(z), 2.0)) * cConj(z);
}

// geometry
float sphereSDF(vec3 p) {
    return length(p) - sphereSize ;
}
float planeSDF(vec3 p) {
    return abs(p.y);
}
float sceneSDF(vec3 p) {
    return min(planeSDF(p), sphereSDF(p));
}
float getAngle(vec3 p, vec3 q) {
    return acos(dot(normalize(p), normalize(q)));
}
float hitSphere(vec3 camPos, vec3 ray) {
    return length(camPos) * sin(getAngle( - camPos, ray)) - sphereSize;
}
float hitPlane(vec3 camPos, vec3 ray) {
    return dot(vec3(0.0, 1.0, 0.0), ray);
}
float hitScene(vec3 camPos, vec3 ray) {
    return min(hitPlane(camPos, ray), hitSphere(camPos, ray));
}
float getDist2Plane(vec3 camPos, vec3 ray) {
    float ang = getAngle(vec3(0.0, - 1.0, 0.0), ray);
    float dist = abs(camPos.y);
    if (hitPlane(camPos, ray) < 0.0) {
        return dist / cos(ang);
    } else {
        return INFTY;
    }
}
float getDist2Sphere(vec3 camPos, vec3 ray) {
    float ang = getAngle( - camPos, ray);
    float dist = length( - camPos);
    if (hitSphere(camPos, ray) < 0.0) {
        return dist * cos(ang) - sqrt(pow(dist * cos(ang), 2.0) - pow(dist, 2.0) + pow(sphereSize, 2.0));
    } else {
        return INFTY;
    }
}
float getDist2Scene(vec3 camPos, vec3 ray) {
    return min(getDist2Plane(camPos, ray), getDist2Sphere(camPos, ray));
}
vec3 getNormal(vec3 p) {
    float d = EPSILON;
    return normalize(vec3(
        sceneSDF(p + vec3(d, 0.0, 0.0)) - sceneSDF(p),
        sceneSDF(p + vec3(0.0, d, 0.0)) - sceneSDF(p),
        sceneSDF(p + vec3(0.0, 0.0, d)) - sceneSDF(p)
    ));
}
mat3 rotX(float theta) {
    return mat3(
        1.0, 0.0, 0.0,
        0.0, sin(theta), cos(theta),
        0.0, - cos(theta), sin(theta)
    );
}
mat3 rotY(float theta) {
    return mat3(
        sin(theta), 0.0, cos(theta),
        0.0, 1.0, 0.0,
        - cos(theta), 0.0, sin(theta)
    );
}
float fct(vec2 z) {    
    return pow(cos(z.x * PI), 2.0) + pow(sin(z.y * PI), 2.0);
}
// fct(x+iy)=cos^2(x*PI)+sin^2(y*PI)

vec2 moebius(vec2 a, vec2 b, vec2 c, vec2 d, vec2 z) {
    return cMult((cMult(a, z) + b), (cMult(c, z) + d));
}
// moebius(a,b,c,d,z)=(az+b)/(cz+d)

void main(void) {

    // fragment position
    vec2 pixPos = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    
    // camera
    vec3 camPos = vec3(0.0, 0.0, 1.9);
    vec3 camDir = vec3(0.0, - 0.0, - 1.0);
    vec3 camUp = vec3(0.0, 1.0, 0.0);
    vec3 camSide = cross(camDir, camUp);
    float targetDepth = 1.0;
    float theta = 3.2 * PI / 4.0;
    camPos = rotX(theta) * camPos;
    camDir = rotX(theta) * camDir;
    camUp = rotX(theta) * camUp;
    
    // ray
    vec3 ray = normalize(camSide * pixPos.x + camUp * pixPos.y + camDir * targetDepth);

    vec4 col = vec4(0.0, 0.0, 0.0, 1.0);;
    if (hitScene(camPos, ray) < 0.0) {
        vec3 rayPos = camPos + getDist2Scene(camPos, ray) * ray;
        vec3 top = vec3(0.0, sphereSize, 0.0);
        vec3 top2Sph = rayPos- top ;
        float ang = getAngle( - top, top2Sph);
        vec3 planePos = sphereSize / (length(top2Sph) * cos(ang)) * top2Sph;
        float t = 0.5 * time;
        vec2 a = pol2xy(vec2(0.5 * t, 0.5 + 0.47 * sin(t)));
        vec2 b = c1 * cos(t);
        vec2 c = c0;
        vec2 d = c1;
        
        glFragColor = mix(
            vec4(vec3(0.0), 1.0),
            vec4(1.0), 
            step(1.0, fct(moebius(a, b, c, d, planePos.xz))));
    } else {
        glFragColor = vec4(vec3(0.0), 1.0);
    } 
}
