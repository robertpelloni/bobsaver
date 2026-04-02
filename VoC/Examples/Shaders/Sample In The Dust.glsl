#version 420

// original https://www.shadertoy.com/view/4sBBDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by SHAU - 2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

/*
 * Ruining lot's of good code here :) 
 * Mainly playing with dust noise algorithm by Nimitz
 * Conceptually similar to Tumbling Box by Dila
 */

#define T time
#define BOXT time * 4.0
#define EPS 0.005
#define FAR 200.0 
#define PI 3.1415
#define dy vec3(0.0, abs(sin(BOXT * 0.5) * 4.0), 0.0)

struct Ray {
    vec3 ro; //ray origin
    vec3 rd; //ray direction 
};

mat2 rot(float x) {return mat2(cos(x), sin(x), -sin(x), cos(x));}  
float diffuse(vec3 n, vec3 ld) {return clamp(dot(n, ld), 0.0, 1.0);}
float specular(vec3 refl, vec3 ld, float k) {return pow(clamp(dot(refl, ld), 0.0, 1.0), k);}

//IQ box functions
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

vec2 bouncingBox(Ray ray, vec3 boxSize, out vec3 outNormalN, out vec3 outNormalF) {
    
    ray.ro -= dy;
    ray.rd.zx *= rot(PI * -0.25);
    ray.ro.zx *= rot(PI * -0.25);
    ray.rd.xy *= rot(PI * 0.25 + BOXT);
    ray.ro.xy *= rot(PI * 0.25 + BOXT);
    ray.rd.yz *= rot(PI * -0.25);
    ray.ro.yz *= rot(PI * -0.25);
    
    vec2 box = boxIntersection(ray, boxSize, outNormalN, outNormalF);
    
    //revert rotation on normals
    outNormalN.yz *= rot(PI * 0.25);
    outNormalN.xy *= rot(PI * -0.25 - BOXT);
    outNormalN.zx *= rot(PI * 0.25);
    
    return box;
}

float tracePlane(Ray ray, vec3 n, vec3 o) {
    return dot(o - ray.ro, n) / dot(ray.rd, n);
}

//From TekF (https://www.shadertoy.com/view/ltXGWS)
float cells(vec3 p) {
    p = fract(p / 2.0) * 2.0;
    p = min(p, 2.0 - p);
    return min(length(p), length(p - 1.0));
}

//Nimitz - https://www.shadertoy.com/view/4lSGRh
float tex(vec3 rp) {
    rp *= 2.0;    
    float rz= 0.;
    float z= 1.;
    for (int i = 0; i < 2; i++) { 
        rz += cells(rp) / z;
        rp *= 1.5;
        z *= -1.1;
    }
    return clamp(rz * rz * 2.5, 0., 1.) * 1.;
}

//cube mapping routine from Fizzer
vec3 fizz(vec3 rp) {
    vec3 f = abs(rp);
    f = step(f.zxy, f) * step(f.yzx, f); 
    f.xy = f.x > .5 ? rp.yz / rp.x : f.y > .5 ? rp.xz / rp.y : rp.xy / rp.z; 
    return f;
}

vec3 bump(vec3 rp, vec3 n) {
    float bf = 0.1;
    vec2 e = vec2(EPS / resolution.y, 0.0);
    float tl = tex(rp);
    vec3 grad = (vec3(tex(rp - e.xyy), 
                      tex(rp - e.yxy), 
                      tex(rp - e.yyx)) - tl) / e.x;
    return normalize(n + grad * bf); 
} 

//Nimitz - slightly changed in attempt to convey bounce
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
    
    p.x += T;
    p.z += sin(p.x * .5);
    
    return triNoise3d(p * 2.2 / (d + 20.), 0.2) * (1. -smoothstep(0., .7, p.y));
}

vec3 fog2(vec3 col, Ray ray, float mt, vec3 sc) {
    
    float d = 0.5;
    
    for (int i = 0; i < 7; i++) {
        vec3  pos = ray.ro + ray.rd * d;
        sc.y = -1.68;
        
        float st = 4.0 / length(pos - sc);

        float rz = fogmap(pos, d);
        float grd1 =  clamp((rz - fogmap(pos + st -float(i) * 0.1, d)) * 3.0 * st, 0.1, 1.);
        vec3 col1 = (vec3(.4, 0.4, .5) * .5 + .5 * vec3(1.5, 0.5, 0.05) * (1.7 - grd1)) * 0.55;

        float grd2 =  clamp((rz - fogmap(pos + .8 -float(i) * 0.1, d)) * 3.0, 0.1, 1.);
        vec3 col2 = (vec3(.4, 0.4, .5) * .5 + .5 * vec3(1.5, 0.5, 0.05) * (1.7 - grd2)) * 0.55;

        vec3 col3 = mix(col, col1, clamp(rz * st * smoothstep(d - 0.4, d + 2. + d * .75, mt), 0., 1.));
        vec3 col4 = mix(col, col2, clamp(rz * smoothstep(d - 0.4, d + 2. + d * .75, mt), 0., 1.));
        
        col = mix(col4, col3, clamp(st, 0.0, 1.2));
        
        d *= 1.5 + 0.3;
        if (d > mt) break;
    }
    
    return col;
}

Ray setupCamera(vec2 uv) {
    vec3 lookAt = vec3(0);
    vec3 camera = vec3(0.0, 0.5, -8.0);
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
    vec3 lp1 = vec3 (6.0, 1.0, -4.0); //sun light
    vec3 lp2 = vec3 (-6.5, 4.5, 6.5); //back light
    
    //coordinate system
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;

    Ray ray = setupCamera(uv);
    
    vec3 fo = vec3(0.0, -1.68, 0.0);
    vec3 fn = vec3(0.0, 1.0, 0.0);

    vec3 nN = vec3(0.0); //near face normal
    vec3 nF = vec3(0.0); //rear face normal

    float mint = FAR;
    float ft = tracePlane(ray, fn, fo);
    vec2 box = bouncingBox(ray, vec3(1), nN, nF);
    
    //sky and clouds lifted verbatim from iq
    float sun = clamp(dot(normalize(lp1), ray.rd), 0.0, 1.0);
    vec3 hor = mix(1.2 * vec3(0.70,1.0,1.0), vec3(1.5, 0.5, 0.05), 0.25 + 0.75 * sun);
    pc = mix( vec3(0.2,0.6,.9), hor, exp(-(4.0+2.0*(1.0-sun))*max(0.0,ray.rd.y-0.1)) );
    pc *= 0.5;
    pc += 0.8*vec3(1.0,0.8,0.7)*pow(sun,512.0);
    pc += 0.2*vec3(1.0,0.4,0.2)*pow(sun,32.0);
    pc += 0.1*vec3(1.0,0.4,0.2)*pow(sun,4.0);
    
    vec3 bcol = pc;
    
    // clouds
    float pt = (1000.0-ray.ro.y)/ray.rd.y; 
    if( pt>0.0 )
    {
        vec3 spos = ray.ro + pt*ray.rd;
        float clo = 0.0;//texture( iChannel0, 0.00006*spos.xz ).x;    
        vec3 cloCol = mix( vec3(0.4,0.5,0.6), vec3(1.3,0.6,0.4), pow(sun,2.0))*(0.5+0.5*clo);
        pc = mix( pc, cloCol, 0.5*smoothstep( 0.4, 1.0, clo ) );
    }
    
    
    if (ft > 0.0 && ft < FAR) {
   
        //floor
        mint = ft;
        vec3 fc = vec3(0);
        
        vec3 rp = ray.ro + ray.rd * ft;
        vec3 ld = normalize(lp1 - rp);
        float diff = diffuse(fn, ld);
        
        vec2 rxz = rp.xz;
        rxz -= BOXT;
        rxz *= rot(PI * 0.25);
        vec2 mx = mod(rxz, 2.0) - 1.0;
        vec3 acol = vec3(1.0);//mix(1.0, 0.0, 0.3);
        vec3 bcol = vec3(0.0);//texture(iChannel0, rxz).xyz;
        fc = (mx.x * mx.y > 0.0) ? acol : bcol; 
        fc *= diff + vec3(1.3, 0.5, 0.05) * diff * 0.5;
        
        //hard shadow
        vec3 nNS = vec3(0);
        vec3 nFS = vec3(0);
        float sh = 1.0;
        vec2 boxS = bouncingBox(Ray(rp, ld), vec3(1), nNS, nFS);
        float lt = length(lp1 - rp);
        if (boxS.x > 0.0 && boxS.x < lt) {
            sh = (boxS.x / lt);    
        }
        fc *= sh;
        
        //fade into background
        float fa = 1.0 - exp(-ft * ft * 0.5 / FAR);
        pc = mix(fc, pc, fa);
    }
    
    if (box.x > 0.0 && box.x < FAR) {
        
        //box
        mint = min(box.x, mint);
        
        vec3 rp = ray.ro + ray.rd * box.x;
        
        //rotate texture to follow box rotation
        vec3 rrp = rp - dy;
        rrp.zx *= rot(PI * -0.25);
        rrp.xy *= rot(PI * 0.25 + BOXT);
        rrp.yz *= rot(PI * -0.25);
        nN = bump(fizz(rrp), nN).xyz;
        
        vec3 sc = vec3(1.0);//mix(texture(iChannel0, fizz(rrp).xy).xyz, vec3(1), tex(fizz(rrp))); //surface colour
        vec3 lc = vec3(0.0); //light colour
        
        //sun light
        vec3 ld1 = normalize(lp1 - rp);        
        float diff = diffuse(nN, ld1);
        vec3 rrd  = reflect(ray.rd, nN); //reflected ray direction
        float spec = specular(rrd, ld1, 16.0);

        lc += vec3(1.3, 0.5, 0.05) * diff * 0.6; 
        lc += vec3(1.3, 0.5, 0.05) * spec * 0.4;
        
        //shadow from sun
        vec3 nNS = vec3(0);
        vec3 nFS = vec3(0);
        float sh = 1.0;
        vec3 rp2 = ray.ro + ray.rd * (box.x - EPS); //step back
        vec2 boxS = bouncingBox(Ray(rp2, ld1), vec3(1), nNS, nFS);
        float lt = length(lp1 - rp);
        if (boxS.x > 0.0 && boxS.x < lt) {
            sh *= 0.3;    
        }

        //back lighting
        vec3 ld2 = normalize(lp2 - rp); 
        diff = diffuse(nN, ld2);
        lc += vec3(0.5, 0.7, 1.0) * diff * 0.1;
        
        //up lighting
        vec3 ld3 = vec3(0.0, -1.0, 0.0);
        diff = diffuse(nN, ld3);        
        lc += vec3(0.9, 0.5, 0.3) * diff * 0.1 / (rp.y + 1.68);
        
        pc = sc * lc * sh;
    }
    
    //nimitz fog
    float mct = mod(T, PI * 0.5) * 4.0; //cycle time
    vec3 sc = vec3(mct, -1.68 - mct * 0.6, mct); //bounce sphere center
    pc = fog2(pc, ray, mint, sc);
        
    glFragColor = vec4(pc, 1);
    
    // output the final color with sqrt for "gamma correction"
    glFragColor = vec4(sqrt(clamp(pc, 0.0, 1.0)),1.0);
}
