#version 420

// original https://www.shadertoy.com/view/lt3SWM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define EPS 0.005
#define FAR 10.0
#define PI 3.1415

float igt = time;

int id = 0; //geometry id

mat2 rot(float x) {
    return mat2(cos(x), sin(x), -sin(x), cos(x));
}

/* Distance Functions IQ */

float sdBox(vec3 p, vec3 pos, vec3 size) {
    return max(max(abs(p.x - pos.x) -size.x, 
               abs(p.y - pos.y) - size.y),
               abs(p.z - pos.z) - size.z);
}

float sdCapsule(vec3 p, vec3 a, vec3 b, vec3 cs, float r) {
    p += cs;
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

//frame made of 12 capsules
float dfFrame(vec3 rp) {
    float msd = 9999.0;
    float r = 0.1;
    float c1 = sdCapsule(rp, 
                         vec3(0.0, 1.0, 0.0),
                         vec3(0.0, -1.0, 0.0),
                         vec3(1.0, 0.0, 1.0),
                         r);
    msd = min(msd, c1);
    float c2 = sdCapsule(rp.zxy, 
                         vec3(0.0, 1.0, 0.0),
                         vec3(0.0, -1.0, 0.0),
                         vec3(1.0, 0.0, 1.0),
                         r);
    msd = min(msd, c2);
    float c3 = sdCapsule(rp, 
                         vec3(0.0, 1.0, 0.0),
                         vec3(0.0, -1.0, 0.0),
                         vec3(-1.0, 0.0, 1.0),
                         r);
    msd = min(msd, c3);
    float c4 = sdCapsule(rp.zxy, 
                         vec3(0.0, 1.0, 0.0),
                         vec3(0.0, -1.0, 0.0),
                         vec3(1.0, 0.0, -1.0),
                         r);
    msd = min(msd, c4);
    float c5 = sdCapsule(rp, 
                         vec3(0.0, 1.0, 0.0),
                         vec3(0.0, -1.0, 0.0),
                         vec3(1.0, 0.0, -1.0),
                         r);
    msd = min(msd, c5);
    float c6 = sdCapsule(rp.zxy, 
                         vec3(0.0, 1.0, 0.0),
                         vec3(0.0, -1.0, 0.0),
                         vec3(-1.0, 0.0, 1.0),
                         r);
    msd = min(msd, c6);
    float c7 = sdCapsule(rp, 
                         vec3(0.0, 1.0, 0.0),
                         vec3(0.0, -1.0, 0.0),
                         vec3(-1.0, 0.0, -1.0),
                         r);
    msd = min(msd, c7);
    float c8 = sdCapsule(rp.zxy, 
                         vec3(0.0, 1.0, 0.0),
                         vec3(0.0, -1.0, 0.0),
                         vec3(-1.0, 0.0, -1.0),
                         r);
    msd = min(msd, c8);
    float c9 = sdCapsule(rp.yzx, 
                         vec3(0.0, 1.0, 0.0),
                         vec3(0.0, -1.0, 0.0),
                         vec3(1.0, 0.0, 1.0),
                         r);
    msd = min(msd, c9);
    float c10 = sdCapsule(rp.yzx, 
                         vec3(0.0, 1.0, 0.0),
                         vec3(0.0, -1.0, 0.0),
                         vec3(-1.0, 0.0, 1.0),
                         r);
    msd = min(msd, c10);
    float c11 = sdCapsule(rp.yzx, 
                         vec3(0.0, 1.0, 0.0),
                         vec3(0.0, -1.0, 0.0),
                         vec3(1.0, 0.0, -1.0),
                         r);
    msd = min(msd, c11);
    float c12 = sdCapsule(rp.yzx, 
                         vec3(0.0, 1.0, 0.0),
                         vec3(0.0, -1.0, 0.0),
                         vec3(-1.0, 0.0, -1.0),
                         r);
    msd = min(msd, c12);
    return msd;
}

float dfScene(vec3 rp) {
    float b = sdBox(rp, vec3(0.), vec3(1.));
    if (b < EPS) {
        id = 1;    
    }
    return min(dfFrame(rp), b);
}

vec3 surfaceNormal(vec3 p) { 
    vec2 e = vec2(5.0 / resolution.y, 0);
    float d1 = dfScene(p + e.xyy), d2 = dfScene(p - e.xyy);
    float d3 = dfScene(p + e.yxy), d4 = dfScene(p - e.yxy);
    float d5 = dfScene(p + e.yyx), d6 = dfScene(p - e.yyx);
    float d = dfScene(p) * 2.0;    
    return normalize(vec3(d1 - d2, d3 - d4, d5 - d6));
}

/* Colouring in stuff. Slowly getting it
//My pencil keeps on slipping over the lines but a little less often :) */

//Shane - hue rotation. I think I've used this in pretty much all of my shaders so far :)
vec3 rotHue(vec3 p, float a){
    vec2 cs = sin(vec2(1.570796, 0) + a);
    mat3 hr = mat3(0.299,  0.587,  0.114,  0.299,  0.587,  0.114,  0.299,  0.587,  0.114) +
              mat3(0.701, -0.587, -0.114, -0.299,  0.413, -0.114, -0.300, -0.588,  0.886) * cs.x +
              mat3(0.168,  0.330, -0.497, -0.328,  0.035,  0.292,  1.250, -1.050, -0.203) * cs.y;
    return clamp(p*hr, 0., 1.);
}

//concentric squares by Shnae.
float conSquares(vec2 p){   
    p = abs(fract(p) - .5) * 2.0;
    p.x = max(p.x + igt * 0.125, p.y + igt * 0.125);
    float c = fract(p.x * 4.);
    return min(c*.9, c*(.9 - c)*12.)/.9;    
}

// Cube mapping - Adapted from one of Fizzer's routines by Shane.
// Can you see some patterns forming here :)
vec3 cubeTex(vec3 p){
    // Mapping the 3D object position to the 2D UV coordinate of one of the six
    // faces of the cube. If using a single symmetrical texture, like here, nothing
    // else needs to be done. However, if you want to use different textures for 
    // each face, then each side has to be handled seperately.
    vec3 f = abs(p); // Needs to be offset by the sphere position. Ie: p - p0;
    // Elegant cubic space stepping trick, as seen in many voxel related examples.
    f = step(f.zxy, f)*step(f.yzx, f); 
    f.xy = f.x>.5? p.yz/p.x : f.y>.5? p.xz/p.y : p.xy/p.z; 
    // Custom 2D routine.
    float c = conSquares((f.xy + 1.)*.5)*.85 + .15;
    return vec3(c);
}

//A bump map from Shane
vec3 bump(vec3 rp, vec3 n) {
    float bumpfactor = 0.05;
    vec2 eps = vec2(2.0 / resolution.y, 0.0);
    float f = cubeTex(rp).x;
    float fx = cubeTex(rp - eps.xyy).x; // Nearby sample in the X-direction.
    float fy = cubeTex(rp - eps.yxy).x; // Nearby sample in the Y-direction.
    float fz = cubeTex(rp - eps.yyx).x; // Nearby sample in the Y-direction.
    vec3 grad = (vec3(fx, fy, fz ) - f) / eps.x;  // Without the extra samples.
    return normalize(n + grad * bumpfactor); // Bump the normal with the gradient vector. 
}  

//IQ
float calcAO(vec3 pos, vec3 nor) {   
    float occ = 0.0;
    float sca = 1.0;
    for(int i = 0; i < 5; i++) {
        float hr = 0.01 + 0.05*float(i);
        vec3 aopos = pos + nor*hr;
        occ += smoothstep(0.0, 0.7, hr - dfScene(aopos)) * sca;
        sca *= 0.97;
    }
    return clamp(1.0 - 3.0 * occ , 0.0, 1.0);
}

//volumetric march. Probably overkill in this case for what I'm trying to achieve
vec3 vMarch(vec3 rp, vec3 rd, vec3 lc) {
    vec3 pc = vec3(0.0);
    float d = 0.0;
    for (int i = 0; i < 80; i++) {
        rp = rp + rd * d;        
        float ns = dfScene(rp);
        d += 0.0125;
        float g = length(rp);
        pc += lc * exp(g * g) * 0.05; //lighter away from center
        if (ns > 0.0 || d > 20.0) break;
    }
    return pc;
}

//main march
vec3 marchScene(vec3 ro, vec3 rd) {
    
    vec3 pc = vec3(0.0); //returned pixel colour
    float d = 0.0; //distance marched
    vec3 rp = vec3(0.0); //ray position
   
    vec3 lp = normalize(vec3(2.0, 5.0, -3.0)); //light position
    vec3 sc = rotHue(vec3(0.5, 0.2, 0.8), mod(igt / 16., 6.283)); //scene colour

    for (int i = 0; i < 50; i++) {
        rp = ro + rd * d;
        float ns = dfScene(rp);
        d += ns;
        if (ns < EPS || d > FAR) break;
    }
    
    if (d < FAR) {
        
        //hit scene
        vec3 n = surfaceNormal(rp);

        if (id == 1) {
            //internal cube
            float glow = calcAO(rp, n); //not it's proper use but using ao to add some brightness to inner cube at edges
            n = bump(rp, n);
            float diff = max(dot(n, lp), 0.0);
            pc = sc * 0.05 + diff * sc * 0.5;
            float g = length(rp);
            pc += glow * sc * exp(g * g) * 0.05;
 
        } else {
            
            //frame
            pc = vMarch(rp, rd, sc);
        }
        
        float spe = pow(max(dot(reflect(rd, n), lp), 0.), 16.); // specular.
        pc += spe * vec3(1.0);
    }
    
    return pc;
}
    
void main(void) {
    
    //coordinate system
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = (uv * 2.0 - 1.0) * 0.5;
    uv.x *= resolution.x / resolution.y;
    
     //camera
    vec3 rd = normalize(vec3(uv, 2.));
    vec3 ro = vec3(0.0, 0.0, -6.5);
    
    //rotate camera
    ro.xy *= rot(igt * 0.5);
    rd.xy *= rot(igt * 0.5);
    ro.xz *= rot(igt * 0.45);
    rd.xz *= rot(igt * 0.45);
    ro.yz *= rot(igt * 0.85);
    rd.yz *= rot(igt * 0.85);
    //*/

    //ray marching
    glFragColor = vec4(marchScene(ro, rd), 1.0);
}
