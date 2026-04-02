#version 420

// original https://www.shadertoy.com/view/4tlcR7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by SHAU - 2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define EPS 0.001
#define FAR 200.0 
#define PI 3.1415
#define T time
#define idx(x, y) (y * 9 + x)
#define rnda floor(sin(rand(vec2(T * 0.01))) * 27.0)

struct Hit {
    float tN;    
    vec3 nN;
    float tF;
    vec3 nF;
    float id;
    vec3 bc;
};

mat2 rot(float x) {return mat2(cos(x), sin(x), -sin(x), cos(x));}
float rand(vec2 co) {return fract(sin(dot(co.xy ,vec2(12.9898, 78.233))) * 43758.5453);}

// IQ - cosine based palette
//http://iquilezles.org/www/articles/palettes/palettes.htm
vec3 palette(in float t) {
    vec3 CP1A = vec3(0.5, 0.5, 0.5);
    vec3 CP1B = vec3(0.5, 0.5, 0.5);
    vec3 CP1C = vec3(2.0, 1.0, 0.0);
    vec3 CP1D = vec3(0.50, 0.20, 0.25);
    return CP1A + CP1B * cos(6.28318 * (CP1C * t + CP1D));
}

//Distance functions, Sphere and box functions all from IQs website

vec2 boxIntersection(vec3 ro, vec3 rd, vec3 boxSize, out vec3 outNormalN, out vec3 outNormalF) {
    vec3 m = 1.0 / rd;
    vec3 n = m*ro;
    vec3 k = abs(m)*boxSize;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    float tN = max(max(t1.x, t1.y ), t1.z);
    float tF = min(min(t2.x, t2.y ), t2.z);
    if( tN > tF || tF < 0.0) return vec2(-1.0); //no intersection
    outNormalN = -sign(rd) * step(t1.yzx, t1.xyz) * step(t1.zxy, t1.xyz);
    outNormalF = -sign(rd) * step(t2.xyz, t2.yzx) * step(t2.xyz, t2.zxy);
    return vec2(tN, tF);
}

vec3 sphNormal(in vec3 pos, in vec4 sph) {
    return normalize(pos - sph.xyz);
}

vec4 sphIntersect(in vec3 ro, in vec3 rd, in vec4 sph) {
    vec3 oc = ro - sph.xyz;
    float b = dot(oc, rd);
    float c = dot(oc, oc) - sph.w * sph.w;
    float h = b * b - c;
    if (h < 0.0) return vec4(vec3(0.0), FAR);
    
    float t = -b - sqrt(h);
    vec3 hp = ro + rd * t;
    vec3 hn = sphNormal(hp, sph);
    return vec4(hn, t);
}

float planeIntersection(vec3 ro, vec3 rd, vec3 n, vec3 o) {
    return dot(o - ro, n) / dot(rd, n);
}

float sdBox(vec3 p, vec3 bc, vec3 b) {    
    vec3 d = abs(bc - p) - b; 
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));;
}

float sdSphere(vec3 rp, vec3 bc, float r) {
    return length(bc - rp) - r;
}

Hit nearest(Hit older, Hit newer) {
    if (newer.tN > 0.0 && newer.tN < older.tN) {
        return newer;
    }
    return older;
}

//raytrace scene
Hit traceScene(vec3 ro, vec3 rd) {

    Hit hit = Hit(FAR, vec3(0.0), FAR, vec3(0.0), 0.0, vec3(0.0));
    
    //floor
    vec3 fo = vec3(0.0, 0.0, 0.0);
    vec3 fn = vec3(0.0, 1.0, 0.0);
    float t = planeIntersection(ro, rd, fn, fo); 
    hit = nearest(hit, Hit(t, fn, FAR, vec3(0.0), 1.0, vec3(0.0)));

    //wall
    vec3 nN, nF;
    for (int y = 0; y < 3; y++) {
        for (int x = 0; x < 9; x++) {
            vec3 bc = vec3(float(x) * 1.5 - 5.0,
                           float(y) * 1.5 - 3.8,
                           sin(T + float(x * y)) * 0.2);
            vec2 box = boxIntersection(ro + bc, rd, vec3(0.7), nN, nF);
            hit = nearest(hit, Hit(box.x, nN, box.y, nF, 3.0 + float(y) * 9.0 + float(x), bc));
        }
    }
    
    //spheres
    vec3 sc1 = vec3(0.0, 0.4, -1.2);
    sc1.xz *= rot(T);
    sc1 += vec3(-1.0, 0.0, -3.0);
    vec4 sphere = sphIntersect(ro, rd, vec4(sc1, 0.4));
    hit = nearest(hit, Hit(sphere.w, sphere.xyz, FAR, vec3(0.0), 2.0, vec3(0.0)));

    vec3 sc2 = vec3(0.0, 0.4, 1.2);
    sc2.xz *= rot(T);
    sc2 += vec3(-2.0, 0.0, -3.0);
    sphere = sphIntersect(ro, rd, vec4(sc2, 0.4));
    hit = nearest(hit, Hit(sphere.w, sphere.xyz, FAR, vec3(0.0), 2.0, vec3(0.0)));

    return hit;
}

float shadow(vec3 rp, vec3 lp) {
    
    float shadow = 1.0;
    
    vec3 ld = normalize(lp - rp);
    float lt = length(lp - rp);
    
    Hit hit = traceScene(rp, ld);
    
    if (hit.tN < lt) {
        shadow = 1.0 * hit.tN / lt * exp(-hit.tN * hit.tN * 0.5 / lt);    
    }
    
    return shadow;
}

float dfScene(vec3 rp) {
 
    //floor
    float msd = rp.y; 
    
    //wall
    for (int y = 0; y < 3; y++) {
        for (int x = 0; x < 9; x++) {
            vec3 bc = vec3(float(x) * 1.5 - 5.0,
                           float(y) * 1.5 - 3.8,
                           sin(T + float(x * y)) * 0.2);
            msd = min(msd, sdBox(rp, -bc, vec3(0.7)));
        }
    }
    
    //spheres
    vec3 sc1 = vec3(0.0, 0.4, -1.2);
    sc1.xz *= rot(T);
    sc1 += vec3(-1.0, 0.0, -3.0);
    msd = min(msd, sdSphere(rp, sc1, 0.4));
    vec3 sc2 = vec3(0.0, 0.4, 1.2);
    sc2.xz *= rot(T);
    sc2 += vec3(-2.0, 0.0, -3.0);
    msd = min(msd, sdSphere(rp, sc2, 0.4));

    return msd;
}

//volumetric glow around light
vec3 marchScene(vec3 ro, vec3 rd) {

    float t = 0.0;
    vec3 pc = vec3(0.0);
    
    for (int i = 0; i < 40; i++) {
        vec3 rp = ro + rd * t;
        float ns = dfScene(rp);
        if (ns < EPS || t > FAR) break;
        
        //which cube is lit
        float y = floor((rnda) / 9.0);
        float x = floor(mod(rnda, 9.0));
        vec3 lc = palette(rnda + T * 0.01 * rnda);
        vec3 bc = vec3(x * 1.5 - 5.0,
                       y * 1.5 - 3.8,
                       sin(T + x * y) * 0.2);
        float lt = length(-bc - rp);
        pc += lc * 0.1 * exp(lt * -lt);
        
        t += ns;
    }
    
    return pc;
}

//light up box
vec3 vMarch(vec3 ro, vec3 rd, float maxt, vec3 bc, vec3 lc) {

    vec3 pc = vec3(0.0);
    float t = 0.0;
    
    for (int i = 0; i < 40; i++) {
        vec3 rp = ro + rd * t; 
        if (t > maxt) break;
        
        float li = length(-bc - rp);            
        pc += lc * 0.1;
        pc += lc * 0.6 / li * li * li;
        
        t += 0.1;       
    }
    
    return pc;
}

void setupCamera(vec2 uv, out vec3 ro, out vec3 rd) {
    vec3 lookAt = vec3(-2.0, 1.0, 0.0);
    vec3 camera = vec3(-2.5, 1.4, -6.0);
    camera.xz *= rot(sin(T * 0.3) * 0.5);
    //camera.xy *= rot(T * 0.5);
    // Using the above to produce the unit ray-direction vector.
    float FOV = PI / 5.; // FOV - Field of view.
    vec3 forward = normalize(lookAt.xyz - camera.xyz);
    vec3 right = normalize(vec3(forward.z, 0., -forward.x )); 
    vec3 up = cross(forward, right);    
    rd = normalize(forward + FOV * uv.x * right + FOV * uv.y * up);
    ro = camera.xyz;
}

void main(void) {
    
    vec3 pc = vec3(0.0);    
    vec3 lp = vec3(4.0, 5.0, -2.0);
    vec3 lc = vec3(0.8, 0.7, 0.9);

    //coordinate system
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;

    vec3 ro, rd;
    setupCamera(uv, ro, rd);    
    
    float refl = 1.0;
    float tt = 0.0;
    
    vec3 mc = marchScene(ro, rd);
    
    for (int i = 0; i < 3; i++) {
        
        Hit hit = traceScene(ro, rd);
  
        if (hit.tN > 0.0 && hit.tN < FAR) {

            vec3 col = vec3(0.0);          
            vec3 sc = vec3(0.0);
            float nrefl = 0.0;
            float fo = 0.0;
            
            vec3 rp = ro + rd  * hit.tN;
            vec3 ld = normalize(lp - rp);
            float lt = length(lp - rp);
            vec3 rrd = reflect(rd, hit.nN);
            tt += hit.tN;

            float diff = clamp(dot(hit.nN, ld), 0.0, 1.0);
            float spec = pow(clamp(dot(rrd, ld), 0.0, 1.0), 16.0);
            float sh = shadow(ro + rd * (hit.tN - EPS), lp);
            float la = 1.0 / (1.0 + lt * lt * 0.1);
            float ta = 1.0 / (1.0 + tt * tt * 0.05);
            float fog = 1.0 - exp(-hit.tN * hit.tN * 0.5 / FAR);
            float fres = pow(clamp(1.0 + dot(hit.nN, rd), 0.0, 1.0), 16.0);
            
            if (hit.id == 1.0) {
                //floor
                sc  = vec3(0.5, 0.4, 0.4);
                nrefl = 0.35;
                fo = 0.05;
            }
            if (hit.id == 2.0) {
                //ball
                sc  = vec3(0.0, 0.1, 0.2);
                nrefl = 0.99;
                fo = 0.0;
            }
            if (hit.id > 2.0) {
                //bricks
                sc = vec3(0.0, 0.0, 0.0);
                nrefl = 0.5;
                fo = 0.01;
                
                //light cube
                //27 cubes starting from id = 3
                if (hit.id == rnda + 3.0) {
                    vec3 lc = palette(rnda + T * 0.01 * rnda);
                    sc += vMarch(rp, rd, hit.tF - hit.tN, hit.bc, lc) * 2.0;
                    sh += (1.0 - sh) * 0.8; //reduce shadow
                    nrefl = 0.35; //reduce reflection
                }
            }
            
            col = sc * 0.2; //ambient
            col += lc * diff * la * 0.2; //diffushiye light
            col += lc * (spec + fres); //specular and fresnel
            col *= sh; //shadow
            col = mix(col, vec3(0.0), fog); //fog
           
            pc = mix(pc, col * refl, refl); //add reflection
            
            //setup for next reflected pass
            ro = ro + rd * (hit.tN - EPS);
            rd = rrd;  
            refl *= nrefl;
            refl *= exp(fo * tt * -tt);

        } else {
            //missed scene
            pc = mix(pc, vec3(0.), refl);
            break;
        }
    }
    //*/
        
    pc += mc;
    
    glFragColor = vec4(sqrt(clamp(pc, 0.0, 1.0)),1.0);
}
