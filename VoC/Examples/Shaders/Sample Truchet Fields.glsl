#version 420

// original https://www.shadertoy.com/view/ldffz8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by SHAU - 2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define T time
#define EPS 0.0001
#define PI 3.1415926535
#define FAR 40.

// Frequencies and amplitudes of tunnel "A" and "B". See then "path" function. Shane
const float freqA = 0.15;
const float freqB = 0.25;
const float ampA = 2.4;
const float ampB = 1.7;

const float sr = 0.01;

// Shane. The path is a 2D sinusoid that varies over time, depending upon the frequencies, and amplitudes.
vec2 path(in float z) {return vec2(ampA * sin(z * freqA), ampB * cos(z * freqB));}

float rand(vec3 r) { return fract(sin(dot(r.xy,vec2(1.38984*sin(r.z),1.13233*cos(r.z))))*653758.5453); }

vec3 light = vec3(0.0); //light position

int id = 0;

struct Ray {
    vec3 ro; //ray origin
    vec3 rd; //ray direction
};
    
mat2 rot(float x) {
    return mat2(cos(x), sin(x), -sin(x), cos(x));
}

float sdSphere(vec3 rp, vec3 bp, float r) {
    return length(bp - rp) - r;
}

//modified from Truchet Tentacles by WAHa_06x36
//http://www.shadertoy.com/view/ldfGWn
float truchetarc(vec3 pos) {
    float r = length(pos.xz);
    float p = 8.0;  
    float f = pow(abs(r - 0.5), p) + pow(abs(pos.y - 0.5) * 0.25, p);
    f = pow(f, 1.0 / p) - 0.1; //0.1 thickness
    return f; 
}

float truchetcell(vec3 rp) {
    float msd = truchetarc(vec3(rp.x + 0.5, rp.y, rp.z + 0.5));
    return min(msd, truchetarc(vec3(rp.x - 0.5, rp.y, rp.z - 0.5)));
}

float dfScene(vec3 rp) {
    float msd = sdSphere(rp, light, sr);
    if (msd < EPS) {id = 1;}
    rp.y += 2.0;    
    float rnd = rand(floor(rp));
    if (rnd < 0.25 || (rnd > 0.5 && rnd < 0.75)) {
        rp.xz *= rot(PI * 0.5);
    }
    rp.xz = mod(rp.xz, 1.0) - 0.5;
    return min(msd, truchetcell(rp));
}

vec3 normal(vec3 rp, float t){ 
    
    vec2 e = vec2(t / resolution.y, 0);

    float d1 = dfScene(rp + e.xyy), d2 = dfScene(rp - e.xyy);
    float d3 = dfScene(rp + e.yxy), d4 = dfScene(rp - e.yxy);
    float d5 = dfScene(rp + e.yyx), d6 = dfScene(rp - e.yyx);
    float d = dfScene(rp) * 2.;
     
    return normalize(vec3(d1 - d2, d3 - d4, d5 - d6));
}

float calculateAO(vec3 p, vec3 n){

   const float AO_SAMPLES = 5.0;
   float r = 1.0, w = 1.0, d0;
    
   for (float i=1.0; i<=AO_SAMPLES; i++){
   
      d0 = i/AO_SAMPLES;
      r += w * (dfScene(p + n * d0) - d0);
      w *= 0.5;
   }
   return clamp(r, 0.0, 1.0);
}

// IQ - cosine based palette
vec3 palette1(in float t) {
    vec3 CP1A = vec3(0.5, 0.5, 0.5);
    vec3 CP1B = vec3(0.5, 0.5, 0.5);
    vec3 CP1C = vec3(2.0, 1.0, 0.0);
    vec3 CP1D = vec3(0.50, 0.20, 0.25);
    return CP1A + CP1B * cos(6.28318 * (CP1C * t + CP1D));
}

struct DI {
    float t; //distance marched
    float lli; //lower light
    float fli; //flying light
};

DI marchScene(Ray ray) {
 
    float t = 0.0;
    vec3 rp = vec3(0.0);
    float lli = 0.0;
    float fli = 0.0;
    
    for (int i = 0; i < 100; i++) {
        rp = ray.ro + ray.rd * t;
        float ns = dfScene(rp);
        if (ns < EPS || ns > FAR) break;
        t += ns;
        
        float ld = length(-2.0 - rp.y);
        float fd = length(light - rp) - sr;
        lli += 0.0125 / (ld * ld);
        fli += 0.0025 / (fd * fd);
    }
    
    return DI(t, lli, fli);
}

Ray setupCamera(vec2 uv) {
    
    Ray ray = Ray(vec3(0.0), vec3(0.0));
    
    //camera
    light = vec3(0.0, 1.5, 0.0 + T * 4.0);  // Light & "Look At" position.
    ray.ro = light + vec3(0.0, 0.0, -2.0);
    
    // Using the Z-value to perturb the XY-plane.
    // Sending the camera, light vector along the "path" function
    // synchronized with the distance function.
    light.xy += path(light.z);
    ray.ro.xy += path(ray.ro.z);
    
    // Using the above to produce the unit ray-direction vector.
    float FOV = PI / 4.; // FOV - Field of view.
    vec3 forward = normalize(light - ray.ro);
    vec3 right = normalize(vec3(forward.z, 0., -forward.x )); 
    vec3 up = cross(forward, right);
    
    ray.rd = normalize(forward + FOV * uv.x * right + FOV * uv.y * up);
    
    return ray;
}

void main(void) {
    
    vec3 pc = vec3(0);
    vec3 lc = palette1(T * 0.01);
    
    //coordinate system
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    
    Ray ray = setupCamera(uv);

    DI di = marchScene(ray);
    
    if (di.t > 0.0 && di.t < FAR && id != 1) {
        
        vec3 rp = ray.ro + ray.rd * di.t;
        vec3 n = normal(rp, di.t);        
        
        float spec = pow(max(dot(reflect(-normalize(light), n), -ray.rd), 0.), 12.); // Specular.
        float d = length(light - ray.ro);
        float ao = calculateAO(rp, n);

        pc = spec * 2.0 * lc * ao / d * d;
        float fog = 1.0 - exp(-di.t * di.t * 0.5 / FAR);
        pc = mix(pc, vec3(0.0), fog);
    }
    
    pc = mix(pc, vec3(1.0, 0.0, 0.0) * di.lli, 0.5);
    pc += lc * smoothstep(0.0, 1.2, di.fli) + vec3(1.) * 0.5 * smoothstep(.8, 1.24, di.fli);
    
    glFragColor = vec4(sqrt(clamp(pc, 0., 1.0)), 1);
}
