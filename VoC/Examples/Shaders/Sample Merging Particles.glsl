#version 420

// original https://www.shadertoy.com/view/4dKBWc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int STEP_NB = 128;
const float DIST_ESPILON = 1e-4;
const float MAX_DIST = 100.;

const float DERIV_EPSI = 1e-4;

const float FIELD_OF_VIEW = 120.;

const float M_PI = 3.1415;

float rand(float n){return fract(sin(n) * 43758.5453123);}
float rand(vec2 n) { 
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}
float noise(vec2 n) {
    const vec2 d = vec2(0.0, 1.0);
  vec2 b = floor(n), f = smoothstep(vec2(0.0), vec2(1.0), fract(n));
    return mix(mix(rand(b), rand(b + d.yx), f.x), mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
}

float sphereDist(vec3 center, float radius, vec3 pos) {
     return length(center-pos) - radius;
}

//Benjamin Keinert, Matthias Innmann, Michael Sänger, and Marc Stamminger. 2015. Spherical fibonacci mapping. ACM Trans. Graph. 34, 6, Article 193 (October 2015), 7 pages.
vec3 sphericalFibonacciMapping(float i, float n) {
    const float PHI = sqrt(5.)*0.5 + 0.5;
    float phi = 2.*M_PI*(i*(PHI-1.)- floor(i*(PHI-1.)));
    float cosTheta = 1. - (2.*i + 1.)*1./n;

    float sinTheta = sqrt(clamp(1. - cosTheta*cosTheta,0.,1.));
    return vec3(
        cos(phi)*sinTheta,
        sin(phi)*sinTheta,
        cosTheta);
}

float smoothMin(float a, float b, float k) {
        float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float evalSceneDist(vec3 pos) {
    float min_dist = MAX_DIST;
    
    // Main Particle
    const int s_nb = 16;
    for(int i=0; i<s_nb; i++){
        vec3 c = sphericalFibonacciMapping(float(i),float(s_nb));
        const float fc = 1.7;
        const float fr = 1.3;
        float tc = mod((time+fc*rand(float(i))),fc) / fc;
        float tr = mod((time+fr*rand(float(i*i))),fr) / fr;
        min_dist = smoothMin(min_dist,sphereDist(abs(sin(tc*M_PI))*c,  abs(sin(tr*M_PI))*.5+.5, pos),.2);
    }
    
    // Small Particles
    const int ss_nb = 64;
    for(int i=0; i<ss_nb; i++){
        float d = rand(float(i))*5.+5.;
        const float f = 3.;
        float t0 = mod((time+f*rand(float(i))),f) / f;
        float t = 1.-t0;
        vec3 c = sphericalFibonacciMapping(float(i),float(ss_nb));
        min_dist = smoothMin(min_dist,sphereDist(c*d*t,  (1.-t)*0.1, pos),0.4);
    }
    
    
    return min_dist;
}

vec3 evalSceneNormal(vec3 pos) {
    return normalize(vec3(
        evalSceneDist(vec3(pos.x+DERIV_EPSI,pos.yz))-evalSceneDist(vec3(pos.x-DERIV_EPSI,pos.yz)),
        evalSceneDist(vec3(pos.x,pos.y+DERIV_EPSI,pos.z))-evalSceneDist(vec3(pos.x,pos.y-DERIV_EPSI,pos.z)),
        evalSceneDist(vec3(pos.xy,pos.z+DERIV_EPSI))-evalSceneDist(vec3(pos.xy,pos.z-DERIV_EPSI))
    ));
}

vec3 rayDirection( vec2 frag_coord) {
    vec2 xy = frag_coord - resolution.xy/2.;
    float z = resolution.y /tan(radians(FIELD_OF_VIEW)/ 2.0);
    return normalize(vec3(xy,-z));
}

float rayMarching(vec3 start, vec3 ray) {    
    float depth = 0.f;
    for(int s=0;s<STEP_NB; s++) {
        float dist = evalSceneDist(start+depth*ray);
        if(dist < DIST_ESPILON)
            return depth;
        depth += dist;
        if(depth > MAX_DIST)
            return -1.;
    }
    return -1.;
}

void main(void)
{
    vec3 cam = vec3(0.,0.,4.);
    vec3 ray = rayDirection(gl_FragCoord.xy);
    
    float dist = rayMarching(cam,ray);
    
    if (dist < 0.f) {
        float d = length(ray.xy);
        const float f = 2.;
        float noise = noise(ray.xy+time*f)*0.2;
        glFragColor = vec4(0.5*(1.- d)+noise,0.,0.,1.);
    } else {  
        vec3 pos = cam+ray*dist;
        vec3 nor = evalSceneNormal(pos);
        float f = abs(dot(nor,ray));
        
            
        glFragColor = vec4(max(f,(0.3-f)*10.),
                         max(0.,max((0.3-f)*10.,10.*(f-0.9))),
                         max(0.,max((0.3-f)*10.,10.*(f-0.9))),
                             1.0);
    }
}
