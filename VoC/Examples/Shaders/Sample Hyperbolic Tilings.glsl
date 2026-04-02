#version 420

// original https://www.shadertoy.com/view/7dcXDB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    A mimic of shane's work at https://www.shadertoy.com/view/WlBczG.
    
    Show the basic procedure to draw a 2d hyperbolic Poincare tiling.

*/

#define PI          3.14159265
#define TAU          6.28318531
#define inf       -1.0
#define MAX_ITER  30

// the smaller this value, the larger the black area
#define BlackRegionSize   0.065

// the first entry in PQR must be finite, other two entries can be either finite or infinite
const vec3 PQR = vec3(3, 3, 7);

// reflection mirrors
vec2 A, B;
vec3 C;

// two vertices of the fundamental triangle, the 3rd one is the origin
vec2 v0, m0;

// count the number of reflections across each mirror
float count;

// compute cos(PI / x), for x = infiniy this is cos(0) = 1.0
float dihedral(float x) { return x == inf ? 1. : cos(PI / x); }

mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

void init() {

    float cAB = dihedral(PQR.x);
    float sAB = sqrt(1. - cAB*cAB);
    
    A = vec2(1, 0);
    B = vec2(-cAB, sAB);
    
    float cAC = dihedral(PQR.y);
    float cBC = dihedral(PQR.z);
    
    float k1 = cAC;
    float k2 = (cBC + cAB*cAC) / sAB;
    float r = 1. / sqrt(k1*k1 + k2*k2 - 1.);
    
    C = vec3(k1, k2, 1.)*r;
    
    v0 = vec2(0., C.y - sqrt(r*r - C.x*C.x));
    vec2 n = vec2(-B.y, B.x);
    float b = dot(C.xy, n);
    float c = dot(C.xy, C.xy) - r*r;
    float k = b + sqrt(b*b-c);
    m0 = k*n;
}

bool try_reflect(inout vec2 p, vec2 mirror, inout float count) {
    float k = dot(p, mirror);
    if (k >= 0.)
        return true;
    p -= 2. * k  * mirror;
    count += 1.;
    return false;
}

bool try_reflect(inout vec2 p, vec3 sphere, inout float count) {
    vec2 cen = sphere.xy;
    float r = sphere.z;
    float d = length(p - cen) - r;
    if (d >= 0.)
        return true;
    p -= cen;
    p *= r * r/ dot(p, p);
    p += cen;
    count += 1.;
    return false;
}

bool fold(inout vec2 p, inout float count) {
    count = 0.;
    for (int k = 0; k < MAX_ITER; k++) {
        bool cond = true;
        cond = cond && try_reflect(p, A, count);
        cond = cond && try_reflect(p, B, count);
        cond = cond && try_reflect(p, C, count);
        if (cond)
            return true;
    }
    return false;
}

float sBox(in vec2 p, in vec2 b) {
    vec2 d = abs(p) - b;
    return min(max(d.x, d.y), 0.) + length(max(d, 0.));
}

float lBox(vec2 p, vec2 a, vec2 b, float ew) {
    float ang = atan(b.y - a.y, b.x - a.x);
    p = rot2(ang)*(p - mix(a, b, .5));

    vec2 l = vec2(length(b - a), ew);
    return sBox(p, (l + ew)/2.) ;
}

vec2 mouseInversion(vec2 p) {
    vec2 m = vec2((2.*mouse*resolution.xy.xy - resolution.xy)/resolution.y);
    if(length(m) < 1e-3) m += 1e-3; 
    if(abs(m.x)>.98*.7071 || abs(m.y)>.98*.7071) m *= .98;

    float k = 1./dot(m, m);
    vec2 invCtr = k*m;
    float t = (k - 1.)/dot(p -invCtr, p - invCtr);
    p = t*p + (1. - t)*invCtr;
    p.x = -p.x;
    return p;    
}

void main(void) {
    vec2 uv = (2.*gl_FragCoord.xy - resolution.xy)/resolution.y;
    uv *= 1.05;
    vec2 p = uv;
    p = mouseInversion(p);
    p = rot2(time/16.)*p;

    init();   
    
    if(length(p)> 1.)
        p /= dot(p, p);
  
    bool found = fold(p, count);
    
    float ln = 1e5, ln2 = 1e5, pnt = 1e5;

    ln = min(ln, lBox(p, vec2(0), v0, .007));
    ln = min(ln, lBox(p, vec2(0), m0, .007));
    ln = min(ln, length(p-C.xy) - C.z - 0.007);

    
    ln2 = min(ln2, lBox(p, vec2(0), m0, .007));
    pnt = min(pnt, length(p - v0)); 
    pnt = min(pnt, length(p - m0)); 
    
    float ssf = (2. - smoothstep(0., .25, abs(length(uv) - 1.) - .25));
    float sf = 2./resolution.y*ssf;
        
    vec3 oCol = .55 + .45*cos(count*TAU / 8. + vec3(0, 1, 2));
    float pat = smoothstep(0., .25, abs(fract(ln2*50. - .2) - .5)*2. -.2);
   
    float sh = clamp(.65 + ln/v0.y*4., 0., 1.);
    
    vec3 col = min(oCol*(pat*.2 + .9)*sh, 1.);
    
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, ln));
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, -(ln - BlackRegionSize)));

    pnt -= .032;
    pnt = min(pnt, length(p) - .032);
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, pnt));
    col = mix(col, vec3(1, .8, .3), 1. - smoothstep(0., sf, pnt + .02));
    
    vec3 bg = vec3(1, .2, .4);
    bg *= .7*(mix(col, vec3(1)*dot(col, vec3(.299, .587, .114)), .5)*.5 + .5);
    pat = smoothstep(0., .25, abs(fract((uv.x - uv.y)*43. - .25) - .5)*2. -.5);
    bg *= max(1. - length(uv)*.5, 0.)*(pat*.2 + .9);
    
    float cir = length(uv);
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*10., abs(cir - 1.) - .05))*.7);
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*2., abs(cir - 1.) - .05)));
    col = mix(col, vec3(.9) + bg, (1. - smoothstep(0., sf, abs(cir - 1.) - .03)));
    col = mix(col, col*max(1. - length(uv)*.5, 0.), (1. - smoothstep(0., sf, -cir + 1.05)));
    col = mix(col, bg, (1. - smoothstep(0., sf, -cir + 1.05)));
    
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, abs(cir - 1.035) - .03))*.8);
    col = mix(col, 1. - exp(-col), .35);

    //debug mirrors
/*
    col = mix(col, vec3(1, 0, 0), 1. - smoothstep(0., 0.01, abs(dot(uv, A)) - 0.01));
    col = mix(col, vec3(1, 0, 0), 1. - smoothstep(0., 0.01, abs(dot(uv, B)) - 0.01));
    col = mix(col, vec3(1, 0, 0), 1. - smoothstep(0., 0.02, abs(length(uv-C.xy) - C.z))-0.01);
*/
    glFragColor = vec4(sqrt(max(col, 0.)), 1.);
}
