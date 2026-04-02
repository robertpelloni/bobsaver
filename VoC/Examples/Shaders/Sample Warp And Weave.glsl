#version 420

// original https://www.shadertoy.com/view/MtfSRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// comment out these lines if you need more speed:
#define SHADOWS
#define REFLECTIONS

#define R(p,a) p=cos(a)*p+sin(a)*vec2(-p.y,p.x);
const float PI = 3.141592653589793;
const float threshold = 0.001;
const float maxIters = 50.;
const float ambient = 0.2;
const float maxD = 100.;

vec3 lightPos = vec3(10.);

// materials
int m=0; // material index

float cube(vec4 cube, vec3 pos){
    cube.xyz -= pos;
    return max(max(abs(cube.x)-cube.w,abs(cube.y)-cube.w),abs(cube.z)-cube.w);
}

float df(vec3 p){
    vec3 mp = mod(p, 0.1);
    mp.y = p.y + sin(p.x*2.+time)*.25 + sin(p.z * 2.5 + time)*.25;
    
    float s1 = cube(
        vec4(0.05, 0.05, 0.05, 0.025),
        vec3(mp.x, mp.y + (sin(p.z * PI * 10.) * sin(p.x * PI * 10.)) * 0.025, 0.05));
    float s2 = cube(
        vec4(0.05, 0.05, 0.05, 0.025), 
        vec3(0.05, mp.y + (sin(p.x * PI * 10.) * -sin(p.z * PI * 10.)) * 0.025, mp.z));
    m = s1 < s2 ? 0 : 1;
    return min(s1, s2);
}

vec2 rm(vec3 pos, vec3 dir, float threshold, float td){
    vec3 startPos = pos;
    vec3 oDir = dir;
    float l,i, tl;
    l = 0.;
    
    for(float i=0.; i<=1.; i+=1.0/maxIters){
        l = df(pos);
        if(abs(l) < threshold){
            break;
        }
        pos += (l * dir * 0.7);
    }
    l = length(startPos - pos);
    return vec2(l < td ? 1.0 : -1.0, min(l, td));
}

float softShadow(vec3 pos, vec3 l, float r, float f, float td) {
    float d;
    vec3 p;
    float o = 1.0, maxI = 10., or = r;
    float len;
    for (float i=10.; i>1.; i--) {
        len = (i - 1.) / maxI;
        p = pos + ((l - pos) * len);
        r = or * len;
        d = clamp(df(p), 0.0, 1.0);
        o -= d < r ? (r -d)/(r * f) : 0.;
        
        if(o < 0.) break;
    }
    return o;
}

void main(void)
{
    //vec3 camPos = vec3(0., sin(time*.3)+3., time);
    vec3 camPos = vec3(0., sin(time*.3)+3., cos(time*.3));
    vec3 uv = vec3(gl_FragCoord.xy / resolution.xy, 1.);
    vec3 rayDir = uv;
    rayDir = normalize(rayDir);
    rayDir.yz = R(rayDir.yz, sin(time*.25)*.25+1.1);
    rayDir.xz = R(rayDir.xz, sin(time*.2));
    
    float camDist = length(camPos);
    
    float gd = maxD;
    vec2 march = rm(camPos, rayDir, threshold, gd);
    
    int lm = m;
    vec3 point = camPos + (rayDir * march.g);
    vec2 e = vec2(0.01, 0.0);
    vec3 n = march.x == 1.0 ? 
        (vec3(df(point+e.xyy),df(point +e.yxy),df(point +e.yyx))-df(point))/e.x :
        vec3(0., 1., 0.);
    
    vec3 lightDir = normalize(lightPos);
    float intensity = max(dot(n, lightDir), 0.0) * 0.5;
    vec3 lightPos2 = point + lightDir;
    
#ifdef SHADOWS
    intensity *= 3.;
    intensity *= softShadow(point, point + n, 2.0, 8., gd); // AO
#endif
    
    intensity -= (march.y)*0.02;
    intensity = march.y == maxD ? 0. : intensity;
    vec4 p = vec4(1.0);
    vec3 c;// = clamp(lm == 0 ? vec3(sin(point)) * .25 : vec3(cos(point)), 0., 1.);
    
    ///c += 1.;
    c = lm==1 ? vec3(0.7, 0.3, 0.4) : vec3(0.3, 0.6, 0.8);
    p.rgb = march.x == -1. ? vec3(0.) : vec3(c * (intensity + ambient));
    
    glFragColor = p;
#ifdef REFLECTIONS
    vec4 p2 = vec4(0.,0.,0.,1.);
    n = normalize(n);
    
    vec3 refDir = rayDir - 2. * dot(n,rayDir) * n;
        
    point += refDir * 0.01;
    march = rm(point, refDir, threshold, maxD);
    if(march.y < 0.5){
        point += (refDir * march.y);
        lm = m;
        n = (vec3(df(point+e.xyy),df(point +e.yxy),df(point +e.yyx))-df(point))/e.x;
        intensity = max(dot(n, lightDir), 0.0) * 0.5;
        c = clamp(lm == 0 ? vec3(sin(point)) * .25 : vec3(cos(point)), 0., 1.);
        c += 1.;
        p2.rgb = vec3(c * (intensity + ambient));
    }
    glFragColor = mix(p, p2, 0.2);
#endif
}
