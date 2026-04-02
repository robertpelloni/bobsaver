#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/WtKGDw

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by SHAU - 2020
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//-----------------------------------------------------

#define R resolution.xy
#define EPS 0.005
#define FAR 50.0
#define ZERO (min(frames,0))
#define T time
#define PI 3.141592

#define UI0 1597334673U
#define UI1 3812015801U
#define UI2 uvec2(UI0, UI1)
#define UI3 uvec3(UI0, UI1, 2798796415U)
#define UIF (1.0 / float(0xffffffffU))

#define S(a, b, v) smoothstep(a, b, v)

//Dave Hoskins - improved hash without sin
//https://www.shadertoy.com/view/XdGfRR
vec2 hash22(vec2 p)
{
    uvec2 q = uvec2(ivec2(p))*UI2;
    q = (q.x ^ q.y) * UI2;
    return vec2(q) * UIF;
}

float hash12(vec2 p) 
{
    uvec2 q = uvec2(ivec2(p)) * UI2;
    uint n = (q.x ^ q.y) * UI0;
    return float(n) * UIF;
}

float hash11(float p)
{
    uvec2 n = uint(int(p)) * UI2;
    uint q = (n.x ^ n.y) * UI0;
    return float(q) * UIF;
}

//noise IQ - Shane
float n3D(vec3 p) 
{    
    const vec3 s = vec3(7, 157, 113);
    vec3 ip = floor(p); 
    p -= ip; 
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    p = p * p * (3. - 2. * p);
    h = mix(fract(sin(h) * 43758.5453), fract(sin(h + s.x) * 43758.5453), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z);
}

//Nimitz
float tri(float x) {return abs(x - floor(x) - 0.5);}
//Fabrice - compact rotation
mat2 rot(float x) {return mat2(cos(x), sin(x), -sin(x), cos(x));}

//Shane - Perspex Web Lattice - one of my favourite shaders
//https://www.shadertoy.com/view/Mld3Rn
//Standard hue rotation formula... compacted down a bit.
vec3 rotHue(vec3 p, float a)
{
    vec2 cs = sin(vec2(1.570796, 0) + a);

    mat3 hr = mat3(0.299,  0.587,  0.114,  0.299,  0.587,  0.114,  0.299,  0.587,  0.114) +
              mat3(0.701, -0.587, -0.114, -0.299,  0.413, -0.114, -0.300, -0.588,  0.886) * cs.x +
              mat3(0.168,  0.330, -0.497, -0.328,  0.035,  0.292,  1.250, -1.050, -0.203) * cs.y;
                             
    return clamp(p*hr, 0., 1.);
}

//SDF functions - IQ
//https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdBox(vec3 p, vec3 b) 
{
    vec3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float sdCapsule(vec3 p, vec3 a, vec3 b, float r) 
{
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba*h) - r;
}

float sdSphere(vec3 p, float r)
{
    return length(p) - r;
}

/*
vec3 opRepLim(vec3 p, float c, vec3 l)
{
    return p-c*clamp(round(p/c),-l,l);
}
*/

//IQ - Intesectors, sphere and box functions
//https://iquilezles.org/www/index.htm
vec2 sphIntersect(vec3 ro, vec3 rd, vec4 sph) {
    vec3 oc = ro - sph.xyz;
    float b = dot(oc, rd);
    float c = dot(oc, oc) - sph.w * sph.w;
    float h = b * b - c;
    if (h < 0.0) return vec2(-1.0); //missed
    h = sqrt(h);
    float tN = -b - h;
    float tF = -b + h;
    return vec2(tN, tF);
}

float sphDensity(vec3 ro, vec3 rd, vec4 sph, float dbuffer) {

    float ndbuffer = dbuffer / sph.w;
    vec3  rc = (ro - sph.xyz) / sph.w;

    float b = dot(rd, rc);
    float c = dot(rc, rc) - 1.0;
    float h = b * b - c;
    if (h < 0.0) return 0.0;
    h = sqrt(h);
    float t1 = -b - h;
    float t2 = -b + h;

    if (t2 < 0.0 || t1 > ndbuffer) return 0.0;
    t1 = max(t1, 0.0);
    t2 = min(t2, ndbuffer);

    float i1 = -(c * t1 + b * t1 * t1 + t1 * t1 * t1 / 3.0);
    float i2 = -(c * t2 + b * t2 * t2 + t2 * t2 * t2 / 3.0);
    return (i2 - i1) * (3.0 / 4.0);
}

vec3 sphNormal(vec3 pos, vec4 sph) 
{
    return normalize(pos - sph.xyz);
}

vec2 boxes(vec3 p)
{
    p.z += T;
    vec3 q = p;    
    q.y = abs(q.y);
    q.xz = fract(p.xz*0.125)*8.0 - 4.0;
    return vec2(sdBox(q - vec3(0.0, 8.0, 0.0), vec3(3., 0.3, 3.0)), 
                hash12(floor(p.xz*0.125)));
}

vec4 map(vec3 p)
{
    vec2 b = boxes(p);
    
    /*
    vec3 q = p;
    q += vec3(-8.0, -0.0, 3.0);
    float l = sin(p.x*3.0)*3.0 * min(1.0, p.x*0.08) * max(0.0, (1.0 - p.x*0.08));
    q.xy *= rot(sin(p.x*2.0+T*1.2)*0.16);
    q.xz *= rot(sin(p.x*2.0+T*2.8)*0.2);
    q = opRepLim(q, 0.25, vec3(30.0, 0.0, 0.0));
    q.yz *= rot(floor(p.x*4.0)*0.1+T*0.9);
    float cs = sdCapsule(q, vec3(0.0, -1.0*l, 0.0), vec3(0.0, 1.0*l, 0.0), 0.02);
    cs = max(cs, -sdSphere(p, 3.0));
    //*/
    
    //capsule stream
    //right
    vec3 q = p;
    q += vec3(0.0, -2.0, 2.0);
    float l = sin(p.x*2.0)*3.0 * min(1.0, p.x*0.08) * max(0.0, (1.0 - p.x*0.08));  
    q.xy *= rot(sin(p.x+T*1.2)*0.1);
    q.xz *= rot(sin(p.x+T*0.8)*0.1);
    q.x = fract(p.x*4.0)*0.25 - 0.125;
    q.yz *= rot(floor(p.x*4.0)*0.1+T*0.9);
    float cs = sdCapsule(q, vec3(0.0, -1.0*l, 0.0), vec3(0.0, 1.0*l, 0.0), 0.01);
    cs = p.x>0.0 && p.x<20.6 ? cs : FAR;
    //noise line
    //left
    q = p;
    q.y += sin(q.x*2.0+T*6.)*0.2 + sin((q.x - 4.2)*3.2+T*13.3)*0.1;
    q.z += sin((q.x - 1.3)*1.7+T*5.)*0.2 + sin((q.x - 5.9)*3.2+T*7.1)*0.14;
    q.yz += tri(q.x*0.31 + T*3.6)*0.2;
    q.xz += tri(q.x*0.7 + T*1.6)*0.8;
    cs = min(cs, sdCapsule(q, vec3(-20.0, -7.0 + sin(T*0.4)*2.0, -4.0 + sin((T-3.1)*0.14)), vec3(0.0, -2.0, 0.0), 0.01));
    //cutout
    cs = max(cs, -sdSphere(p, 3.0));

    return vec4(min(cs, b.x), cs, b.x, b.y);
}

// particles (Andrew Baldwin)
// stolen from Galvanize by Virgill 
float snow(vec3 direction) {
    float help = 0.0;
    const mat3 p = mat3(13.323122,23.5112,21.71123,21.1212,28.7312,11.9312,21.8112,14.7212,61.3934);
    vec2 uvx = vec2(direction.x,direction.z)+vec2(1.,resolution.y/resolution.x)*gl_FragCoord.xy / resolution.xy;
    float acc = 0.0;
    float DEPTH = direction.y*direction.y-0.3;
    float WIDTH =0.1;
    float SPEED = 0.1;
    for (int i=0;i<10;i++) {
        float fi = float(i);
        vec2 q = uvx*(1.+fi*DEPTH);
        q += vec2(q.y*(WIDTH*mod(fi*7.238917,1.)-WIDTH*.5),SPEED*time/(1.+fi*DEPTH*.03));
        vec3 n = vec3(floor(q),31.189+fi);
        vec3 m = floor(n)*.00001 + fract(n);
        vec3 mp = (31415.9+m)/fract(p*m);
        vec3 r = fract(mp);
        vec2 s = abs(mod(q,1.)-.5+.9*r.xy-.45);
        float d = .7*max(s.x-s.y,s.x+s.y)+max(s.x,s.y)-.01;
        float edge = .04;
        acc += smoothstep(edge,-edge,d)*(r.x/1.0);
        help = acc;
    }
    return help;
}

/*
vec3 overlay(vec2 uv)
{
    vec2 ruv = uv*rot(sin(T*0.03));
    ruv.x += (sin(ruv.y*4.0 + T*0.3) * 0.08);
    vec2 c = fract(ruv*vec2(20.0, 12.0)) - 0.5;
    float cH = hash12(floor(ruv*vec2(20.0, 12.0)));
    
    vec3 col = palette(cH*10000.) * S(0.16+cH*0.1, 0.1+cH*0.1, length(c)); //dots
    //vignette
    col *= S(0.0, 0.1, uv.x) * S(1.0, 0.9, uv.x) * 
           S(0.0, 0.1, uv.y) * S(1.0, 0.9, uv.y);
    return col;
}
*/

//background
vec3 background(vec3 rd, vec3 colA, vec3 colB)
{
    //radial lines
    float a = (atan(rd.x, rd.y)/6.2831853) + 0.5, //0->1
          l = floor(a * 24.0) / 24.0; //partition cells    
    vec3 pc = colB * 2.0 *
              S(0.46, 0.5, fract(a*24.0)) * S(0.54, 0.5, fract(a*24.0));
    //horizontal lines
    float dY = pow(abs(rd.y), 0.8), //problem with power - thanks iapafotoo
          cY = fract(dY*6.0-T*0.4),
          cYID = floor(dY*6.0-T*0.4),
          cYH = hash11(cYID) - 0.6,    
          tt = mod(T*cYH*4.0*sign(rd.y), 3.0) - 1.5,
          dX = length(tt - rd.x);
    pc += colB * 1.6 * S(0.02, 0.0, length(cY - 0.5)); //lines
    //noise
    pc *= (2.0 +n3D(rd*3.6+T)) * n3D(rd*5.0+T*0.3);
    //sparks
    pc += (cYH*sign(-rd.y)>0.0 ? step(tt, rd.x) : step(rd.x, tt)) * //clip
          colA * 6.0 * S(0.05, 0.0, length(cY - 0.5)) / //line 
          (1.0 + dX*dX*60.); //attenuation 
    //fade
    pc *= max(abs(rd.y*0.4), 0.);
    //center glow
    pc += colB / ((1.0 + abs(rd.x)*abs(rd.x)*8.0) * (1.0 + dY*dY*100.0));

    return pc;
}

vec4 renderScene(vec3 ro, vec3 rd, vec3 lp, vec3 colA, vec3 colB)
{
    float t = 0.0;
    vec3 pc = background(rd, colA, colB); 
    
    for (int i=ZERO; i<80; i++)
    {
        vec3 p = ro + rd*t;
        vec4 ns = map(p);
        //if (abs(ns.x)<EPS && ns.x==ns.y) break;
        pc += 0.3 * colA / (1.0 + ns.y*ns.y*200.0);
        float atn = 1.0 / (1.0 + length(p-ro)*length(p*ro)*0.0001);
        pc += step(ns.z, EPS) * step(ns.w, 0.4) * //clip 
              0.008 * colB / (1.0 + ns.z*ns.z*30.0) * atn;
        t += max(EPS*2.0, ns.x * 0.6);
        if (t>FAR) break;
    }    
        
    return vec4(pc, t);
}

vec3 camera(vec2 U, vec3 ro, vec3 la, float fl) 
{
    vec2 uv = (U - R*.5) / R.y;
    vec3 fwd = normalize(la-ro),
         rgt = normalize(vec3(fwd.z, 0., -fwd.x));
    return normalize(fwd + fl*uv.x*rgt + fl*uv.y*cross(fwd, rgt));
}

void main(void)
{
    vec2 U = gl_FragCoord.xy;

    vec3 col = vec3(0),
         la = vec3(0),
         colA = rotHue(vec3(1,0,0), T*0.1),
         colB = rotHue(vec3(1,0,0), (T-3.0)*0.1),
         ro = vec3(0.0, sin(T*0.1)*2.0, -11.0 - sin(T*0.2)*2.0);
    
    ro.xz *= rot(sin((T+5.0)*0.3)*0.3);
    vec3 rd = camera(U, ro, la, 1.4);
    vec3 lp = vec3(3.0, 4.0, -2.0);
    
    vec4 scene = renderScene(ro, rd, lp, colA, colB);
    col = scene.xyz;
    
    vec4 sph = vec4(0.0, 0.0, 0.0, 3.0);
    vec2 si = sphIntersect(ro, rd, sph);
    float sd = sphDensity(ro,rd, sph, FAR);
    if (si.x>0.0)
    {
        
        col *= scene.y==2.0 ? 0.0 : 0.4;
        vec3 pN = ro + rd*si.x;
        vec3 pF = ro + rd*si.y;
        
        vec3 nN = sphNormal(pN, sph);
        vec3 nF = sphNormal(pF, sph) * -1.0;
        
        vec3 ldN = normalize(lp - pN);
        vec3 ldF = normalize(lp - pF);
        
        float specN = pow(max(dot(reflect(-ldN, nN), -rd), 0.0), 16.0);
        float specF = pow(max(dot(reflect(-ldF, nF), -rd), 0.0), 16.0);
        float fres = pow(clamp(dot(nN, rd) + 1.0, 0.0, 1.0), 2.0);

        col += colA * pow(sd, 4.0) * max(0.0, (sin(T*4.0)+0.5) * 0.6);
        
        col += vec3(1) * specN;  
        col += vec3(1) * specF*0.2;  
        
        //reflection
        vec3 rro = pN;
        vec3 rrd = reflect(rd, nN);
        vec4 rScene = renderScene(rro, rrd, lp, colA, colB);
        col += rScene.xyz * fres;
    }
    
    col += colA*2.0*snow(normalize(vec3(0.0, 0.0, -1.0)));
    
    glFragColor = vec4(col, 1.0);
}
