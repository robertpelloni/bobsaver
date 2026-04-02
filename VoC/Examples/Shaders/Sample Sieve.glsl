#version 420

// original https://www.shadertoy.com/view/MlGyRy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define thickness .0025
#define sqrt3 1.73205080757
#define cell .033333333
#define speed 5.
#define boxmin -1.
#define boxmax 1.
#define fff(x) floor(x / thickness) * thickness

float rnd(in vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

bool intersect(in vec3 orig, in vec3 dir, out float minDist, out float maxDist) {
    float tmin = (boxmin - orig.x) / dir.x; 
    float tmax = (boxmax - orig.x) / dir.x; 
 
    if (tmin > tmax){
        float tmp = tmin;
        tmin = tmax;
        tmax = tmp;
    }
 
    float tymin = (boxmin - orig.y) / dir.y; 
    float tymax = (boxmax - orig.y) / dir.y; 
 
    if (tymin > tymax){
        float tmp = tymin;
        tymin = tymax;
        tymax = tmp;
    }
 
    if ((tmin > tymax) || (tymin > tmax)) 
        return false; 
 
    if (tymin > tmin) 
        tmin = tymin; 
 
    if (tymax < tmax) 
        tmax = tymax; 
 
    float tzmin = (boxmin - orig.z) / dir.z; 
    float tzmax = (boxmax - orig.z) / dir.z; 
 
    if (tzmin > tzmax){
        float tmp = tzmin;
        tzmin = tzmax;
        tzmax = tmp;
    }
 
    if ((tmin > tzmax) || (tzmin > tmax)) 
        return false; 
 
    if (tzmin > tmin) 
        tmin = tzmin; 
 
    if (tzmax < tmax)
        tmax = tzmax;
 
    minDist = tmin;
    maxDist = tmax;
    return true;
}

vec3 rayDirection(float fieldOfView, vec2 size) {
    vec2 xy = gl_FragCoord.xy - size / 2.;
    float z = size.y / tan(radians(fieldOfView) / 2.);
    return normalize(vec3(xy, -z));
}

mat4 viewMatrix(vec3 eye, vec3 center, vec3 up) {
    vec3 f = normalize(center - eye),
         s = normalize(cross(f, up)),
         u = cross(s, f);
    return mat4(vec4(s, 0.), vec4(u, 0.), vec4(-f, 0.), vec4(vec3(0.), 1.));
}

vec3 clrInside(in float lmin, in float lmax, in vec3 origin,  vec3 dir){
    float tc = fff(fract(time * .25));
    float tp = fff(fract(time * .25 + .5));
    float t1 = max(tc, tp);
    float t2 = min(tc, tp);
    
    float iter = lmin + .01;
    while(iter < lmax){
        vec3 intersectionNormalized = vec3(.5) + (origin + dir * iter) * .5;
        float y = fff(intersectionNormalized.y);
        
        float r = rnd(floor(intersectionNormalized.xz/cell + floor(time * .25)));
        float deltatime = t1 - (.5 + r * .35);
        float deltapos = (speed + (r * 2. - 1.)) * deltatime * step(0., deltatime);
        float n = fff((t1 - deltapos));
        
        vec2 muv = abs(mod(intersectionNormalized.xz, cell) * 2. - cell);
        if(y == max(n, t2) && step(muv.x, cell * .66) == 1. && step(muv.y, cell * .66) == 1.)
            return vec3(1.);
        iter += .01;
    }
    return vec3(0.);
}

void main(void) {
    vec3 viewDir = rayDirection(45.0, resolution.xy);
    vec3 eye = vec3(0., .75, 3.5);
    mat4 viewToWorld = viewMatrix(eye, vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0));
    vec3 worldDir = (viewToWorld * vec4(viewDir, 0.0)).xyz;
    
    float lmin, lmax;
    if (intersect(eye, worldDir, lmin, lmax)) {
        vec3 point = eye + worldDir * lmin;
        glFragColor = vec4(clrInside(lmin, lmax, eye, worldDir), 1.);
        return;
    }
    
    glFragColor = vec4(0);
}
