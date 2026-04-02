#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wtXGRf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by SHAU - 2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

/*
    Some nice K-IFS example:

    Nightmist by NuSan
    https://www.shadertoy.com/view/tlX3zB

    Gold and Silver by NuSan
    https://www.shadertoy.com/view/tss3Rs

    KIFS Flythrough by Shane
    https://www.shadertoy.com/view/XsKXzc

    evvvvil - [TWITCH] Volumetric Merrygoround
    https://www.shadertoy.com/view/tsjGR3

    Flux Core by Otavio Good
    https://www.shadertoy.com/view/ltlSWf

*/

#define R resolution.xy
#define EPS .005
#define FAR 100.
#define T time
#define PI 3.141592
#define MT mod(T,60.)

#define UI0 1597334673U
#define UI1 3812015801U
#define UI2 uvec2(UI0, UI1)
#define UI3 uvec3(UI0, UI1, 2798796415U)
#define UIF (1.0 / float(0xffffffffU))

//Dave Hoskins - Hash without Sin V2
float hash11(float p) {
    uvec2 n = uint(int(p)) * UI2;
    uint q = (n.x ^ n.y) * UI0;
    return float(q) * UIF;
}

//Fabrice - compact rotation
mat2 rot(float x) {return mat2(cos(x), sin(x), -sin(x), cos(x));}

vec2 path(float t) {
    float a = sin(t * PI / 32. + 1.5707);
    float b = cos(t * PI / 32.);
    return vec2(a * 2., b * a);    
}

float PD(float t) {return (sin(t)+1.)*.5;}

vec3 planes(vec3 rd, vec3 c) {
    float a = (atan(rd.y, rd.x) / (PI * 2.)) + .5, //polar
          fla = floor(a * 24.) / 24., //split into 24 segemnts
          fra = fract(a * 24.),
          frnd = hash11(fla * 400.);
    vec3 pc = c * frnd * step(0.1, fra); //mix colours radially
    float mt = mod(abs(rd.y) + frnd * 4. - T * 0.1, 0.3); //split segments 
    pc *= step(mt, 0.16) * mt * 16.; //split segments
    return pc * max(abs(rd.y), 0.); //fade middle
}

// see mercury sdf functions
// Repeat around the origin by a fixed angle.
// For easier use, num of repetitions is use to specify the angle.
float pModPolar(inout vec2 p, float repetitions) {
    float angle = 2.0 * PI / repetitions;
    float a = atan(p.y, p.x) + angle / 2.0;
    float r = length(p);
    float c = floor(a / angle);
    a = mod(a, angle) - angle / 2.0;
    p = vec2(cos(a), sin(a)) * r;
    // For an odd number of repetitions, fix cell index of the cell in -x direction
    // (cell index would be e.g. -5 and 5 in the two halves of the cell):
    if (abs(c) >= (repetitions / 2.0)) c = abs(c);
    return c;
}

//IQ - distance funcr=tions
float sdBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.) + length(max(d, 0.));
}

vec3 map(vec3 p) {

    p.xy += path(p.z);
    
    pModPolar(p.yx, 7.);
    
    float size = 1. + (clamp(MT,0.,3.)*2.) - (clamp(MT-23.,0.,3.)*2.) + (clamp(MT-30.,0.,3.)*2.)
                    - (clamp(MT-53.,0.,3.)*2.);
    
    //iterative space manipulation
    for(int i=0; i<5; ++i) {
        p.xz *= rot(float(i)+1.7);
        p.xz = abs(fract(p.xz/30. + .5) - .5)*30.; //NuSan
        p.xz -= size;
        size *= 0.5;
    }    

    p -= vec3(.9,5.9,.9);
    float t = sdBox(p, vec3(1.));
    t = max(t, -sdBox(p-vec3(.1,-.1,-.1), vec3(1.)));

    float b = length(p) - .6;
    
    return vec3(min(t, b), t, b);
}

vec3 normal(vec3 p) {  
    vec2 e = vec2(-1., 1.) * EPS;   
    return normalize(e.yxx * map(p + e.yxx).x + e.xxy * map(p + e.xxy).x + 
                     e.xyx * map(p + e.xyx).x + e.yyy * map(p + e.yyy).x);   
}

vec3 camera(vec2 U, vec3 ro, vec3 la, float fl) {
    vec2 uv = (U - R*.5) / R.y;
    vec3 fwd = normalize(la-ro),
         rgt = normalize(vec3(fwd.z, 0., -fwd.x));
    return normalize(fwd + fl*uv.x*rgt + fl*uv.y*cross(fwd, rgt));
}

void main(void) {

    vec4 C = glFragColor;
    vec2 U = gl_FragCoord.xy;    

    float AT = T * 6. - 3.;    
    float ch = 16. - (smoothstep(0.,4.,MT-26.)*16.) + (smoothstep(0.,4.,MT-56.)*16.);
    
    vec3 la = vec3(0.,0.,AT), //look at
         ro = vec3(0., ch, AT-14.), //ray origin
         ns = vec3(-1.), //nearest surface
         lp = vec3(2.,5.,AT-3.), //light position
         gc = vec3(0); //glow colour
    
    ///*
    ro.xy -= path(ro.z);
    ro.xy *= rot(T*.3);
    la.xy -= path(la.z);
    lp.xy -= path(lp.z);
    //*/
    
    vec3 rd = camera(U,ro,la,1.4); 

    vec3 pc = planes(rd, vec3(1.,0.,0.));
    
    //ray march
    float t = 0.;
    for (int i=0; i<196; i++) {
        vec3 p = ro + rd*t;
        ns = map(p);
        if (ns.x<EPS || t>FAR) break;
        gc += .1 * vec3(1.,.25,0.) / (1. + ns.z*ns.z*40.) * PD(p.z*.2+T); //glow
        t += ns.x*.3;
    }

    //shading
    if (t>0. && t<FAR) {
        vec3 p = ro + rd*t;
        vec3 n = normal(p);
        vec3 ld = normalize(lp-p);
        pc = vec3(.3) * max(.05,dot(ld,n));
        if (ns.x==ns.z) pc = mix(vec3(.1,.05,0.), vec3(1.,.5,0.), PD(p.z*.2+T));
    }
    pc+=gc;
      
    C =vec4(pc,1.);

    glFragColor = C;
}
