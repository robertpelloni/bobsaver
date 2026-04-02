#version 420

// original https://www.shadertoy.com/view/lsjcWG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by SHAU - 2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

/**
 *
 * Simple ray tracer based on IQ article on Sphere functions
 * http://iquilezles.org/www/articles/spherefunctions/spherefunctions.htm
 *
 **/

#define T time
#define EPS 0.0001
#define FAR 6.0 
#define PI 3.1415926535

const int ID_MISS = 0;
const int ID_SPHERE = 1;
const int ID_FLOOR = 2;
const int ID_WALL1 = 3;
const int ID_WALL2 = 4;

vec3 lp = vec3(4.0, 4.0, -3.5); //light position

vec4 osphere = vec4(0.0, 0.0, 0.0, 0.5); //sphere
vec3 ofloor = vec3(0.0, -1.0, 0.0); //floor
vec3 owall1 = vec3(-3.0, 0.0, 0.0); //wall 1
vec3 owall2 = vec3(0.0, 0.0, 3.0); //wall 2
vec3 nsphere = vec3(0); //sphere normal
vec3 nfloor = vec3(0, 1, 0); //floor normal
vec3 nwall1 = vec3(1, 0, 0); //wall 1 normal
vec3 nwall2 = vec3(0, 0, -1); //wall 2 normal    

struct Hit {
    int id; //id of hit object
    float t; //distance to hit position
    vec3 hp; //hit position
    vec3 hn; //hit normal
    float ref; //refectivity
};
    
const Hit MISS = Hit(ID_MISS, -1.0, vec3(0), vec3(0), 0.0);

mat2 rot(float x) {
    return mat2(cos(x), sin(x), -sin(x), cos(x));
}
 
vec3 sphNormal(vec3 pos, vec4 sph) {
    return normalize(pos - sph.xyz);
}

Hit sphIntersect(in vec3 ro, in vec3 rd, in vec4 sph) {
    
    vec3 oc = ro - sph.xyz;
    float b = dot(oc, rd);
    float c = dot(oc, oc) - sph.w * sph.w;
    float h = b * b - c;
    if (h < 0.0) return MISS; //missed
    
    float t = -b - sqrt(h);
    vec3 hp = ro + rd * t;
    vec3 hn = sphNormal(hp, sph);
    
    return Hit(ID_SPHERE, t, hp, hn, 0.8);
}

Hit planeIntersect(vec3 ro, vec3 rd, vec3 n, vec3 o, int id) {
    float t = dot(o - ro, n) / dot(rd, n);
    vec3 hp = ro + rd * t;
    return Hit(id, t, hp, n, 0.2);
}

Hit nearestSurface(Hit old, Hit new) {
    if (new.t > 0.0) {
        if (old.t > 0.0 && old.t < new.t) return old; 
        return new;
    }
    return old;
}

float sphSoftShadow(vec3 ro, vec3 rd, vec4 sph, float k) {
    
    vec3 oc = ro - sph.xyz;
    float b = dot(oc, rd);
    float c = dot(oc, oc) - sph.w * sph.w;
    float h = b * b - c;
    
    // physically plausible shadow
    float d = sqrt(max(0.0, sph.w * sph.w - h)) - sph.w;
    float t = -b - sqrt(max(h, 0.0));
    return (t < 0.0) ? 1.0 : smoothstep(0.0, 1.0, 2.5 * k * d / t);
} 

float sphOcclusion(vec3 pos, vec3 nor, vec4 sph) {
    vec3  r = sph.xyz - pos;
    float l = length(r);
    return dot(nor, r) * (sph.w * sph.w) / (l * l * l);
}

//trace a single ray through scene objects and return nearest hit object
//omit tracing currently hit object if tracing a reflection
Hit traceRay(vec3 ro, vec3 rd, int dontTrace) {
    
    Hit nearestObject = MISS; //default to missed scene
    
    if (dontTrace != ID_SPHERE) {
        nearestObject = nearestSurface(nearestObject, sphIntersect(ro, rd, osphere));
    }
    
    if (dontTrace != ID_FLOOR) {
        nearestObject = nearestSurface(nearestObject, planeIntersect(ro, rd, nfloor, ofloor, ID_FLOOR)); 
    }
    
    if (dontTrace != ID_WALL1) {
        nearestObject = nearestSurface(nearestObject, planeIntersect(ro, rd, nwall1, owall1, ID_WALL1)); 
    }
       
    if (dontTrace != ID_WALL2) {
        nearestObject = nearestSurface(nearestObject, planeIntersect(ro, rd, nwall2, owall2, ID_WALL2)); 
    }
    
    return nearestObject;
}

vec3 wallColour(float x) {
    vec3 wc = vec3(0.0);    
    if (mod(x - T * 2.0, 3.0) > 1.5) { 
        wc = vec3(0.8, 0.8, 1.0);
    }
    return wc;
}

vec3 pixelColour(vec3 ro, vec3 rd, Hit hit) {
    
    vec3 pc = vec3(0); //pixel colour
    vec3 sc = vec3(0.2); //surface colour
    float occ = 1.0; //occlusion
    
    if (hit.id == ID_FLOOR) {
        sc = vec3(1.0, 0.8, 0.8); 
        occ = 1.0 - sphOcclusion(hit.hp, nfloor, osphere);
    }
    if (hit.id == ID_WALL1) {
        sc = vec3(0.0, 1.0, 0.8);
        occ = 0.5 + 0.5 * nwall1.y;
    }
    if (hit.id == ID_WALL2) {
        sc = wallColour(hit.hp.x); 
        occ = 0.5 + 0.5 * nwall2.y;
    }

    float diff = max(dot(hit.hn, normalize(lp)), 0.0); //diffuse
    pc = diff * sc; 
    pc *= sphSoftShadow(hit.hp, normalize(lp), osphere, 2.0);
    pc += 0.05 * occ; 
    
    float ld = length(lp - hit.hp); //distance from light to hit surface
    pc /= (ld * ld * 0.05);
    
    float spe = pow(max(dot(reflect(rd, hit.hn), normalize(lp)), 0.), 16.); //specular.
    pc += spe * vec3(1.0) * hit.ref;

    return pc;
}

void main(void) {
    
    vec3 pc = vec3(0);
    
    //coordinate system
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    
    //camera
    vec3 lookAt = vec3(0.0, 0.0, 0.0);  // "Look At" position.
    vec3 camPos = lookAt + vec3(0.0, 0.0, -1.5);
    camPos.xz *= rot(T);
    
    // Using the above to produce the unit ray-direction vector.
    float FOV = PI / 4.; // FOV - Field of view.
    vec3 forward = normalize(lookAt - camPos);
    vec3 right = normalize(vec3(forward.z, 0., -forward.x )); 
    vec3 up = cross(forward, right);
    
    // rd - Ray direction.
    vec3 rd = normalize(forward + FOV * uv.x * right + FOV * uv.y * up);

    //first pass
    Hit hit = traceRay(camPos, rd, ID_MISS);
    float tt = hit.t; //total distance travelled by ray and bounces
    
    if (hit.t > 0.0) {
        
        //surface colour
        pc = pixelColour(camPos, rd, hit) * exp(-0.05 * tt);   
    
        //reflections
        Hit phit = hit; //previous hit surface
        vec3 prd = rd; //previous ray direction
        float rfact = 1.0; //reflection factor
        
        for (int i = 0; i < 6; i++) {
            
            vec3 rrd = reflect(prd, phit.hn); //reflected ray direction  
            
            Hit reflection = traceRay(phit.hp, rrd, phit.id); //reflection hit surface
            tt += reflection.t;
            rfact *= phit.ref;
            
            pc = mix(pc, pixelColour(phit.hp, rrd, reflection) * exp(-0.05 * tt), rfact); 
            
            phit = reflection;
            prd = rrd;
            
            if (reflection.t < 0.0) {
                break;    
            }
        }
        
        float spe = pow(max(dot(reflect(rd, hit.hn), normalize(lp)), 0.), 16.); //specular.
        pc += spe * vec3(1.0) * hit.ref;
    }
    
    glFragColor = vec4(pc ,1.0);
}
