#version 420

// original https://www.shadertoy.com/view/ctfXRs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Thanks to (everyone I've copied code + ideas from):
// TheArtOfCode - raymarching
//  BlackleMori - hash, erot
//      Sizertz - AO, shadow
//        NuSan - materials
//        Tater - raymarching
//         Leon - raymarching hash trick
//           iq - pal, smin, most things!

#define tau 6.2831853071
#define pi 3.1415926535
#define thc(a,b) tanh(a*cos(b))/tanh(a)
#define ths(a,b) tanh(a*sin(b))/tanh(a)
//#define pal(a,b) .5+.5*cos(2.*pi*(a+b))
#define pal(a) .5+.5*cos(2.*pi*(a))
#define sabs(x) sqrt(x*x+1e-2)
//#define sabs(x, k) sqrt(x*x+k)
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))

#define FK(k) floatBitsToInt(k*k/7.)^floatBitsToInt(k)
float hash(float a, float b) {
    int x = FK(a), y = FK(b);
    return float((x*x+y)*(y*y-x)-x)/2.14e9;
}

vec3 erot(vec3 p, vec3 ax, float ro) {
  return mix(dot(ax, p)*ax, p, cos(ro)) + cross(ax,p)*sin(ro);
}

float cc(float a, float b) {
    float f = thc(a, b);
    return sign(f) * pow(abs(f), 0.25);
}

float cs(float a, float b) {
    float f = ths(a, b);
    return sign(f) * pow(abs(f), 0.25);
}

float h21(vec2 a) { return fract(sin(dot(a.xy, vec2(12.9898, 78.233))) * 43758.5453123); }
float mlength(vec2 uv) { return max(abs(uv.x), abs(uv.y)); }
float mlength(vec3 uv) { return max(max(abs(uv.x), abs(uv.y)), abs(uv.z)); }

// Maybe remove this
float sfloor(float a, float b) { return floor(b-.5)+.5+.5*tanh(a*(fract(b-.5)-.5))/tanh(.5*a); }

vec2 smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0., 1.);
    return vec2(mix(b, a, h) - k * h * (1. - h), h);
}

float smax(float a, float b, float k) {
    float h = clamp(0.5 - 0.5 * (b - a) / k, 0., 1.);
    return mix(b, a, h) + k * h * (1. - h); 
}

#define MAX_STEPS 400
#define MAX_DIST 100.
#define SURF_DIST .001

#define t time
#define TEST 8.

//https://www.shadertoy.com/view/sslGzN
const float Semitone  = 1.05946309436; //12 notes between an octave, octave is 2, so a semitone is 2^(1/12)

float KeyToFrequency(float n){
    return pow(Semitone,(n-8.))*440./48000.;
}

vec3 ori() {
    vec2 m = mouse*resolution.xy.xy/resolution.xy;
    float r = mix(100., 12., tanh(.2*t));
    vec3 ro = vec3(r*cos(.8*t), cos(1.7 * t), r*sin(.8*t));
    //ro.yz *= rot(-m.y*3.14+1.);
    //ro.xz *= rot(-m.x*6.2831);
    return ro;
}

vec2 map(vec3 p) {

    // Torus (thin)
    vec3 p1 = p;
    p1.xy *= rot(0.5 * t);
    p1.yz *= rot(0.215 * t);
    float d1 = length(p1.xy) - 0.5;
    float td = length(vec2(p1.z,d1));
   
    // Sphere
    float sd = length(p) - 1.25;
 
    // Mix between stuff
    float mx = .5 + .5 * thc(5., 0. * length(p) + 0.5 * t);
    float mx2 = .5 + .5 * thc(5., 0. * length(p) + 0.4 * t);
    
    // Scale a grid using distance functions
    // (this is a mess and I don't understand it)
    // sc also used for color
    float sc = smin(td, sd, 1.).y;
    sc *= 0.25 * TEST;
    sc -= 0.5 * mix(td, sd, mix(0., 2., mx2));    
    
    p.yz *= rot(0.4 * t);
    
    // Mix between 3D sphere grid and 2D column grid
    vec3 p2 = mod(p - 0.5 * sc, sc) - 0.5 * sc;    
    float d = mix(length(p2) + 0.2 * sc, 
                  length(p2.xz) + 0.12 * sc, 
                  mx);
    
    // Oscillate sphere in centre
    float s = 0.0; //texture(iChannel1, vec2(14., 0.25)).x;
    d = min(d, length(p) - 2. * s);
    
    // Restrict shape to sphere
    d = smax(d, length(p) - 10., 1.);

    // Cut out sphere around camera (didnt work for hollow shapes)
    //float camd = length(p - ori()) - 2.2;
    //d = -smin(-d, camd, 0.5).x;
    
    return vec2(d, sc);
}

vec3 march(vec3 ro, vec3 rd, float z) {    
    float d = 0.;
    float s = sign(z);
    int steps = 0;
    float mat = 0.;
    for(int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * d;
        vec2 m = map(p);
        // use hash to hide artifacts
        m.x *= 0.7 + 0.3 * hash(hash(p.x,p.z), p.y);
        if (s != sign(m.x)) { z *= 0.5; s = sign(m.x); }
        if (abs(m.x) < SURF_DIST || d > MAX_DIST) {
            steps = i + 1;
            mat = m.y;
            break;
        }
        d += m.x * z; 
    }   
    return vec3(min(d, MAX_DIST), steps, mat);
}

vec3 norm(vec3 p) {
    float d = map(p).x;
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        map(p-e.xyy).x,
        map(p-e.yxy).x,
        map(p-e.yyx).x);
    
    return normalize(n);
}

vec3 dir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i);
    return d;
}

float AO(in vec3 p, in vec3 n) {
    float occ = 0.;
    float sc = 1.;
    for (float i = 0.; i < 5.; i++) {
        float h = 0.015 + 0.015 * i;
        float d = map(p+h*n).x;
        occ += (h-d)*sc;
        sc *= 0.95;
    }
    return clamp(1. - 3.*occ, 0., 1.);
}

float shadow(in vec3 ro, in vec3 rd) {
    float res = 1.;
    float t = SURF_DIST;
    for (int i=0; i<24; i++)
    {
        float h = map(ro + rd * t).x;
        float s = clamp(32. * h / t, 0., 1.);
        res = min(res, s);
        t += clamp(h, 0.01, 0.2);
        if(res<SURF_DIST || t>MAX_DIST ) break;
    }
    res = clamp(res, 0.0, 1.0);
    return smoothstep(0., 1., res);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    vec3 ro = ori();
    
    vec3 rd = dir(uv, ro, vec3(0), 1.6);
    vec3 col = vec3(0);
   
    vec3 m = march(ro, rd, 1.);  
    float d = m.x;    
    vec3 p = ro + rd * d;
    float l = length(p);
    
    vec3 bg = vec3(244,242,199)/255.;
    
    if (d<MAX_DIST) {        
        vec3 n = norm(p);        

        vec3 ld = -normalize(p);
        float dif  = dot(n,  ld)*.5+.5;
        float spec = pow(dif, 40.);
        float fres = pow(1. + dot(rd,n),  5.);
    
        // Texture (maybe looks better without)
        vec3 an = abs(n);
        vec3 c1 = vec3(0.0); //texture(iChannel0, 0.14 * p.xy).rgb;
        vec3 c2 = vec3(0.0); //texture(iChannel0, 0.14 * p.yz).rgb;
        vec3 c3 = vec3(0.0); //texture(iChannel0, 0.14 * p.zx).rgb;
        col = an.z*c1+an.x*c2+an.y*c3;

        // Shadow
        float sd = shadow(p + 10. * SURF_DIST * n, ld);
        col *= .5+.5*sd;
        
        // Specular
        col = clamp(col + spec, 0., 1.);
        
        // Ambient occlusion (used incorrectly)
        float ao = AO(p + 10. * SURF_DIST * n, n);
        col = mix(col, vec3(1,0.5,0), .2+.2*thc(4.,8.*ao));
        
        // Fresnel (within 3.9-20. length from origin, was buggy)
        float s = smoothstep(3.9, 5., l);// * (1.-smoothstep(14.,20., l));
        col = mix(col, bg, s * fres);
    }
    else 
       col = bg;
   
    float xp = exp(-0.077 * l);
    vec3 pl = pal(.5*log(l) + .73 + xp*m.z + (1.-xp)*vec3(.5,1,2)/3.);
    col = mix(col, pl, xp);
    col = 1. - col;
    col = pow(col, vec3(1./2.2)); // gamma correction
    col = 1. - col;  

    // tanh causes artifacts
    float o = 2.*pi/3.;
    vec3 off = 0.4 * tanh(0.2 * t) * cos(t + vec3(-o,o,0));
    col = tanh(vec3(.1,0,0) + (vec3(3.5,3.35,2.5)+off)*col);

    glFragColor = vec4(col,1.0);
}
