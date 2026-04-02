#version 420

// original https://www.shadertoy.com/view/Wllfzl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "RayMarching starting point" 
// by Martijn Steinrucken aka BigWings/CountFrolic - 2020
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// 
// You can use this shader as a template for ray marching shaders

#define MAX_STEPS 1000
#define MAX_DIST 100.
#define SURF_DIST .001

#define S smoothstep

mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

float Hash21(vec2 p) {
    p = fract(p*vec2(123.34,233.53));
    p += dot(p, p+23.234);
    return fract(p.x*p.y);
}

float sdBox(vec3 p, vec3 s) {
    p = abs(p)-s;
    return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
}

float GetDist(vec3 p) {
    float move = -time;
    
    vec3 pl = p;
    pl.y += move;
    pl.xz *= Rot(pl.y);
    float plane1 = dot(pl, normalize(vec3(0, 0,  1))) + 1.5;
    float plane2 = dot(pl, normalize(vec3(0, 0,  -1))) + 1.5;
    float planes = min(plane1, plane2);
    planes *= 0.1;

    vec3 gp = p;
    gp.x += time / 2.;
    gp.y += move * 5.;
    float gscale = 4.;//1. + 3. * (0.5 + 0.5 * sin(p.y / 1.));
    float gyroid = dot(sin(gp * gscale), cos(gp.zxy * gscale)) - 1.4 - 0.2 * (S(-5., 0., p.y));
    gyroid *= 0.1;

    gp = p;
    gp.x += time / 2.;
    gp.y += move * 5.;
    gscale = 7.;
    float gyroid2 = dot(sin(gp * gscale), cos(gp.zxy * gscale)) - 0.5 - 1.2 * (S(-5., 0., p.y));
    gyroid2 *= 0.1;

    return max(-planes, gyroid+gyroid2);
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
        c = f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i);
    return d;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 m = mouse*resolution.xy.xy/resolution.xy;
    
    vec3 col = vec3(0);
    
    vec3 ro = vec3(0, 0, 0);
    
    //ro.yz *= Rot(-m.y*3.14+1.);
    //ro.xz *= Rot(-m.x*6.2831);
    
    vec3 rd = GetRayDir(uv, ro, ro + vec3(0.0001, 1, 0), 1.);

    float d = RayMarch(ro, rd);
    
    if(d<MAX_DIST) {
        vec3 p = ro + rd * d;
        vec3 n = GetNormal(p);
        
        //col += n;
        //col += vec3(S(80., 100., d));
        float dif = dot(n, normalize(ro + vec3(0,0,0.5)))*.5+.5;
        col += dif;  
    }
    
    col = pow(col, vec3(.4545));    // gamma correction
    col = vec3(S(0., -10., d));    // gamma correction
    
    glFragColor = vec4(col,1.0);
}
