#version 420

// original https://www.shadertoy.com/view/Wl2XzR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float screenDist = 0.5;                            // Screen distance as a fraction of screen width
const vec3 light = normalize(vec3(-0.5, -0.7, -0.2));
const int stepCount = 256;
const float tmin = 0.01;
const float tmax = 200.0;
const float pi = 3.14159265;

float mapsphere(in vec3 p, in vec3 center, float rad) {
    return length(p - center) - rad;   
}

float mapbox(in vec3 p, in vec3 center, in vec3 size) {    
    vec3 a = abs(p - center) - vec3(size);
    return max(a.x, max(a.y, a.z));
}

float mapcube(in vec3 p, in vec3 center, float size) {
     return mapbox(p, center, vec3(size));   
}

float mapplane(in vec3 p, in vec3 center, in vec3 n) {
    return dot(p - center, n);
}

vec3 rotx(in vec3 p, float a) {
    return vec3(p.x,
                cos(a) * p.y + sin(a) * p.z,
                cos(a) * p.z - sin(a) * p.y);
}

vec3 roty(in vec3 p, float a) {
    return vec3(cos(a) * p.x + sin(a) * p.z,
                p.y,
                cos(a) * p.z - sin(a) * p.x);
}

vec3 rotz(in vec3 p, float a) {
    return vec3(cos(a) * p.x + sin(a) * p.y,
                cos(a) * p.y - sin(a) * p.x,
                p.z);
}

vec3 roteuler(in vec3 p, in vec3 euler) {
     return roty(rotx(rotz(p, euler.z), euler.y), euler.z);   
}

vec4 minp(in vec4 a, in vec4 b) {
    return a.w < b.w ? a : b;   
}

bool checkerboard(in vec2 p) {
    float x = mod(p.x, 2.0);
    if (x < 0.0) x += 2.0;
    float y = mod(p.y, 2.0);
    if (y < 0.0) y += 2.0;
    return (x < 1.0) == (y < 1.0);
}

vec4 map(in vec3 p) { 
    vec4 sphere = vec4(0, 0, 0, 1000);
    for (int i = 0; i < 10; i++) {
        float a = float(i) * 2.0*pi / 10.0;
        float a2 = a + time * 0.4;
        vec3 center = vec3(sin(a2), 0.0, cos(a2)) * 5.0 + vec3(0, 2.0 + sin(float(i)), -10);
        vec3 col = vec3(sin(a), sin(a + 2.2), sin(a + 4.4)) * 0.75 + vec3(0.5);
         sphere = minp(sphere, vec4(col, mapsphere(p, center, 1.0)));
    }
    
    const vec3 boxCol = vec3(0.6);    
    vec3 ccenter = vec3(0, 4.0 + sin(time) * 1.0,-10);
    vec3 boxp = ccenter + roteuler(p - ccenter, vec3(time * 0.2, time * 0.7, time * 1.1) * 0.3);
    vec4 box = vec4(boxCol, mapbox(boxp, ccenter, vec3(3, 2, 0.75)));
    box.w = max(box.w, 1.0 - length(boxp.xy - ccenter.xy));
    box.w = max(box.w, 0.5 - length(boxp.yz - ccenter.yz));
    box.w = max(box.w, 0.5 - length(boxp.xz - ccenter.xz));

    const vec3 planeCol1 = vec3(0, 0.5, 0.75);
    const vec3 planeCol2 = vec3(0.7, 0.8, 1);
    vec4 plane = vec4(
        checkerboard(p.xz * 0.5) ? planeCol1 : planeCol2, 
        p.y - -2.0);
    
    return minp(sphere, minp(box, plane));
}

vec3 getNormal(in vec3 p, float t) {
    
    // Calculate pixel size at point distance. 
    // This will be the distance of the normal samples from the original point.
    float s = 0.1 / t;
    
    // Sample relative distance along each axis
    float d = map(p).w;            // Need original distance to compare it to
    vec3 r = vec3(
        map(p + vec3(s,0,0)).w - d,
        map(p + vec3(0,s,0)).w - d,
        map(p + vec3(0,0,s)).w - d);
    
    return normalize(r);
}

vec3 getScreenRay(in vec2 s) {
    s -= resolution.xy / 2.0;
    return vec3(s / (screenDist * resolution.x), -1);
}

vec4 march(in vec3 from, in vec3 delta) {
    float t = tmin;    
    for (int i = 0; i < stepCount && t < tmax; i++) {
         vec3 p = from + delta * t;
        vec4 d = map(p);
        if (abs(d.w) <= 0.0005 * t)
            return vec4(d.xyz, t);
        t += d.w;
    }
    
    return vec4(vec3(0),-1);    
}

float shadow(in vec3 from, in vec3 delta, float k) {
    float res = 1.0;
    float t = tmin;    
    for (int i = 0; i < stepCount && t < tmax; i++) {
         vec3 p = from + delta * t;
        float d = map(p).w;
        if (d <= 0.0)
            return 0.0;
        res = min(res, k*d/t);
        t += d;
    }
    
    return res;
}

// Crude lighting equation
float lighting(in vec3 e, in vec3 n, float diffuse, float specular, float shiny) {
    
    // Diffuse term
    float d = dot(n, -light) * diffuse;
    
    // Specular term
    vec3 h = -(normalize(e) + light) / 2.0;
    float s = pow(dot(n, h), shiny) * specular;

    return max(d + s, 0.0);
}

void main(void)
{
    const vec3 fogCol = vec3(0.0, 0.0, 0.2);
    const float r = 0.6;

    float ang = time * 0.03;
    vec3 from = vec3(0, 3, -10) + roty(vec3(0, 0, 12), ang);
    vec3 dir = normalize(roty(rotx(getScreenRay(gl_FragCoord.xy), 0.1), ang));
    
    vec3 sumCol = vec3(0);
    float sumf = 1.0;
    for (int bounce = 0; bounce < 4; bounce++) {    
        vec4 d = march(from, dir);

        if (d.w < 0.0)
            break;
        
        // Position and normal
        vec3 p = from + dir * d.w;
        vec3 n = getNormal(p, d.w);

        // Lighting
        float l = lighting(dir, n, 1.5, 2.0, 10.0);
        if (l > 0.0) {
            // Shadow ray
            float s = shadow(p, -light, 16.0);
            l *= s;
        }

        vec3 col = d.xyz * min(l + 0.2, 1.0);
        col *= r;

        // Fog
        float fog = clamp(d.w * d.w / 1200.0, 0.0, 1.0);
        col = mix(col, fogCol, fog);
        
        // Add to sum
        sumCol += col*sumf;
        
        // Calculate reflection vector
        from = p;
        dir = normalize(reflect(dir, n));
  
        sumf *= (1.0 - r) * (1.0 - fog);
    }
    
    sumCol += fogCol * sumf;
    
    glFragColor = vec4(sumCol, 1.0);
}
