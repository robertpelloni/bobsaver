#version 420

// original https://www.shadertoy.com/view/wsf3DB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEP 100
#define MIN_DIST 0.01
#define MAX_DIST 30.
#define FOV_PARAM 2.
#define SURF_SHIFT 0.1

// 0.8, 0.5, 0.4        0.2, 0.4, 0.2    2.0, 1.0, 1.0    0.00, 0.25, 0.25
vec3 palette( in float t ){
    float wave = sin(time * .5) * 0.5 + 0.5;
    vec3 a = vec3(.8, 0.5, .4);
    vec3 b = vec3(.2, .4, .2);
    vec3 c = vec3(2., 1., 1.);
    vec3 d = vec3( 1. * wave, .25, .25);
    return a + b*cos( 6.28318*(c*t+d) );
}

mat2 rot2d(float a) {
    float c = cos(a);
    float s = sin(a);
    
    return mat2(c, s, -s, c);
//    return mat2(c, s, c, s);
}

float GetDistSphere(vec3 p, vec4 sphere) {
     return length(p - sphere.xyz) - sphere.w;   
}

float GetDistPlane(vec3 p, float d) {
    return p.y + d;
}

float GetDistRepSphere(vec3 p, vec4 sphere, vec3 c) {
    vec3 q = mod(p, c) - 0.5 * c;
    
    return GetDistSphere(q, sphere);
}
/*
float GetDist_(vec3 p) {
    vec4 sphere = vec4(0, 0, 1, 0.5);
    float planeDist = .5;
    float d = GetDistSphere(p, sphere);
    d = min(d, GetDistPlane(p, planeDist));
    
    return d;
}
*/

float GetDist(vec3 p) {
    p.xy *= rot2d(sin(1. * time) * p.z / 10.);
    float wave      = cos(2. * time) * 0.5 + 0.5;
    vec3 repSphere  = vec3(1, 1, 1);
    vec4 sphere     = vec4(0, 0, .5, .3);
    float planeDist = MAX_DIST;
    float dSphere   = GetDistRepSphere(p, sphere, repSphere);
    float dPlane    = GetDistPlane(p, planeDist);
    float d         = min(dSphere, dPlane);

    /*float wave = sin(time) * 0.5 + 0.5;
    float d = (dSphere + (wave * 10. * dPlane)) / (1. + 10. * wave);
    */
    return d;
}

vec3 GetNormal(vec3 p) {
    vec2 e = vec2(0.01, 0);
    
    vec3 n = GetDist(p) - vec3(
        GetDist(p - e.xyy),
        GetDist(p - e.yxy),
        GetDist(p - e.yyx)
    );
    
    return normalize(n);
}

float RayMarch(vec3 ro, vec3 rd) {
    float d = 0.;
    
    for (int i = 0; i < MAX_STEP; i++) {
//        rd.xyz          = rd.yzx;
        vec3 p      = ro + d * rd;
           float dist  = GetDist(p);
        d          += dist;
        
        if (dist < MIN_DIST || dist > MAX_DIST) break;
    }
    
    return d;
}

float GetLight(vec3 p, vec3 light) {
    vec3 toLight = light - p;
    vec3 n       = GetNormal(p);
    float dif    = dot(n, normalize(toLight));
    float dScene = RayMarch(p + SURF_SHIFT * n, normalize(toLight));
    
    if (dScene < length(toLight)) dif *= 0.1;
    
    return dif;
}

void main(void)
{
    vec2 uv          = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    uv.xy           *= FOV_PARAM * sin(time); 
    vec3 col         = vec3(0);
    vec3 ro          = vec3(0.125, 3., 1);
//    vec2 roRotCenter = vec2(0, 2);
    vec2 roRotCenter = vec2(3, 3);
    ro.xy            = (ro.xy - roRotCenter) * rot2d(.5 * time) + (.1 * sin(time)) * roRotCenter; 
    vec3 rd          = normalize(vec3(uv.x, uv.y, 1));
    vec3 light       = vec3(1, 1, 0.5);
    float d          = RayMarch(ro, rd);
    vec3 p           = ro + d * rd;
    float dif        = GetLight(p, light);
    float wave       = sin(time) * 0.5 + 0.5;
    vec3 palCol      = palette(d / 50.);
//    col              = palCol * dif;
    col              = palCol;
//    col              = vec3(dif);
    glFragColor        = vec4(col,1.0);
}
