#version 420

// original https://www.shadertoy.com/view/WdsyzH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Base code:
///// "RayMarching starting point" 
//// by Martijn Steinrucken aka BigWings/CountFrolic - 2020
//// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define MAX_STEPS 200
#define MAX_DIST 100.
#define SURF_DIST .001

#define S(a, b, t) smoothstep(a, b, t)
#define M(x, y) (x-y*floor(x/y)) 

mat2 Rot(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

float sdBox(vec3 p, vec3 s) {
    p = abs(p)-s;
    return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
}

float sdGyroid(vec3 p, float scale, float thickness, float bias) {
    p *= scale;
    return abs(dot(sin(p), cos(p.zxy))+bias)/scale - thickness;
}

float sdLine(vec3 p, vec3 o, vec3 dir, float t) {
    vec3 a = o;
    vec3 b = a+dir;
    vec3 bMinusA = b-a;
    float h = min(t, max(-t, dot((p-a), bMinusA)/dot(bMinusA,bMinusA)));
    //float h = dot(p-a, bMinusA)/dot(bMinusA,bMinusA);
    float dist = length(p - a +-(b-a) * h )- 0.05;
    return dist;
}

mat3 rx(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat3(1,0,0,0,c,-s,0,s,c);
}
mat3 ry(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat3(c,0,s,0,1,0,-s,0,c);
}
mat3 rz(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat3(c,-s,0,s,c,0,0,0,1);
}

float GetDist(vec3 p) {
    vec3 pp = abs(p);
    float dist = MAX_DIST+1.;
    float x =0.5, y=0.5, z = 0.5;
    float t1 = .5+0.5*sin(time);
    float t2 = .5+0.5*cos(time*2.);
    float t3 = .5+0.5*sin(3.*time+3.141592);
    dist = min(dist, sdLine(pp, vec3(x,y,z), vec3(1,0,0), t1));
    dist = min(dist, sdLine(pp, vec3(x,y,z), vec3(0,1,0), t2));
    dist = min(dist, sdLine(pp, vec3(x,y,z), vec3(0,0,1), t3));
 
    p *= rx(1.+0.25*cos(time))*ry(1.+0.25*cos(time))*rz(1.+0.25*sin(time));
    dist = min(dist, sdLine(p, vec3(0), vec3(0,0,1), 10.));
    dist = min(dist, sdLine(p, vec3(0), vec3(0,1,0), 10.));
    dist = min(dist, sdLine(p, vec3(0), vec3(1,0,0), 10.));
    return dist;
}

float RayMarch(vec3 ro, vec3 rd) {
    float dO=0.;
    
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO;
        float dS = GetDist(p);
        dO += dS;
        if(dO>MAX_DIST || abs(dS)<SURF_DIST) break;
    }
    
    return dO;
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p);
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
    
    return normalize(n);
}

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = p+f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i-p);
    return d;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 m = mouse*resolution.xy.xy/resolution.xy;
    
    vec3 col = vec3(1);
    
    vec3 ro = 3.*vec3(cos(time/2.), sin(time/3.), -sin(cos(time)));
    ro.yz *= Rot(-m.y*3.14+1.);
    ro.xz *= Rot(-m.x*6.2831);
    
    vec3 rd = GetRayDir(uv, ro, vec3(0), 1.);

    float d = RayMarch(ro, rd);
    col *= 0.5+0.5*rd.y;

    
    if(d<MAX_DIST) {
        vec3 p = ro + rd * d;
        vec3 n = GetNormal(p);
        
        float dif = dot(n, normalize(vec3(1,2,3)))*.5+.5;
        col += vec3(dif/(d*d));
        col*=0.5+0.5*n.y;
    }
    
    col = pow(col, vec3(.4545));    // gamma correction
    
    glFragColor = vec4(col,1.0);
}
