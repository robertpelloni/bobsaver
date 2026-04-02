#version 420

// original https://www.shadertoy.com/view/Xlccz7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// ponk (Leon Denise) 19/07/2018
// most lines below are from the shadertoy community
// licensed under hippie love conspiracy
// happy tweaking

// Geometry
float range = .8;
float radius = .4;
float blend = .3;
const float count = 8.;

// Light
vec3 lightPos = vec3(1, 1, 1);
float specularSharpness = 10.;
float glowSharpness = 1.;

// Colors
vec3 ambient = vec3(.1);
vec3 light = vec3(0);
vec3 specular = vec3(1);
vec3 glow = vec3(1);

// Raymarching
const float epsilon = .0001;
const float steps = 100.;
const float far = 10.;
#define repeat(p,r) (mod(p,r)-r/2.)
#define sdist(p,r) (length(p)-r)
float box (vec3 p, vec3 b) { vec3 d = abs(p) - b; return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0)); }
float torus (vec3 p, vec2 t) { vec2 q = vec2(length(p.xz)-t.x,p.y); return length(q)-t.y; }
float smoothmin (float a, float b, float r) { float h = clamp(.5+.5*(b-a)/r, 0., 1.); return mix(b, a, h)-r*h*(1.-h); }
mat2 rot (float a) { float c=cos(a),s=sin(a); return mat2(c,-s,s,c); }
vec3 look (vec3 eye, vec3 target, vec2 anchor) {
    vec3 forward = normalize(target-eye);
    vec3 right = normalize(cross(forward, vec3(0,1,0)));
    vec3 up = normalize(cross(right, forward));
    return normalize(forward + right * anchor.x + up * anchor.y);
}

// Miscellaneous
#define time time*.4
#define PI 3.14159
#define TAU 6.28318
#define PIHALF 1.7079
#define PIQUART 0.785397
#define saturate(p) clamp(p,0.,1.)
float random (in vec2 st) { return fract(sin(dot(st.xy, vec2(12.9898,78.233)))* 43758.5453123); }

float geometry (vec3 pos)
{
    float scene = 10.;
    vec3 p = pos;
    for (float index = count; index > 0.; --index) {
        float ratio = index / count;
        
        // easing
        ratio *= ratio;
        
        // domain reptition and translation offset
        p.xz = abs(p.xz) - range * ratio;
        
        // rotations
        p.xz *= rot(PIQUART);
        p.yz *= rot(time);
        //p.yx *= rot(PIHALF);

        scene = smoothmin(scene, box(p, vec3(radius * ratio)), blend * ratio);
    }
    return scene;
}

vec3 getNormal (vec3 p) {
    vec2 e = vec2(epsilon,0);
    return normalize(vec3(geometry(p+e.xyy)-geometry(p-e.xyy),
                          geometry(p+e.yxy)-geometry(p-e.yxy),
                          geometry(p+e.yyx)-geometry(p-e.yyx)));
}

void raymarching (vec3 pos, vec3 ray, inout vec4 hit)
{
    float total = 0.;
    for (float i = steps; i >= 0.; --i) {
        float dist = geometry(pos);
        if (dist < epsilon * total || total > far) {
            hit.xyz = pos;
            hit.w = i/steps;
            break;
        }
        total += dist;
        pos += ray * dist;
    }
}

void main(void) //WARNING - variables void ( out vec4 color, in vec2 coordinate ) need changing to glFragColor and gl_FragCoord
{    
    vec2 coordinate = gl_FragCoord.xy;
    vec4 color = glFragColor;
    vec2 mouse = mouse*resolution.xy.xy / resolution.xy;
    mouse.x = (mouse.x * 2. - 1.) * PI;
    mouse.y *= 1.5;
    
    vec2 uv = (coordinate.xy-.5*resolution.xy)/resolution.y;
    vec3 eye = vec3(0,2,2) * (2. - mouse.y);
    vec3 target = vec3(0);
    vec4 hit;
    
    eye.xz *= rot(mouse.x);
    lightPos.xz *= rot(time);
    
    vec3 ray = look(eye, target, uv);
    raymarching(eye, ray, hit);
    
    vec3 pos = hit.xyz;
    vec3 normal = getNormal(pos);
    vec3 lightDir = normalize(lightPos);
    float lightIntensity = clamp(dot(lightDir, normal),0.,1.);
    float specularIntensity = saturate(pow(max(0., dot(reflect(lightDir, normal), ray)), specularSharpness));
    float glowIntensity = saturate(pow(abs(1.-abs(dot(normal, ray))), glowSharpness));

    color.rgb = ambient + light * lightIntensity + specular * specularIntensity + glow * glowIntensity;
    color.rgb *= hit.w;
    color.rgb *= step(length(eye-pos), far);
    //color.rgb = normal * .5 + .5;
    glFragColor = color;
}
