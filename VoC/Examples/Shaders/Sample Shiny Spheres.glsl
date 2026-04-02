#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/XllBRf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int nSpheres = 50;
const float sphereRadius = 0.45;

const float tau = 6.28318;
const float inf = 999.0;

struct Hit { 
    float t; 
    vec3 p; 
    vec3 n;
    int id;
};

Hit noHit;

Hit sphereHit(vec3 center, float radius, vec3 rayOrigin, vec3 rayDirection, int id) {
    float a = dot(rayDirection, rayDirection);
    vec3 L = rayOrigin - center;
    float b = 2.0 * dot(rayDirection, L);
    float c = dot(L, L) - radius*radius;
    float discrim = b*b - 4.0*a*c;
    if (discrim < 0.0) return noHit;
    float t = (-b - sqrt(discrim)) / (2.0 * a);
    if (t < 0.0) return noHit;
    vec3 p = rayOrigin + t*rayDirection;
    return Hit(t, p, normalize(p-center), id);
}

Hit hitSomething(vec3 rayOrigin, vec3 rayDirection, float time) {
    const float fns = float(nSpheres);

    Hit minHit = noHit;

    for (int i = 0; i < nSpheres; i++) {
        float fi = float(i);
        float fni = fi / fns;
        float d = 3.0 * sin(time * fni + fi);
        vec3 center = vec3(d*cos(tau*fni+time*10.0*fni)+sin(time*10.0), 
                       d*sin(tau*fni+time*10.0*fni), 
                       d*sin(0.5*tau*fni+time*fni*1.4142)+cos(time*10.0));
        
        Hit hit = sphereHit(center, sphereRadius + sphereRadius*2.0*pow(float(i%10)/10.0, 5.0), rayOrigin, rayDirection, 0);
        if (hit.t <= 0.0 || hit.t > minHit.t) continue;
        minHit = hit;
    }

    Hit hit = sphereHit(vec3(0.0, -41.5, 2.0), 40.0, rayOrigin, rayDirection, 1);
    if (hit.t > 0.0 && hit.t < minHit.t) minHit = hit;

    return minHit;
}

vec3 colorSomething(Hit hit, float time, vec3 rayOrigin, vec3 rayDirection, mat3x3 cam) {
    if (hit.t > inf - 0.5) return vec3(0.0, 0.75+0.25*sin(time), 1.0);

    vec3 color;

    // diffuse
    if (hit.id == 0) {
        float dup    = 1.0 * dot(hit.n, cam[1]) + 0.0;
        float dright = 1.0 * dot(hit.n, cam[0]) + 0.0;
        float dfwd   = 1.0 * dot(hit.n, -cam[2] ) + 0.0;
        color = vec3(dright, dup, dfwd);
    } else if (hit.id == 1) {
        float check = 0.4 + 0.6 * float(int(mod(hit.p.x, 2.0)) ^ int(mod(hit.p.z, 2.0)));
        color = vec3(check, check, 0.1);
    }

    // specular
    vec3 refl = reflect(rayDirection, hit.n);
    float spec = pow(dot(refl, cam[1]), 20.0);
    if (spec > 0.0) color += vec3(spec, spec, spec);

    return color;
}

const int maxDepth = 4;
vec3 trace( mat3x3 cam, vec3 rayOrigin, vec3 rayDirection, float time )
{
    vec3 color = vec3(0.0, 0.0, 0.0);
    float ref = 1.0;
    for (int i = 0; i < maxDepth; i++) {
        Hit minHit = hitSomething(rayOrigin, rayDirection, time);
        color += ref * colorSomething(minHit, time, rayOrigin, rayDirection, cam);
        if (minHit.id < 0) break;
        ref *= 0.6;
        rayOrigin = minHit.p;
        rayDirection = reflect(rayDirection, minHit.n);
    }
    color = color * 0.8;
    return color;
}

void main(void)
{
    const vec3 zero = vec3(0.0, 0.0, 0.0);
    noHit = Hit(inf, zero, zero, -1);
    
    // make time optionally srubbable
    float time = time / 20.0;

    float camDist = 8.0;
    vec3 rayOrigin = vec3(1.1*camDist*sin(tau * time * 0.5), 0.0, 0.9*camDist*cos(tau * time * 0.5));
    vec2 uv = 2.0 * gl_FragCoord.xy / resolution.xy - vec2(1.0, 1.0);
    uv.x *= resolution.x / resolution.y;
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 lookat = vec3(0.0, 0.0, 0.0);
    vec3 fwd   = normalize(lookat - rayOrigin);
    vec3 right = normalize(cross(fwd, up));
    vec3 camup = normalize(cross(right, fwd));
    vec3 rayDirection = normalize(fwd + 0.5 * (uv.x*right + uv.y*up));
    
    glFragColor = vec4(trace(mat3x3(right, camup, fwd), rayOrigin, rayDirection, time), 1.0);
}
