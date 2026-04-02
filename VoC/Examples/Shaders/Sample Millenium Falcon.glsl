#version 420

// original https://www.shadertoy.com/view/XtXyWX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by SHAU - 2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

/**
 * Model of Millenium Falcon
 * Stars and Greeble texture borrowed from Fancy Ties by Nimitz
 **/

#define EPS 0.005
#define FAR 200.0 
#define PI 3.1415
#define T mod(time, 28.0)
#define R resolution.x / resolution.y
#define FOV PI / 4.0

mat2 rot(float x) {return mat2(cos(x), sin(x), -sin(x), cos(x));}
float tri(in float x) {return abs(fract(x) - .5);}

//animation parameters
vec3 shippos = vec3(0.0);
float glow = 0.0;
float shipxz = 0.0;
float shipyz = 0.0;
float shipxy = 0.0;
float showbay = 0.0;
float showplanet = 0.0;

vec3 transform(vec3 rp) {
    rp += shippos;
    rp.xz *= rot(shipxz);
    rp.yz *= rot(shipyz);
    rp.xy *= rot(shipxy);
    return rp;    
}

//Dave Hoskins
vec2 hash22(vec2 p){
    p = fract(p * vec2(5.3983, 5.4427));
    p += dot(p.yx, p.xy +  vec2(21.5351, 14.3137));
    return fract(vec2(p.x * p.y * 95.4337, p.x * p.y * 97.597));
}

vec3 hash33(vec3 p) {
    p = fract(p * vec3(5.3983, 5.4427, 6.9371));
    p += dot(p.yzx, p.xyz + vec3(21.5351, 14.3137, 15.3219));
    return fract(vec3(p.x * p.z * 95.4337, p.x * p.y * 97.597, p.y * p.z * 93.8365));
}

//3D noise function (IQ)
float noise(vec3 p) {
    vec3 ip = floor(p);
    p -= ip; 
    vec3 s = vec3(7, 157, 113);
    vec4 h = vec4(0.0, s.yz, s.y + s.z) + dot(ip, s);
    p = p * p * (3.0 - 2.0 * p); 
    h = mix(fract(sin(h) * 43758.5), fract(sin(h+s.x) * 43758.5), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z); 
}

//Distance functions IQ & Mercury
float pModPolar(inout vec2 p, float repetitions) {    
    float angle = 2.0 * PI / repetitions;
    float a = atan(p.y, p.x) + angle / 2.0;
    float r = length(p);
    float c = floor(a / angle);
    a = mod(a,angle) - angle / 2.0;
    p = vec2(cos(a), sin(a)) * r;
    if (abs(c) >= (repetitions / 2.0)) c = abs(c);
    return c;
}

float sdBox(vec3 p, vec3 bc, vec3 b) {    
    vec3 d = abs(bc - p) - b; 
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));;
}

float sdCappedCylinder(vec3 p, vec2 h) {
  vec2 d = abs(vec2(length(p.xz), p.y)) - h;
  return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float sdTorus(vec3 p, vec2 t) {
  vec2 q = vec2(length(p.xz) - t.x, p.y);
  return length(q) - t.y;
}

float sdCapsule(vec3 p, vec3 a, vec3 b, float r) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

float sdConeSection(in vec3 p, in float h, in float r1, in float r2) {
    float d1 = -p.y - h;
    float q = p.y - h;
    float si = 0.5 * (r1 - r2) / h;
    float d2 = max(sqrt(dot(p.xz, p.xz) * (1.0 - si * si)) + q * si - r2, q);
    return length(max(vec2(d1, d2), 0.0)) + min(max(d1, d2), 0.);
}

vec3 sphNormal(in vec3 pos, in vec4 sph) {
    return normalize(pos - sph.xyz);
}

vec4 sphIntersect(vec3 ro, vec3 rd, vec4 sph) {
    vec3 oc = ro - sph.xyz;
    float b = dot(oc, rd);
    float c = dot(oc, oc) - sph.w * sph.w;
    float h = b * b - c;
    if (h < 0.0) return vec4(vec3(0.0), 0.0);  
    float t = -b - sqrt(h);
    vec3 hp = ro + rd * t;
    vec3 hn = sphNormal(hp, sph);
    return vec4(hn, t);
}

vec2 boxIntersection(vec3 ro, vec3 rd, vec3 boxSize) {
    vec3 m = 1.0 / rd;
    vec3 n = m * ro;
    vec3 k = abs(m) * boxSize;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    float tN = max(max(t1.x, t1.y), t1.z);
    float tF = min(min(t2.x, t2.y), t2.z);
    if( tN > tF || tF < 0.0) return vec2(-1.0); // no intersection
    return vec2(tN, tF);
}

float core(vec3 rp) {
    float msd = sdCappedCylinder(rp + vec3(0.0, 0.3, 0.0), vec2(5.0, 0.1));
    msd = min(msd, sdCappedCylinder(rp + vec3(0.0, -0.3, 0.0), vec2(5.0, 0.1)));
    msd = min(msd, sdCappedCylinder(rp, vec2(4.8, 0.2)));    
    rp.xy = abs(rp.xy);
    float hole1 = sdCappedCylinder(rp + vec3(-2.6, -0.7, 5.7), vec2(0.3, 0.4));
    float hole2 = sdCappedCylinder(rp + vec3(-1.6, -0.7, 6.6), vec2(0.3, 0.4));    
    msd = min(msd, sdBox(rp, vec3(3.0, 0.0, -4.0), vec3(1.6, 0.2, 3.6)));
    msd = min(msd, sdBox(rp, vec3(3.0, 0.3, -4.0), vec3(2.0, 0.1, 4.0)));
    rp.xz *= rot(-0.32);
    float bar = sdBox(rp, vec3(8.0, 0.0, 0.0), vec3(3.0, 1.0, 10.0));
    bar = min(bar, sdBox(rp, vec3(4.8, 0.0, 0.0), vec3(0.3, 0.2, 10.0)));
    msd = max(msd, -hole1);
    msd = max(msd, -hole2);
    return max(msd, -bar);
}

float cut1(vec3 rp, float l) {
    rp.xz *= rot(PI * 2.0 / 360.0 * 45.0);
    return sdBox(rp, vec3(l, 0.0, l), vec3(4.0));
}

float cowl(vec3 rp) {
    rp.y = abs(rp.y);
    rp.yz *= rot(-0.15);
    return max(sdBox(rp, vec3(0.0, 1.35, -3.4), vec3(.9, 0.2, 2.8)), 
               - sdCappedCylinder(rp, vec2(1.4, 2.0)));   
}

float shell(vec3 rp) {
    float cut = cut1(rp, 3.7);
    float cyl = sdCappedCylinder(rp, vec2(1.4, 2.0));
    rp.y = abs(rp.y);
    float c = pModPolar(rp.xz, 20.0);
    rp.xy *= rot(-0.2);
    float msd = max(sdBox(rp, vec3(3.0, 1.7, 0.0), vec3(2.9, 0.1, 1.0)), cut);;
    msd = min(msd, sdBox(rp, vec3(3.0, 1.5, 0.0), vec3(2.4, 0.2, 0.9)));
    return max(msd, -cyl);
}

float window(vec3 rp) {
    float msd = sdTorus(rp.yzx, vec2(0.3, 0.025));
    pModPolar(rp.yx, 6.0);
    return min(msd, sdCapsule(rp, vec3(0.0, 0.3, 0.0), vec3(0.0, 0.6, 0.8), 0.025));
}

float gunpod(vec3 rp) {
    float win = window(rp + vec3(5.35, 0.0, 4.6));
    float front = sdCappedCylinder(rp.xzy + vec3(5.35, 3.2, .0), vec2(0.8, 0.6));
    front = max(front, -sdCappedCylinder(rp.xzy + vec3(5.35, 3.2, .0), vec2(0.4, 0.7)));
    rp.xz *= rot(-PI / 3.0);
    float msd = sdCappedCylinder(rp.xzy + vec3(0.0, 4.0, .0), vec2(0.8, 4.0));
    msd = max(msd, -sdCappedCylinder(rp.xzy + vec3(0.0, 4.0, .0), vec2(0.4, 4.2)));
    rp.xz *= rot(PI * 2.0 * 37.5 / 360.0); 
    float box = sdBox(rp, vec3(-4.0, 0.0, -1.8), vec3(3.0));
    msd = max(msd, box);
    front = max(front, -box);
    msd = min(msd, front);
    return min(msd, win);    
}

float tunnel(vec3 rp) {
    float msd = sdCappedCylinder(rp.yxz, vec2(1.3, 4.7));
    msd = min(msd, sdConeSection(rp.yxz + vec3(0.0, -5.0, 0.0), 0.6, 1.0, 0.6));
    msd = max(msd, -sdCappedCylinder(rp.yxz, vec2(0.5, 8.0)));
    msd = min(msd, sdTorus(rp.yxz + vec3(0.0, -5.6, 0.0), vec2(0.2, 0.025))); 
    pModPolar(rp.yz, 6.0);
    return min(msd, sdCapsule(rp, vec3(5.6, 0.2, 0.0), vec3(5.6, 0.5, 0.0), 0.025));
}

float pods(vec3 rp) {
    rp.x = abs(rp.x);
    float msd = sdCappedCylinder(rp + vec3(0.0, -1.0, -3.6), vec2(0.4, 0.4));
    msd = min(msd, sdCappedCylinder(rp + vec3(0.0, -1.2, -2.4), vec2(0.4, 0.4)));
    msd = min(msd, sdCappedCylinder(rp + vec3(-1.0, -1.2, -2.2), vec2(0.4, 0.4)));
    return min(msd, sdCappedCylinder(rp + vec3(-1.4, -0.9, -3.3), vec2(0.4, 0.4)));
}

float gunturret(vec3 rp) {
   float msd = sdCappedCylinder(rp, vec2(1.2, 1.6));
   rp.y = abs(rp.y); 
   msd = min(msd, sdBox(rp, vec3(0.0, 1.8, -0.6), vec3(0.2, 0.3, 0.4)));                             
   return min(msd, sdCappedCylinder(rp.xzy + vec3(0.0, 1.2, -1.9), vec2(0.05, 0.5)));                             
}

float dish(vec3 rp) {
    rp.xz *= rot(T * 0.5);
    float msd = sdCapsule(rp, vec3(0.0, 0.0, 0.0), vec3(0.0, -2.0, 0.0), 0.05);
    msd = min(msd, sdCapsule(rp, vec3(0.0, 0.0, 0.0), vec3(0.0, -2.0, 0.8), 0.05));
    msd = min(msd, sdCapsule(rp, vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, -0.4), 0.1));
    msd = min(msd, sdCappedCylinder(rp + vec3(0.0, 1.1, 0.0), vec2(0.6, 0.2)));
    pModPolar(rp.yx, 10.0);
    rp.yz *= rot(-0.4);
    return min(msd, sdBox(rp, vec3(0.0, 0.5, 0.0), vec3(0.22, 0.3, 0.05)));
}

float engine(vec3 rp) {
    return max(sdTorus(rp, vec2(5.9, 0.2)), cut1(rp, 5.0));   
}

vec2 nearest(vec2 older, vec2 newer) {
    if (newer.x < older.x) return newer;
    return older;
}

vec3 map(vec3 rp) {    
    rp = transform(rp);    
    vec2 hit = vec2(FAR, 0.0);
    float lt = FAR;
    hit = vec2(core(rp), 1.0);
    hit = nearest(hit, vec2(shell(rp), 2.0));
    hit = nearest(hit, vec2(dish(rp + vec3(-2.6, -2.1, 2.2)), 3.0));
    hit = nearest(hit, vec2(gunturret(rp), 4.0));
    hit = nearest(hit, vec2(cowl(rp), 5.0));
    hit = nearest(hit, vec2(pods(rp), 6.0));
    hit = nearest(hit, vec2(gunpod(rp), 7.0));
    lt = engine(rp);
    hit = nearest(hit, vec2(lt, 8.0));
    rp.x = abs(rp.x);
    hit.x = max(hit.x, -sdConeSection(rp.yxz + vec3(0.0, -5.6, 0.0), 1.4, 1.2, 1.6));
    hit = nearest(hit, vec2(tunnel(rp), 9.0));    
    return vec3(hit, lt);
}

vec3 normal(vec3 rp, float t) {
    float e = EPS * t;
    return normalize(vec3(map(rp + vec3(e, 0.0, 0.0)).x - map(rp - vec3(e, 0.0, 0.0)).x,
                          map(rp + vec3(0.0, e, 0.0)).x - map(rp - vec3(0.0, e, 0.0)).x,
                          map(rp + vec3(0.0, 0.0, e)).x - map(rp - vec3(0.0, 0.0, e)).x));
}

float occlusion(vec3 rp, vec3 n) {
    
    float fac = 2.5;
    float occ = 0.0;
    
    for (int i = 0; i < 5; i ++) {
        float hr = 0.01 + float(i) * 0.35 / 4.0;        
        float dd = map(n * hr + rp).x;
        occ += (hr - dd) * fac;
        fac *= 0.7;
    }
    
    return clamp(1.0 - occ, 0.0, 1.0);    
}

float shadow(vec3 ro, vec3 rd) {
    
    float shade = 1.0;
    float dist = 0.05;    
    float end = max(length(rd), EPS);
    rd /= end;
    
    for (int i = 0; i < 12; i++) {
        float h = map(ro + rd * dist).x;
        shade = min(shade, smoothstep(0.0, 1.0, 16.0 * h  / dist));
        dist += clamp(h, 0.01, 0.5);        
        if (h < EPS || dist > end) break; 
    }
    return min(max(shade, 0.) + 0.2, 1.0); 
}

vec3 march(vec3 ro, vec3 rd) {
    
    float t = 0.0;
    float li = 0.0;
    float id = 0.0;
    
    for (int i = 0; i < 100; i++) {
        vec3 rp = ro + rd * t;
        vec3 ns = map(rp);
        if (ns.x < EPS || t > FAR) {
            id = ns.y;    
            break;
        }
        li += exp(ns.z * -ns.z) * 0.02;
        t += ns.x;
    }
    
    return vec3(t, id, li);
}

//starfield from nimitz
//https://www.shadertoy.com/view/ltfGDs
vec3 stars(in vec3 p) {
    
    vec3 c = vec3(0.);
    float res = resolution.x * .85 * FOV;
    
    p.x += (tri(p.z * 50.) + tri(p.y * 50.)) * 0.006;
    p.y += (tri(p.z * 50.) + tri(p.x * 50.)) * 0.006;
    p.z += (tri(p.x * 50.) + tri(p.y * 50.)) * 0.006;
    
    for (float i = 0.; i < 3.; i++) {
        
        vec3 q = fract(p * (.15 * res)) - 0.5;
        vec3 id = floor(p * (.15 * res));
        float rn = hash33(id).z;
        float c2 = 1.-smoothstep(-0.2, .4, length(q));
        c2 *= step(rn, 0.005 + i * 0.014);
        c += c2 * (mix(vec3(1.0, 0.75, 0.5),vec3(0.85, 0.9, 1.), rn * 30.) * 0.5 + 0.5);
        p *= 1.15;
    }
    return c*c*1.5;
}

//greeble texture from nimitz
//https://www.shadertoy.com/view/ltfGDs
float tex(vec3 rp, float nrot, float scale) {    

    rp = transform(rp);
    
    vec2 p = rp.zx * scale;
    float id = floor(p.x) + 100. * floor(p.y);
    float rz= 1.0;
    pModPolar(p, nrot);
    
    for(int i = 0; i < 3; i++) {
        vec2 h = (hash22(floor(p)) - 0.5) * .95;
        vec2 q = fract(p) - 0.5;
        q += h;
        float d = max(abs(q.x), abs(q.y)) + 0.1;
        p += 0.5;
        rz += min(rz, smoothstep(0.5, .55, d)) * 1.;
        p *= 1.4;
    }
    
    rz /= 7.;
    
    return rz;
}

vec3 ptex(vec3 rp) {
    rp.xy *= rot(rp.z * .1);
    rp.xz *= rot(rp.y * .04);
    vec3 pc = vec3(1.0, 0.0, 0.0);// * texture(iChannel0, rp.xy * .01).xyz;
    pc *= noise(rp * 0.01) * vec3(0.6, 0.7, 0.0) * 2.0;
    return pc;
}

vec4 bump(vec3 rp, vec3 n, float bmpamt, float nrot, float scale) {
    float bf = bmpamt;
    vec2 e = vec2(EPS / resolution.y, 0.0);
    float tl = tex(rp, nrot, scale);
    vec3 grad = (vec3(tex(rp - e.xyy, nrot, scale), 
                      tex(rp - e.yxy, nrot, scale), 
                      tex(rp - e.yyx, nrot, scale)) - tl) / e.x;
    return vec4(normalize(n + grad * bf), tl); 
} 

vec3 bay(vec2 gl_FragCoord) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= R;
    float ir = resolution.y / resolution.x;    
    vec3 pc = vec3(1.0) * pow(abs(uv.y), 64.0);
    pc += vec3(1.0) * pow(abs(uv.x * ir), 64.0);
    return pc;
}

void setupCamera(out vec3 ro, out vec3 rd, vec2 gl_FragCoord) {
    
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= R;
    
    vec3 lookAt = vec3(0.0);;
    
    if (T < 6.6) {
        ro = vec3(0.0, 0.0, -14.0);
        shippos = vec3(0.0, 0.0, clamp(2.0 - T, -2.0, 2.0)) +
                  vec3(clamp(T * 1.8, 0.0, 7.9), 0.0, 0.0) +
                  normalize(vec3(2.8, -2.3, -2.0)) * clamp((T - 4.4) * 6.0, 0.0, 20.0);
        shipxz = clamp((T - 0.9) * 1.17, 0.0, 4.0);
        shipyz = clamp(T * -0.3, -0.4, 0.0) + clamp(T * 0.25 - 0.25, 0.0, 0.8);
        shipxy = clamp(T * -0.14, -0.6, 0.0);
        glow = 1.0 + clamp((T - 3.9) * 2.0, 0.0, 1.8);
        showbay = 1.0;
        
    } else if (T < 15.6) {
        ro  = vec3(9.0, 3.0, 9.0);
        ro.xz *= rot(0.5 * - (T - 7.2));
        ro.xy *= rot(0.1 * (T - 6.6));
        glow = 1.8;
    } else if (T < 22.6) {
        ro = vec3(8.0 + T - 15.6, 4.0 - T + 14.6, 2.0);
        shippos = vec3(0.0, 0.0, (T - 18.6) * 40.0);
        lookAt = -shippos;
        shipxy = (T - 14.6) * 0.14;
        glow = 1.8;
        
    } else {
        ro = vec3(0.0, 6.0, 14.0);
        shippos = vec3(0.0, 0.0, -10.0 + (T - 22.6) * 20.0);
        lookAt = -shippos;
        glow = 1.8;
        showplanet = 1.0;
    }
    
    vec3 forward = normalize(lookAt - ro);
    vec3 right = normalize(vec3(forward.z, 0., -forward.x )); 
    vec3 up = cross(forward, right);    
    rd = normalize(forward + FOV * uv.x * right + FOV * uv.y * up);
}

void main(void) {
    
    vec3 pc = vec3(0.0);
    vec3 ld = normalize(vec3(4.0, 5.0, 2.0));
    
    vec3 ro, rd;
    setupCamera(ro, rd, gl_FragCoord.xy);
  
    pc += stars(rd);
    
    vec4 planet = sphIntersect(ro, rd, vec4(60.0, 80.0, -160.0, 80.0));
    if (planet.w > 0.0 && showplanet > 0.0) {
        vec3 rp = ro + rd * planet.w;
        float diff = max(dot(planet.xyz, ld), 0.001);
        pc = ptex(rp) * diff;
    }
  
    vec2 bounds = boxIntersection(ro + shippos, rd, vec3(8.0));
    if (bounds.x > 0.0 || bounds.y > 0.0) {
        vec3 t = march(ro, rd);
        if (t.x > 0.0 && t.x < FAR) {
        
            vec3 rp = ro + rd * t.x;
            vec3 n = normal(rp, t.x);
            if (t.y == 1.0 || t.y == 5.0 || t.y == 7.0 || t.y == 9.0) {
                n = bump(rp, n, 0.13, 1.0, 1.0).xyz;
            } else if (t.y == 2.0 || t.y == 4.0) {
                n = bump(rp, n, 0.08, 20.0, 0.5).xyz;
            }
        
            float diff = max(dot(n, ld), 0.02);
            float occ = occlusion(rp, n);
            float sh = shadow(rp, ld);
         
            vec3 sc = vec3(1.0);
            sc *= clamp(noise(transform(rp) * 0.6 + 0.1), 0.5, 1.0);
       
            if (t.y == 6.0) {
                sc = vec3(0.2);       
            }
        
            if (t.y != 8.0) {
                pc = sc * diff * occ;
                pc *= sh;
            } else {
                pc = vec3(0.4, 0.4, 1.0) * glow;    
            }
        }
    
        pc += t.z * vec3(0.4, 0.4, 1.0) * glow;
    }
    
    pc += bay(gl_FragCoord.xy) * showbay;

    
    glFragColor = vec4(sqrt(clamp(pc, 0.0, 1.0)),1.0);
}
