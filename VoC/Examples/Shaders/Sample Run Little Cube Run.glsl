#version 420

// original https://www.shadertoy.com/view/MllyRS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by SHAU - 2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

/*
 * inspired by Dila's tumbling boxes (kind of)
 * https://www.shadertoy.com/view/XtdSz8
 */

#define EPS 0.005
#define FAR 200.0 
#define PI 3.1415
#define T time

struct Hit {
    float tN;    
    vec3 nN;
    float tF;
    vec3 nF;
    float id;
    vec3 bc;
};
    
mat2 rot(float x) {return mat2(cos(x), sin(x), -sin(x), cos(x));}

//wireframe edges
float tex(vec3 rp) {
    float bs = 0.9;
    if (abs(rp.x) < bs && abs(rp.y) < bs) return 0.0;
    return 1.0;   
}

//cube mapping routine from Fizzer
float fizz(vec3 rp, float i) {

    rp.xy *= rot(T + i);
    rp.xz *= rot(T + i);
    
    vec3 f = abs(rp);
    f = step(f.zxy, f) * step(f.yzx, f); 
    f.xy = f.x > .5 ? rp.yz / rp.x : f.y > .5 ? rp.xz / rp.y : rp.xy / rp.z; 
    return tex(f);
}

float planeIntersection(vec3 ro, vec3 rd, vec3 n, vec3 o) {
    return dot(o - ro, n) / dot(rd, n);
}

// intersection of a ray and a capped cylinder oriented in an arbitrary direction
vec4 iCylinder(in vec3 ro, in vec3 rd, 
               in vec3 pa, in vec3 pb, float ra) // extreme a, extreme b, radius
{
    vec3 cc = 0.5 * (pa + pb);
    float ch = length(pb - pa);
    vec3 ca = (pb - pa) / ch;
    ch *= 0.5;

    vec3  oc = ro - cc;

    float card = dot(ca, rd);
    float caoc = dot(ca, oc);
    
    float a = 1.0 - card * card;
    float b = dot( oc, rd) - caoc * card;
    float c = dot( oc, oc) - caoc * caoc - ra*ra;
    float h = b*b - a*c;
    if (h < 0.0) return vec4(-1.0);
    h = sqrt(h);
    float t1 = (-b -h) / a;

    float y = caoc + t1 * card;

    // body
    if (abs(y) < ch) return vec4(t1, normalize(oc + t1 * rd - ca * y));
    
    // caps
    float sy = sign(y);
    float tp = (sy * ch - caoc) / card;
    if(abs(b + a * tp) < h) {
        return vec4(tp, ca * sy);
    }

    return vec4(-1.0);
}

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

vec2 rotateBox(vec3 ro, vec3 rd, vec3 boxSize, out vec3 nN, out vec3 nF, float i) {
 
    ro.xy *= rot(T + i);
    rd.xy *= rot(T + i);
    ro.xz *= rot(T + i);
    rd.xz *= rot(T + i);
    
    vec2 box = boxIntersection(ro, rd, boxSize, nN, nF);
    
    nN.xz *= rot(-T - i);
    nF.xz *= rot(-T - i);
    nN.xy *= rot(-T - i);
    nF.xy *= rot(-T - i);

    return box;
}

Hit traceCubes(vec3 ro, vec3 rd, out float edge) {

    Hit hit = Hit(FAR, vec3(0.0), FAR, vec3(0.0), 0.0, vec3(0.0));

    vec3 nN, nF;
    for (int i = 0; i < 10; i++) {
        float fi = float(i);
        vec3 bc = vec3(-fi + fi * 0.3, sin(fi + T * 4.0), 0.0);
        vec2 box = rotateBox(ro + bc, rd, vec3(1.0) - fi * 0.08, nN, nF, fi);
        
        if (box.x > 0.0) {
            
            vec3 rp = ro + bc + rd * box.x;
            edge += fizz(rp, float(i));
            rp = ro + bc + rd * box.y;
            edge += fizz(rp, float(i));
            
            if (box.x < hit.tN) {
                hit = Hit(box.x, nN, box.y, nF, fi, bc);
            }
        }
    }    
    
    return hit;
}

vec3 colourCubes(Hit t, vec3 ro, vec3 rd, vec3 lp, float edge, vec3 opc) {

    vec3 pc = opc;
    
    vec3 rp = ro + rd * t.tN;
    vec3 rpb = ro + rd * (t.tN - EPS);
    vec3 rrd = reflect(rd, t.nN);
    vec3 ld = normalize(lp - rp);
    float diff = clamp(dot(t.nN, ld), 0.0, 1.0);
    float spec = pow(clamp(dot(rrd, ld), 0.0, 1.0), 16.0);

    //cubes
    if (edge > 0.0) {
        pc += vec3(1.0);
    }
            
    vec3 cc = vec3(0.05) + vec3(1.0) * diff;
    cc += vec3(1.0) * spec;
    cc += vec3(0.8, 0.0, 0.2) * clamp(-t.nN.y, 0.0, 1.0) * 0.05; 
    
    //floor reflections
    vec3 fo = vec3(0.0, -2.8, 0.0);
    vec3 fn = vec3(0.0, 1.0, 0.0);
    
    float ft = planeIntersection(rpb, rrd, fn, fo);
    if (ft > 0.0 && ft < FAR) {
        
        vec3 frp = rpb + rrd * ft;
        vec3 ld = normalize(lp - frp);
        //checker board
        frp.x += T * -8.0;
        vec3 sc = vec3(0.0);//texture(iChannel0, frp.xz * 0.1).xyz;
        vec2 mx = mod(frp.xz, 4.0) - 2.0;
        if (mx.x * mx.y > 0.0) sc = vec3(0.8) + vec3(0.0);//texture(iChannel0, frp.xz * 0.2).xyz * 0.1;
        
        cc += sc * exp(ft * -ft * 0.8) * 0.2;
    }
    
    pc = mix(cc, pc, t.id * 0.1);
    
    return pc;
}

void setupCamera(out vec3 ro, out vec3 rd, vec2 gl_FragCoord) {
    
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    
    vec3 lookAt = vec3(0);
    ro = vec3(0.0, 0.2 + (sin(T * 0.5) + 1.0) * 0.4, -10.6 + sin(T * 0.2) * 3.0);
    ro.xz *= rot(T);

    // Using the above to produce the unit ray-direction vector.
    float FOV = PI / 4.; // FOV - Field of view.
    vec3 forward = normalize(lookAt.xyz - ro);
    vec3 right = normalize(vec3(forward.z, 0., -forward.x )); 
    vec3 up = cross(forward, right);    
    rd = normalize(forward + FOV * uv.x * right + FOV * uv.y * up);
}

void main(void) {
    
    vec3 pc = vec3(0.0); //pixel colour
    float edge = 0.0;
    vec3 lp = vec3(4.0, 5.0, -2.0);
    float mint = FAR;
    
    vec3 ro, rd;
    setupCamera(ro, rd, gl_FragCoord.xy);    

    vec3 fo = vec3(0.0, -2.8, 0.0);
    vec3 fn = vec3(0.0, 1.0, 0.0);
    
    float ft = planeIntersection(ro, rd, fn, fo);
    if (ft > 0.0 && ft < FAR) {
        
        //floor
        mint = ft;
        vec3 rp = ro + rd * ft;
        vec3 rpb = ro + rd * (ft - EPS);
        vec3 ld = normalize(lp - rp);
        float lt = length(lp - rp);
        float diff = clamp(dot(fn, ld) ,0.0, 1.0);
        
        //checker board
        rp.x += T * -8.0;
        vec3 sc = vec3(0.0); //texture(iChannel0, rp.xz * 0.1).xyz;
        vec2 mx = mod(rp.xz, 4.0) - 2.0;
        if (mx.x * mx.y > 0.0) sc = vec3(0.8); // + texture(iChannel0, rp.xz * 0.2).xyz * 0.1;
        
        //reflections
        float rEdge = 0.0;
        vec3 rrd = reflect(rd, fn);
        Hit rt = traceCubes(rpb, rrd, rEdge);
        if (rt.tN > 0.0 && rt.tN < FAR) {
            sc += colourCubes(rt, rpb, rrd, lp, rEdge, pc) * exp(-rt.tN * rt.tN * 0.1);    
        }
        
        //shadow
        float shad = 1.0;
        float shadEdge = 0.0;
        Hit st = traceCubes(rpb, ld, shadEdge);
        if (st.tN > 0.0 && st.tN < lt) {
            shad = (0.1 + st.id * 0.2) * st.tN / lt ;
        }
        if (shadEdge > 0.0) {
            shad *= st.tN / lt;
        }
        shad = clamp(shad, 0.1, 1.0);
        
        pc = sc * diff * shad;
    }
    
    vec3 ca = vec3(-2.0, 0.0, 0.0);
    vec3 cb = vec3(7.0, 0.0, 0.0);
    vec4 ci = iCylinder(ro, rd, ca, cb, 3.0); 

    if (ci.x > 0.0) {
        
        ro = ro + rd * ci.x;    
        //pc += vec3(0.0, 0.0, 1.0) * 0.2; //bounding cylinder
           
        float edge = 0.0;//
        Hit t = traceCubes(ro, rd, edge);
        if (t.tN > 0.0 && t.tN < FAR) {
            mint = min(mint, t.tN);                        
            pc = colourCubes(t, ro, rd, lp, edge, pc);
        }
    }
    
    float fog = 1.0 - exp(-mint * mint * 0.5 / FAR);
    //pc = mix(pc, vec3(0.0), fog);
    
    glFragColor = vec4(pc, 1.0);
}
