#version 420

// original https://www.shadertoy.com/view/lsSfDK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by SHAU - 2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define T time 
#define EPS 0.005
#define FAR 200.0 
#define PI 3.1415

struct Ray {
    vec3 ro; //ray origin
    vec3 rd; //ray direction 
};

vec3 lp = vec3(-3.3, 5.0, -3.0); //light position
vec3 gc = vec3(0.0);

mat2 rot(float x) {return mat2(cos(x), sin(x), -sin(x), cos(x));}
   
float diffuse(vec3 n, vec3 ld) {return clamp(dot(n, ld), 0.0, 1.0);}
float fresnel(vec3 n, vec3 rd, float k) {return pow(clamp(1.0 + dot(n, rd), 0.0, 1.0), k);}
float specular(vec3 refl, vec3 ld, float k) {return pow(clamp(dot(refl, ld), 0.0, 1.0), k);}
// https://www.shadertoy.com/view/ldSSzV
float specular2(vec3 n, vec3 rp, vec3 rd, vec3 ld, float k) {
    vec3 n2 = normalize(n - normalize(rp) * 0.2);
    vec3 rrd2 = reflect(rd, n2);
    return pow(clamp(dot(rrd2, ld), 0.0, 1.0), 64.0);
}

// IQ - cosine based palette
//http://iquilezles.org/www/articles/palettes/palettes.htm
vec3 palette1(in float t) {
    vec3 CP1A = vec3(0.5, 0.5, 0.5);
    vec3 CP1B = vec3(0.5, 0.5, 0.5);
    vec3 CP1C = vec3(2.0, 1.0, 0.0);
    vec3 CP1D = vec3(0.50, 0.20, 0.25);
    return CP1A + CP1B * cos(6.28318 * (CP1C * t + CP1D));
}

// Calcs intersection and exit distances, and normal at intersection
//
// The box is axis aligned and at the origin, but has any size.
// For arbirarily oriented and located boxes, simply transform
// the ray accordingly and reverse the transformation for the
// returning normal(without translation)
// IQ
vec2 boxIntersection(Ray ray, vec3 boxSize, out vec3 outNormalN, out vec3 outNormalF) {
    vec3 m = 1.0 / ray.rd;
    vec3 n = m * ray.ro;
    vec3 k = abs(m) * boxSize;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    float tN = max(max(t1.x, t1.y ), t1.z);
    float tF = min(min(t2.x, t2.y ), t2.z);
    if( tN > tF || tF < 0.0) return vec2(-1.0); // no intersection
    outNormalN = -sign(ray.rd) * step(t1.yzx, t1.xyz) * step(t1.zxy, t1.xyz);
    outNormalF = -sign(ray.rd) * step(t2.xyz, t2.yzx) * step(t2.xyz, t2.zxy);
    return vec2(tN, tF);
}

vec2 rboxIntersection(Ray ray, vec3 boxSize, out vec3 outNormalN, out vec3 outNormalF) {
    ray.rd.xz *= rot(T);
    ray.ro.xz *= rot(T);
    ray.rd.xy *= rot(T * 0.5);
    ray.ro.xy *= rot(T * 0.5);

    vec2 box = boxIntersection(ray, boxSize, outNormalN, outNormalF);
    
    outNormalN.xy *= rot(-T * 0.5);
    outNormalF.xy *= rot(-T * 0.5);
    outNormalN.xz *= rot(-T);
    outNormalF.xz *= rot(-T);

    return box;
}

float tracePlane(vec3 ro, vec3 rd, vec3 n, vec3 o) {
    return dot(o - ro, n) / dot(rd, n);
}

//From TekF (https://www.shadertoy.com/view/ltXGWS)
float cells(vec3 p) {
    p = fract(p / 2.0) * 2.0;
    p = min(p, 2.0 - p);
    return min(length(p), length(p - 1.0));
}

//Nimitz - https://www.shadertoy.com/view/4lSGRh
float tex(vec3 rp) {
    rp *= 4.0;
    float rz= 0.;
    float z= 1.;
    for (int i = 0; i < 2; i++) { 
        rz += cells(rp) / z;
        rp *= 1.5;
        z *= -1.1;
    }
    return clamp(rz * rz * 2.5, 0., 1.) * 1.;
}

vec4 bump(vec3 rp, vec3 n) {
    float bf = 0.5;
    vec2 e = vec2(EPS / resolution.y, 0.0);
    float tl = tex(rp);
    vec3 grad = (vec3(tex(rp - e.xyy), 
                      tex(rp - e.yxy), 
                      tex(rp - e.yyx)) - tl) / e.x;
    return vec4(normalize(n + grad * bf), tl); 
} 

//Lifted verbatim from Nimitz - lazy me
//https://www.shadertoy.com/view/4ts3z2
float tri(float x) {return abs(fract(x) - .5);}
vec3 tri3(vec3 p) {return vec3(tri(p.z + tri(p.y * 1.)), tri(p.z + tri(p.x * 1.)), tri(p.y + tri(p.x * 1.)));}                       
mat2 m2 = mat2(0.970,  0.242, -0.242,  0.970);

float triNoise3d(vec3 p, float spd) {
    
    float z = 1.4;
    float rz = 0.;
    vec3 bp = p;
    
    for (float i = 0.; i <= 3.; i++) {
        vec3 dg = tri3(bp * 2.);
        p += (dg + T * spd);

        bp *= 1.8;
        z *= 1.5;
        p *= 1.2;
        //p.xz*= m2;
        
        rz+= (tri(p.z + tri(p.x + tri(p.y)))) / z;
        bp += 0.14;
    }
    return rz;
}

float fogmap(vec3 p, float d) {
    
    p.x += T * 1.5;
    p.z += sin(p.x * .5);
    
    return triNoise3d(p * 2.2 / (d + 20.), 0.2) * (1. -smoothstep(0., .7, p.y));
}

vec3 fog(vec3 col, Ray ray, float mt) {
    
    float d = .5;
    
    for (int i = 0; i < 7; i++) {
        vec3  pos = ray.ro + ray.rd * d;
        float rz = fogmap(pos, d);
        float grd =  clamp((rz - fogmap(pos + .8 -float(i) * 0.1, d)) * 3., 0.1, 1.);
        vec3 col2 = (vec3(.1, 0.8, .5) * .5 + .5 * gc * (1.7 - grd)) * 0.55;
        col = mix(col, col2, clamp(rz * smoothstep(d - 0.4, d + 2. + d * .75, mt), 0., 1.));
        d *= 1.5 + 0.3;
        if (d > mt) break;
    }
    
    return col;
}

vec3 colGlass(vec3 rp, vec3 rd, vec3 n, vec3 lc) {
    vec3 gc = vec3(0.);
    vec3 ld = normalize(lp - rp); //light direction
    vec3 refl = reflect(rd, n); //reflected ray direction
    gc += lc * fresnel(n, rd, 4.0);
    gc += lc * specular(refl, ld, 16.0);
    gc += lc * specular2(n, rp, rd, ld, 64.0) * diffuse(n, ld);
    return gc;
}

Ray setupCamera(vec2 uv) {
    vec3 lookAt = vec3(0);
    vec3 camera = vec3(0.0, (sin(T * 0.4) + 1.0) * 0.4 + 0.5, -3.0);
    camera.xz *= rot(T * 0.5);
    //camera.xy *= rot(T * 0.5);
    // Using the above to produce the unit ray-direction vector.
    float FOV = PI / 4.; // FOV - Field of view.
    vec3 forward = normalize(lookAt.xyz - camera.xyz);
    vec3 right = normalize(vec3(forward.z, 0., -forward.x )); 
    vec3 up = cross(forward, right);    
    vec3 rd = normalize(forward + FOV * uv.x * right + FOV * uv.y * up);
    return Ray(camera.xyz, rd);
}

void main(void) {
    
    vec3 pc = vec3(0);
    gc = palette1(T * 0.1);
    
    //coordinate system
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;

    Ray ray = setupCamera(uv);
    
    vec3 fo = vec3(0.0, -2.0, 0.0);
    vec3 fn = vec3(0.0, 1.0, 0.0);

    vec3 nN = vec3(0.0); //near face normal
    vec3 nF = vec3(0.0); //rear face normal
    
    vec2 box = rboxIntersection(ray, vec3(1), nN, nF);
    float ft = tracePlane(ray.ro, ray.rd, fn, fo);
    
    if (ft > 0.0 && ft < FAR) {
   
        vec3 rp = ray.ro + ray.rd * ft;
        fn = bump(rp, fn).xyz;
        vec3 ld = normalize(lp - rp);
        float diff = diffuse(fn, ld);
        
        vec3 nNS = vec3(0);
        vec3 nFS = vec3(0);
        
        float sh = 1.0;
        vec2 boxS = rboxIntersection(Ray(rp, ld), vec3(1), nNS, nFS);
        float gt = length(boxS.y - boxS.x);
        float lt = length(lp - rp);
        if (boxS.x > 0.0 && boxS.x < lt) {
            sh = (boxS.x / lt) / clamp(gt, 0.4, 1.0);    
        }
        
        pc = vec3(0.1) + gc * tex(rp) * 1.0; 
        pc *= diff;
        vec3 rrd = reflect(ray.rd, fn);
        pc += vec3(1.0) * specular(rrd, ld, 16.0);
        pc = fog(pc, ray, ft) * sh;
        
        float fg = 1.0 - exp(-ft * ft * 0.5 / FAR);
        pc = mix(pc, vec3(0.0), fg);

    }
    
    if (box.x > 0.0 && box.x < FAR) {
        
        vec3 rp = ray.ro + ray.rd * box.x;
        vec3 ld = normalize(lp - rp);
        
        vec3 bgc = vec3(0);
        if (ft > 0.0 && ft < FAR) {
            bgc = pc;    
        }
        
        //pseudo glass box
        float gt = box.y - box.x; //distance travelled through the glass
        pc = colGlass(rp, ray.rd, nN, vec3(1.0));
        //backface
        vec3 bfrp = ray.ro + ray.rd * box.y; 
        pc += colGlass(bfrp, ray.rd, nF, vec3(1.0)) * 0.25 / (1.0 + box.y * 0.001);
        
        pc += bgc * (0.8 - gt * 0.25);
        
        pc = fog(pc, ray, box.x);
    }
        
    glFragColor = vec4(pc, 1);
}
