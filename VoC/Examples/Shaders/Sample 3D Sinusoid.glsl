#version 420

// original https://www.shadertoy.com/view/WtKcWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rotate(float a) {
    float si = sin(a), co = cos(a);
    return mat2(co, si, -si, co);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float sdBox(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

vec3 id = vec3(0);
float map(in vec3 p) {
    float scale = 40.;
    p *= scale;
    vec3 pmod = mod(p, 2.0) - 1.; 
    vec3 pint = p - pmod;
    id = pint;
    float period = 6.;
    float t = (time + 9.24) * 2.;
    float size = (sin(period*pint.x + t) 
               +  sin(period*pint.y + t) 
               +  sin(period*pint.z)) 
               * 0.5;
    float roundness = 0.05;
    pmod.xz *= rotate(size);
    float sizeBox = size * 2. * (0.5 - roundness);
    float box = sdBox(pmod, vec3(sizeBox)*.5) - roundness;
    return box/scale;

}

#define MIN_MARCH_DIST 0.0001
#define MAX_MARCH_DIST 40.
#define MAX_MARCH_STEPS 60.
float march(in vec3 ro, in vec3 rd) {
    float t = 0.4, // don't render too close to camera
          i = 0.;
    for(i=0.; i < MAX_MARCH_STEPS; i++) {
        vec3 p = ro + t*rd;
        float d = map(p);
        if(abs(d) < MIN_MARCH_DIST)
            break;
        t += d;
        if(t > MAX_MARCH_DIST)
            break;
    }
    if(i >= MAX_MARCH_STEPS) {
        t = MAX_MARCH_DIST;
    }
    return t;
}

vec3 normal(in vec3 p) {
    float eps = MIN_MARCH_DIST;
    vec2 h = vec2(eps, 0);
    return normalize(vec3(map(p+h.xyy) - map(p-h.xyy),
                          map(p+h.yxy) - map(p-h.yxy),
                          map(p+h.yyx) - map(p-h.yyx)));
}

float G1V(float dotNV, float k) {
    return 1.0 / (dotNV * (1.0 - k) + k);
}

// http://filmicworlds.com/blog/optimizing-ggx-shaders-with-dotlh/
float brdf_ggx(vec3 N, vec3 V, vec3 L, float roughness, float F0) {
    float alpha = roughness * roughness;
    vec3 H = normalize(V+L);
    float dotNL = clamp(dot(N,L), 0., 1.);
    float dotNV = clamp(dot(N,V), 0., 1.);
    float dotNH = clamp(dot(N,H), 0., 1.);
    float dotLH = clamp(dot(L,H), 0., 1.);
    float alphaSqr = alpha*alpha;
    float pi = 3.14159;
    float denom = dotNH * dotNH * (alphaSqr - 1.0) + 1.0;
    float D = alphaSqr / (pi * denom * denom);
    float dotLH5 = pow(1.0 - dotLH, 5.0);
    float F = F0 + (1.0 - F0) * dotLH5;
    float k = alpha / 2.0;
    float vis = G1V(dotNL, k) * G1V(dotNV, k);
    return dotNL * D * F * vis;
}

vec3 shade(vec3 N, vec3 L, vec3 V, vec3 diffuse, vec3 specular) {
    return diffuse * clamp(dot(L, N), 0., 1.)       // Lambertian Diffuse
         + specular * brdf_ggx(N, V, L, 0.55, 0.1); // GGX Specular
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;
    
    // Camera
    vec3 ro = vec3(0,0,-1.);
    vec3 ta = vec3(0,0,0);
    vec3 ww = normalize(ta-ro);
    vec3 uu = normalize(cross(ww, vec3(0,1,0)));
    vec3 vv = normalize(cross(uu,ww));
    vec3 rd = normalize(uv.x*uu + uv.y*vv + 1.0*ww);
    float time = (time + 9.24) * 0.1;
    rd.zx *= rotate(time);
    ro.z += time;
    ro.y += time;
    
    // March
    float t = march(ro, rd);
    
    // Shade
    vec3 col = vec3(0);
    if(t < MAX_MARCH_DIST) {
        vec3 P = ro + t*rd;             
        vec3 N = normal(P);                
        vec3 V = normalize(ro - P); 
        vec3 ambient = vec3(.06);
        vec3 diffuse = hsv2rgb(vec3(fract(length(id) / 80. + time * 0.2), 1., 1.));
        vec3 specular = vec3(.9);      
        vec3 tangent = cross(V, vec3(0,1,0));
        col =       shade(N, normalize(ro-P+tangent*0.03), V, diffuse, specular)
            + 0.3 * shade(N, normalize(P-ro+tangent*0.2), V, diffuse, specular)  
            + ambient;                                               
        col *= clamp(exp(-0.20*(t-0.2)), 0., 1.);                       
    }
    
    glFragColor = vec4(pow(col, vec3(2.2)),1.0); // Gamma correction
}
