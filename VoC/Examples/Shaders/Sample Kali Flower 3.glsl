#version 420

// original https://www.shadertoy.com/view/Xtsyzl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by SHAU - 2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define FAR 50.0 
#define PI 3.1415
#define T time

mat2 rot(float x) {return mat2(cos(x), sin(x), -sin(x), cos(x));}

// IQ - cosine based palette
//http://iquilezles.org/www/articles/palettes/palettes.htm
vec3 palette(in float t) {
    vec3 CP1A = vec3(0.5, 0.5, 0.5);
    vec3 CP1B = vec3(0.5, 0.5, 0.5);
    vec3 CP1C = vec3(2.0, 1.0, 0.0);
    vec3 CP1D = vec3(0.50, 0.20, 0.25);
    return CP1A + CP1B * cos(6.28318 * (CP1C * t + CP1D));
}

float sdBox(vec3 p, vec3 bc, vec3 b) {    
    vec3 d = abs(bc - p) - b; 
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

vec2 nearest(vec2 old, vec2 new) {
    if (new.x < old.x) return new;
    return old;
}

vec2 map(vec3 rp) {
    
    vec2 msd = vec2(FAR, 0.0);
    
    for (int i = 0; i < 10; i++) {
        float c = 0.36 + sin(PI + T * 0.05) * 0.1;
        float q = 2.0 + sin(PI + T * 0.2);
        rp = abs(rp) / dot(rp, rp) - c;
        msd = nearest(msd, vec2(sdBox(rp, q - vec3(2.0, 0.0, 0.0), vec3(1.0)), float(i)));
    }
    
    return msd;    
}

vec3 march(vec3 ro, vec3 rd) {
 
    float t = 0.0;
    vec3 pc = vec3(0.0);
    
    for (int i = 0; i < 140; i++) {
        vec3 rp = ro + rd * t;
        vec2 ns = map(rp);
        t += clamp(ns.x, 0.05, 0.2);
        float rt = length(rp);
        pc += palette(ns.y * 0.1 + T * 0.1) * exp(ns.x * -ns.x * 400.) * 0.08 * exp(rt * -rt * 0.05);;
    }
    
    return pc;
}

void setupCamera(vec2 gl_FragCoord, out vec3 ro, out vec3 rd) {
    
    //coordinate system
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    
    vec3 lookAt = vec3(0);
    ro = vec3(0.0, 0.0, -10.0 + sin(T * 0.2) * 8.0);
    ro.xz *= rot(T);
    ro.xy *= rot(T * 0.5);
    // Using the above to produce the unit ray-direction vector.
    float FOV = PI / 4.; // FOV - Field of view.
    vec3 forward = normalize(lookAt.xyz - ro.xyz);
    vec3 right = normalize(vec3(forward.z, 0., -forward.x )); 
    vec3 up = cross(forward, right);    
    rd = normalize(forward + FOV * uv.x * right + FOV * uv.y * up);
}

void main(void) {
    
    vec3 pc = vec3(0.0);
    vec3 lp = vec3(4.0, 5.0, -2.0);
    
    vec3 ro, rd;
    setupCamera(gl_FragCoord.xy, ro, rd);
    
    pc = march(ro, rd);
    
    glFragColor = vec4(sqrt(clamp(pc, 0., 1.)), 1.0);
}
