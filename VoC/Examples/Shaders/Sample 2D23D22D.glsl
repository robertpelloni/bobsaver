#version 420

// original https://www.shadertoy.com/view/XdXcR7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by SHAU - 2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define EPS 0.001
#define FAR 80.0 
#define STEPS 200
#define PI 3.1415
#define IGT time

//animation
//2D
float xoff = 0.0; //x offset
float yoff = 0.0; //y offset
float ra = 0.0; //rotation angle
float zoom = 2.0; //zoom
//Cube rotations
float cuberotyz = 0.0;
float cuberotxz = 0.0;
//Camera
vec3 lookAt = vec3(0.5, 0.0, 0.5);
vec3 camPos = vec3(0.0, 0.35, 0.001);
float camRot = 0.0; 
//turn specular off when close to surface
float specfact = 0.0;

//Ugly timeline code
void timeline() {
    
    float igt = mod(IGT, 25.0);
    
    if (igt < 2.0) {
        xoff = 1.0 + igt;
        yoff = 1.0;
        zoom = 4.0;
    } else if (igt < 4.0) {
        xoff = 3.0;
        yoff = igt * 0.5;
        zoom = 4.0;        
    } else if (igt < 6.0) {
        xoff = 3.0 + (igt - 4.0) * 0.5;
        yoff = 2.0;
        zoom = 4.0;        
    } else if (igt < 8.0) {
        xoff = 1.0;
        ra = (igt - 6.0) * PI * 0.25;
    } else if (igt < 10.0) {
        xoff = (igt - 8.0) * 0.5;
        yoff = (igt - 8.0) * 0.5;
        zoom = 4.0;
        lookAt.xz -= (igt - 8.) * 0.125;
        camPos.y += (igt - 8.) * 0.25;
        specfact += (igt - 8.) * 0.25;
    } else if (igt < 12.0) {
        xoff = 1.0;
        yoff = 1.0;
        zoom = 4.0;
        lookAt.xz -= (igt - 8.) * 0.125;
        camPos.y += (igt - 8.) * 0.25;
        cuberotxz = (igt - 12.0) * PI * 0.25;
        specfact += (igt - 8.) * 0.25;
    } else if (igt < 14.0) {
        xoff = 1.0 + igt;
        yoff = 1.0;
        zoom = 4.0;
        lookAt = vec3(0.0);
        camPos.y = 1.35;
        camPos.z += (igt - 12.) * 0.5;
        specfact = 1.0;
    } else if (igt < 16.) {
        xoff = 3.0;
        yoff = 1. + (igt - 14.) * 0.5;
        zoom = 4.0;        
        lookAt = vec3(0.0);
        camPos.y = 1.35;
        camPos.z += 1.;
        camRot = (igt - 14.0) * PI * 0.25;
        specfact = 1.0;
    } else if (igt < 18.) {
        xoff = 3.0 + (igt - 16.0) * 0.5;
        yoff = 2.0;
        zoom = 4.0;        
        lookAt = vec3(0.0);
        camPos.y = 1.35;
        camPos.z += 1.;
        camRot = (igt - 14.0) * PI * 0.25;
        cuberotxz = (igt - 16.0) * PI * 0.25;
        specfact = 1.0;
    } else if (igt < 20.) {
        xoff = 1.0;
        ra = (igt - 6.0) * PI * 0.25;
        lookAt = vec3(0.0);
        camPos.y = 1.35;
        camPos.z += 1.;
        camRot = (igt - 14.0) * PI * 0.25;
        cuberotyz = (igt - 18.0) * PI * 0.25;
        cuberotxz = (igt - 16.0) * PI * 0.25;
        specfact = 1.0;
    } else if (igt < 22.) {
        xoff = (igt - 20.0) * 0.5;
        yoff = (igt - 20.0) * 0.5;
        zoom = 4.0;
        lookAt = vec3(0.0);
        camPos.y = 1.35;
        camPos.z += 1. - (igt - 20.) * 0.5;
        camRot = (igt - 14.0) * PI * 0.25;
        cuberotyz = (igt - 18.0) * PI * 0.25;
        cuberotxz = (igt - 16.0) * PI * 0.25;
        specfact = 1.0;
    } else if (igt < 24.) {
        xoff = 1.0;
        yoff = 1.0;
        zoom = 4.0;
        lookAt = vec3((igt - 22.) * -0.25, 0.0, (igt - 22.) * -0.25);
        camPos.y = 1.35 - (igt - 22.) * 0.5;
        specfact = 24. - igt;
    } else if (igt < 25.) {
        xoff = 1.0;
        yoff = 1.0;
        zoom = 4.0;
    }
}

//Optimisation by Fabrice (I think?)
mat2 rot(float x) {
    return mat2(cos(x), sin(x), -sin(x), cos(x));
}

/* Distance functions - IQ */
float sdBox(vec3 p, vec3 b) {    
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));;
}

float dfScene(vec3 rp) {
    float msd = 99.0;
    rp.xz = fract(rp.xz) - .5; //repeat
    rp.yz *= rot(cuberotyz);
    rp.xz *= rot(cuberotxz);
    msd = sdBox(rp, vec3(0.25));
    return msd;
}

// Checkerboard texture
float checkerboard(vec2 rp) {
    rp.x += xoff;
    rp.y += yoff;
    rp *= rot(ra);
    vec2 m = mod(rp, zoom) - vec2(zoom * 0.5);
    return m.x * m.y > 0.0 ? 0.0 : 1.0;
}

// Cube mapping - Adapted from one of Fizzer's routines by Shane.
vec3 cubeTex(vec3 p){
    p.yz *= rot(cuberotyz);
    p.xz *= rot(cuberotxz);
    // Mapping the 3D object position to the 2D UV coordinate of one of the six
    // faces of the cube. If using a single symmetrical texture, like here, nothing
    // else needs to be done. However, if you want to use different textures for 
    // each face, then each side has to be handled seperately.
    vec3 f = abs(p); // Needs to be offset by the sphere position. Ie: p - p0;
    // Elegant cubic space stepping trick, as seen in many voxel related examples.
    f = step(f.zxy, f)*step(f.yzx, f); 
    f.xy = f.x>.5? p.yz/p.x : f.y>.5? p.xz/p.y : p.xy/p.z; 
    // Custom 2D routine.
    float c = checkerboard(f.xy);   
    return vec3(c);
}

vec3 surfaceNormal(vec3 rp) {
    float e = 0.001;
    vec3 dx = vec3(e, 0.0, 0.0);
    vec3 dy = vec3(0.0, e, 0.0);
    vec3 dz = vec3(0.0, 0.0, e);
    return normalize(vec3(dfScene(rp + dx) - dfScene(rp - dx),
                          dfScene(rp + dy) - dfScene(rp - dy),
                          dfScene(rp + dz) - dfScene(rp - dz)));
}

//IQ
/* Doesn't work in some browsers
float softshadow(in vec3 ro, in vec3 rd, float mint, float maxt, float k) {
    float res = 1.0;
    for(float t = mint; t < maxt;) {
        float h = dfScene(ro + rd * t);
        if(h < EPS) return 0.0;
        res = min(res, k * h / t);
        t += h;
    }
    return res;
}
//*/

// Shadows. Lifted from Shane
float softshadow(vec3 ro, vec3 rd, float start, float end, float k){

    float shade = 1.0;

    float dist = start;

    // Max shadow iterations - More iterations make nicer shadows, but slow things down.
    for (int i=0; i < 24; i++){
    
        float h = dfScene(ro + rd*dist);
        shade = min(shade, k*h/dist);

        dist += clamp( h*.86, 0.01, 0.2);//min(h, stepDist);
        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (abs(h)<0.001 || dist > end) break; 
    }

    // Shadow value.
    return min(max(shade, 0.) + 0.25, 1.0); 
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

float marchScene(vec3 ro, vec3 rd) {
    
    float d = 0.0; //distance marched
    vec3 rp = vec3(0.0); //ray position
   
    for (int i = 0; i < STEPS; i++) {
        rp = ro + rd * d;
        float ns = dfScene(rp);
        d += ns;
        if (ns < EPS || d > FAR) break;
    }
    
    return d;
}

float raytraceFloor(vec3 ro, vec3 rd, vec3 n, vec3 o) {
    return dot(o - ro, n) / dot(rd, n);
}

void main(void) {
    
    timeline();
    
    vec3 pc = vec3(0.0); //pixel colour
    vec3 sc = vec3(1.0); //surface colour
    float edge = 0.0; //edge factor
    vec3 lp = vec3(1.0, 8.0, 1.0); //light position
    vec3 lc = vec3(1.0); //light colour
    float k = 16.0; //penumbra factor
    
    //coordinate system
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    
    //camera
    vec3 ro = lookAt + camPos;
    ro.xz *= rot(camRot);

    float FOV = PI / 3.0; // FOV - Field of view.
    vec3 forward = normalize(lookAt - ro);
    vec3 right = normalize(vec3(forward.z, 0.0, -forward.x )); 
    vec3 up = cross(forward, right);
    vec3 rd = normalize(forward + FOV * uv.x * right + FOV * uv.y * up);
   
    //raytace floor 
    vec3 fn = vec3(0, 1, 0); //floor normal
    float fd = raytraceFloor(ro, rd, fn, vec3(0, -1.0, 0)); //floor distance

    float d = marchScene(ro, rd);
    
    if (d < FAR) {

        vec3 rp = ro + rd * d; //ray surface intersection        
        sc = cubeTex(vec3(fract(rp.x) - 0.5, rp.y, fract(rp.z) - 0.5));
        vec3 n = surfaceNormal(rp);
        float ao = calcAO(rp, n);
        float diff = max(dot(n, normalize(lp)), 0.0); //diffuse
        pc = sc * 0.5 + diff * sc * ao;
        float spe = pow(max(dot(reflect(rd, n), normalize(lp)), 0.), 16.); //specular.
        pc = pc + spe * vec3(1.0) * specfact;
    
    
    } else if (fd > 0.0 && fd < FAR) {
        
        //shade floor
        vec3 rp = ro + rd * fd;
        vec3 ld = normalize(lp - rp); //direction to light
        float maxt = length(lp - rp); //distance to light
        float sf = softshadow(rp, ld, EPS, maxt, k); //shadow factor
        float li = sf * clamp(dot(fn, ld), 0.0, 1.0); //light intensity
        pc = sc * lc * li + vec3(0.25) * (1.0 - li); //shadow
    }

    glFragColor = vec4(pc, 1.0);
}
