#version 420

// original https://www.shadertoy.com/view/4slcR8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by SHAU - 2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

/*
    An attempt at an implementation of enhanced sphere tracing inspired by a few recent really nice examples :)

    Enhanced Sphere Tracing by Patu
    https://www.shadertoy.com/view/4tVXRV

    accelerated ray marching by nshelton
    https://www.shadertoy.com/view/llySW1

    and more but I cannot find the links at the moment so sorry if I forgot you

*/

#define EPS 0.001
#define FAR 80.0 
#define STEPS 200
#define PI 3.1415

const float freqA = 0.15;
const float freqB = 0.25;
const float ampA = 2.4;
const float ampB = 1.7;

// The path is a 2D sinusoid that varies over time, depending upon the frequencies, and amplitudes.
// Borrowed from Subterranean Cavern by Shane https://www.shadertoy.com/view/XlXXWj
vec2 path(in float z) {
    return vec2(ampA * sin(z * freqA), ampB * cos(z * freqB));
}

//Optimisation by Fabrice (I think?)
mat2 rot(float x) {
    return mat2(cos(x), sin(x), -sin(x), cos(x));
}

/* Distance functions - IQ */
float sdBox(vec3 p, vec3 b, vec3 bc) {
    vec3 d = abs(p - bc) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));;
}

float sdBoxes(vec3 rp, vec3 b, vec3 bc) {    
    float msd = sdBox(rp, b, bc + vec3(1.0, 1.0, 1.0));
    msd = min(msd, sdBox(rp, b, bc + vec3(1.0, 1.0, -1.0)));
    msd = min(msd, sdBox(rp, b, bc + vec3(-1.0, 1.0, 1.0)));
    msd = min(msd, sdBox(rp, b, bc + vec3(-1.0, 1.0, -1.0)));
    msd = min(msd, sdBox(rp, b, bc + vec3(1.0, -1.0, 1.0)));
    msd = min(msd, sdBox(rp, b, bc + vec3(1.0, -1.0, -1.0)));
    msd = min(msd, sdBox(rp, b, bc + vec3(-1.0, -1.0, 1.0)));
    msd = min(msd, sdBox(rp, b, bc + vec3(-1.0, -1.0, -1.0)));
    return msd;
}

float dfScene(vec3 rp) {
    
    float msd = 99.0;
    
    vec3 bc1 = vec3(0.0, 0.0, 0.0); //box center
    bc1.xy += path(rp.z + time); //cube array follows path
    rp.z = mod(rp.z - 2.0, 4.0) - 2.0; //repeay on z axis
    
    //box array
    msd = sdBoxes(rp, vec3(0.8), bc1);
    
    return msd;
}

//simple fog from IQ
vec3 applyFog(in vec3 rgb, in float distance) {
    float b = 0.1;
    float fogAmount = 1.0 - exp(-distance * b);
    vec3  fogColor  = vec3(0.);
    return mix(rgb, fogColor, fogAmount);
}

// IQ - cosine based palette, 4 vec3 params
vec3 palette1(in float t) {
    vec3 CP1A = vec3(0.5, 0.5, 0.5);
    vec3 CP1B = vec3(0.5, 0.5, 0.5);
    vec3 CP1C = vec3(2.0, 1.0, 0.0);
    vec3 CP1D = vec3(0.50, 0.20, 0.25);
    return CP1A + CP1B * cos(6.28318 * (CP1C * t + CP1D));
}

// The normal function with some edge detection rolled into it from Shane
vec3 edgeSurfaceNormal(vec3 p, float dist, inout float edge) { 
    
    //vec2 e = vec2(EPS, 0);
    vec2 e = vec2((FAR / dist * 0.5) / resolution.y, 0);
    
    // Take some distance function measurements from either side of the hit point on all three axes.
    float d1 = dfScene(p + e.xyy), d2 = dfScene(p - e.xyy);
    float d3 = dfScene(p + e.yxy), d4 = dfScene(p - e.yxy);
    float d5 = dfScene(p + e.yyx), d6 = dfScene(p - e.yyx);
    float d = dfScene(p) * 2.0;    // The hit point itself - Doubled to cut down on calculations. See below.
     
    // Edges - Take a geometry measurement from either side of the hit point. Average them, then see how
    // much the value differs from the hit point itself. Do this for X, Y and Z directions. Here, the sum
    // is used for the overall difference, but there are other ways. Note that it's mainly sharp surface 
    // curves that register a discernible difference.
    edge = abs(d1 + d2 - d) + abs(d3 + d4 - d) + abs(d5 + d6 - d);
    //edge = max(max(abs(d1 + d2 - d), abs(d3 + d4 - d)), abs(d5 + d6 - d)); // Etc.
    
    // Once you have an edge value, it needs to normalized, and smoothed if possible. How you 
    // do that is up to you. This is what I came up with for now, but I might tweak it later.
    edge = smoothstep(0., 1., sqrt(edge/e.x*2.));
    
    // Return the normal.
    // Standard, normalized gradient mearsurement.
    return normalize(vec3(d1 - d2, d3 - d4, d5 - d6));
}
//*/

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

//TODO: DON'T DELETE FOR NOW AS WE NEED TO DO SOME PERFOMANCE TESTING

/*
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
//*/

// http://erleuchtet.org/~cupe/permanent/enhanced_sphere_tracing.pdf
float relaxedMarch(vec3 ro, vec3 rd) {
    
    float igt = time;
    float pixelRadius = 0.001; //TODO: work out pixel radius
    float relax = 1.2; //relaxation
    float t = EPS; //actual distance marched
    float candidate_error = 1e32; // TODO: I don't quite understand the logic behind this
    float candidate_t = EPS; //marched distance used for rendering
    float previousRadius = 0.0; //minimum surface distance from previous march iteration
    float stepLength = 0.0; //length of march step 
    float functionSign = dfScene(ro) < 0.0 ? -1.0 : 1.0; //outside or inside of geometry?
    
    for (int i = 0; i < STEPS; i++) {
        
        float signedRadius = functionSign * dfScene(ro + rd * t);
        float radius = abs(signedRadius);
        previousRadius = radius;
        
        bool sorFail = relax > 1.0 && (radius + previousRadius) < stepLength;
        if (sorFail) {
            stepLength -= relax * stepLength; //oops we may have overstepped. Step back
            relax = 1.0; //turn relaxation off
            //TODO: turn relaxation on again with a wait condition?
        } else {
            stepLength = signedRadius * relax; //relaxed march
            //prevent exessive stepping for glancing rays (I think?) 
            float error = radius / t;
            if (error < candidate_error) {
                candidate_t = t;
                candidate_error = error;
            }
            if (error < pixelRadius || t > FAR) break;
        }
        
        t += stepLength;
    }
    
    if (candidate_error > pixelRadius) {candidate_t = FAR;}
    return candidate_t;
}

void main(void) {
    
    vec3 pc = vec3(0.0);
    float igt = time;
    
    //coordinate system
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    
    //camera
    vec3 lookAt = vec3(0.0, 0.0, igt * 2.0);
    vec3 ro = lookAt + vec3(4.0, 4.0, sin(igt * 0.125) * 10.0);
    ro.xy *= rot(igt * 0.5);

    float FOV = PI / 3.0; // FOV - Field of view.
    vec3 forward = normalize(lookAt - ro);
    vec3 right = normalize(vec3(forward.z, 0.0, -forward.x )); 
    vec3 up = cross(forward, right);

    vec3 rd = normalize(forward + FOV * uv.x * right + FOV * uv.y * up);

    /* compare normal marching against enhanced sphere marching (relaxedMarch) */ 
    //float d = marchScene(ro, rd);
    float d = relaxedMarch(ro, rd);
    
    if (d < FAR) {

        vec3 sc = vec3(0.0, 0.0, 0.0); //surface colour
        float edge = 0.0; //edge factor
        vec3 lp = normalize(vec3(5.0, 8.0, -3.0)); //light position
        vec3 rp = ro + rd * d; //ray surface intersection
        vec3 n = edgeSurfaceNormal(rp, d, edge);
        float ao = calcAO(rp, n);
        
        float diff = max(dot(n, lp), 0.0); //diffuse
        
        vec3 ec = palette1(igt + rp.z ); //edge colour
        
        pc = sc * 0.5 + diff * sc * ao + edge * ec;
        float spe = pow(max(dot(reflect(rd, n), lp), 0.), 16.); //specular.
        pc = pc + spe * vec3(1.0);
    }
    
    pc = applyFog(pc, d * 0.5);
    glFragColor = vec4(pc, 1.0);
}
