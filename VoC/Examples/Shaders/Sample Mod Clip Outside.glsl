#version 420

// original https://www.shadertoy.com/view/flSXzV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define STEPS 64
#define PIXELR 0.5/resolution.x
#define FAR 50.0

#define PI 3.14159265
#define PHI (sqrt(5)*0.5 + 0.5)

#define HASHSCALE1 0.1031

const vec3 FOG_COLOR = vec3(0.5, 0.55, 0.65);

//Distance functions and helpper functions from Mercury's SDF library
//http://mercury.sexy/hg_sdf/

// Sign function that doesn't return 0
float sgn(float x) {
    return (x < 0.0)?-1.0:1.0;
}

// Maximum/minumum elements of a vector
float vmax3(vec3 v) {
    return max(max(v.x, v.y), v.z);
}

float fSphere(vec3 p, float r) {
    return length(p) - r;
}

// Plane with normal n (n is normalized) at some distance from the origin
float fPlane(vec3 p, vec3 n, float distanceFromOrigin) {
    return dot(p, n) + distanceFromOrigin;
}

// Cheap Box: distance to corners is overestimated
float fBoxCheap(vec3 p, vec3 b) { //cheap box
    return vmax3(abs(p) - b);
}

// Box: correct distance to corners
float fBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return length(max(d, vec3(0))) + vmax3(min(d, vec3(0)));
}

// Repeat space along one axis. Use like this to repeat along the x axis:
// <float cell = pMod1(p.x,5);> - using the return value is optional.
float pMod1(inout float p, float size) {
    float halfsize = size*0.5;
    float c = floor((p + halfsize)/size);
    p = mod(p + halfsize, size) - halfsize;
    return c;
}

// Repeat in two dimensions
vec2 pMod2(inout vec2 p, vec2 size) {
    vec2 c = floor((p + size*0.5)/size);
    p = mod(p + size*0.5,size) - size*0.5;
    return c;
}

// Rotate around a coordinate axis (i.e. in a plane perpendicular to that axis) by angle <a>.
// Read like this: R(p.xz, a) rotates "x towards z".
// This is fast if <a> is a compile-time constant and slower (but still practical) if not.
void pR(inout vec2 p, float a){
    p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

// Shortcut for 45-degrees rotation
void pR45(inout vec2 p) {
    p = (p + vec2(p.y, -p.x))*sqrt(0.5);
}

float sdf(vec3 p){
    // neighbour trick
    /*float cellIndex = pMod1(p.x, 4.0);
    vec3 p_ = p;
    pR(p_.yx, (cellIndex+0.0)*.2+time*.5);
    float box = fBox(p_, vec3(1.0));
    vec3 p1 = p+vec3(2.0,0.0,0.0);
    pR(p1.yx, (cellIndex-0.5)*.2+time*.5);
    float box1 = fBox(p1, vec3(1.0));
    vec3 p2 = p-vec3(2.0,0.0,0.0);
    pR(p2.yx, (cellIndex+0.5)*.2+time*.5);
    float box2 = fBox(p2, vec3(1.0));
    
    return min(box,min(box1,box2));*/
    
    // 1D full repetition of pMod
    /*vec3 p1 = p;    
    float cellIndex_ = pMod1(p1.x, 4.0);
    pR(p1.yx, cellIndex_*.5+time*.5);
    float box1 = fBox(p1, vec3(1.0));
    
    vec3 p2 = p+vec3(2.0,0.0,0.0);    
    float cellIndex2 = pMod1(p2.x, 4.0);
    cellIndex2 -= 0.5;
    pR(p2.yx, cellIndex2*.5+time*.5);
    float box2 = fBox(p2, vec3(1.0));    
    
    return min(box1,box2);*/
    
    
    // 2D full repetition of pMod
    vec2 gridSize = vec2(4.0);
    vec2 cellIndexRatio = vec2(0.333);
    float timeRatio = 1.0;
    
    vec3 p1 = p;    
    vec2 cellIndex1 = pMod2(p1.xz, gridSize);
    pR(p1.yx, length(cellIndex1*cellIndexRatio)+time*timeRatio);
    float box1 = fBox(p1, vec3(1.0));
    
    vec3 p2 = p+vec3(2.0,0.0,0.0);    
    vec2 cellIndex2 = pMod2(p2.xz, gridSize);
    cellIndex2 -= vec2(0.5, 0.0);
    pR(p2.yx, length(cellIndex2*cellIndexRatio)+time*timeRatio);
    float box2 = fBox(p2, vec3(1.0));
    
    vec3 p3 = p+vec3(0.0,0.0,2.0);    
    vec2 cellIndex3 = pMod2(p3.xz, gridSize);
    cellIndex3 -= vec2(0.0, 0.5);
    pR(p3.yx, length(cellIndex3*cellIndexRatio)+time*timeRatio);
    float box3 = fBox(p3, vec3(1.0));
    
    vec3 p4 = p+vec3(2.0,0.0,2.0);    
    vec2 cellIndex4 = pMod2(p4.xz, gridSize);
    cellIndex4 -= vec2(0.5, 0.5);
    pR(p4.yx, length(cellIndex4*cellIndexRatio)+time*timeRatio);
    float box4 = fBox(p4, vec3(1.0));
    
    
    return min(box1,min(box2,min(box3,box4)));
}

//calculate normals for objects
vec3 normals(vec3 p){
    vec3 eps = vec3(PIXELR, 0.0, 0.0 );
    return normalize(vec3(
        sdf(p+eps.xyy) - sdf(p-eps.xyy),
        sdf(p+eps.yxy) - sdf(p-eps.yxy),
        sdf(p+eps.yyx) - sdf(p-eps.yyx)
    ));
}

//Ambient occlusion method from https://www.shadertoy.com/view/4sdGWN
//Random number [0:1] without sine
float hash(float p){
    vec3 p3  = fract(vec3(p) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 randomSphereDir(vec2 rnd){
    float s = rnd.x*PI*2.;
    float t = rnd.y*2.-1.;
    return vec3(sin(s), cos(s), t) / sqrt(1.0 + t * t);
}
vec3 randomHemisphereDir(vec3 dir, float i){
    vec3 v = randomSphereDir( vec2(hash(i+1.), hash(i+2.)) );
    return v * sign(dot(v, dir));
}

float ambientOcclusion( in vec3 p, in vec3 n, in float maxDist, in float falloff ){
    const int nbIte = 32;
    const float nbIteInv = 1./float(nbIte);
    const float rad = 1.-1.*nbIteInv; //Hemispherical factor (self occlusion correction)
    
    float ao = 0.0;
    
    for( int i=0; i<nbIte; i++ )
    {
        float l = hash(float(i))*maxDist;
        vec3 rd = normalize(n+randomHemisphereDir(n, l )*rad)*l; // mix direction with the normal
                                                                // for self occlusion problems!
        
        ao += (l - max(sdf( p + rd ),0.)) / maxDist * falloff;
    }
    
    return clamp( 1.-ao*nbIteInv, 0., 1.);
}

vec3 colorify(vec3 ld, vec3 p, vec3 lc){

    vec3 cc = vec3(0.8) * (ambientOcclusion(p, normals(p), 4.0, 2.0) + 
                           ambientOcclusion(p, normals(p), 6.0, 1.5));
    cc += lc;
    cc *=0.5;
    return cc;
}

vec3 fog(vec3 col, vec3 p, vec3 ro, vec3 rd, vec3 ld, vec3 lc){
    float dist = length(p-ro);
    float sunAmount = max( dot( rd, ld ), 0.0 );
    float fogAmount = 1.0 - exp( -dist*0.03);
    vec3  fogColor = mix(FOG_COLOR, lc, pow(sunAmount, 4.0));
    return mix(col, fogColor, fogAmount);
}

//Enhanced sphere tracing algorithm introduced by Mercury
float march(vec3 ro, vec3 rd){
    float t = 0.0001;//EPSILON;
    float step = 0.0;

    float omega = 1.05;//muista testata eri arvoilla! [1,2]
    float prev_radius = 0.0;

    float candidate_t = t;
    float candidate_error = 1000.0;
    float sg = sgn(sdf(ro));

    vec3 p = vec3(0.0);

    for(int i = 0; i < STEPS; ++i){
        p = rd*t+ro;
        float sg_radius = sg*sdf(p);
        float radius = abs(sg_radius);
        step = sg_radius;
        bool fail = omega > 1. && (radius+prev_radius) < step;
        if(fail){
            step -= omega * step;
            omega = 1.;
        }
        else{
            step = sg_radius*omega;
        }
        prev_radius = radius;
        float error = radius/t;

        if(!fail && error < candidate_error){
            candidate_t = t;
            candidate_error = error;
        }

        if(!fail && error < PIXELR || t > FAR){
            break;
        }
        t += step;
    }
    //discontinuity reduction
    float er = candidate_error;
    for(int j = 0; j < 6; ++j){
        float radius = abs(sg*sdf(p));
        p += rd*(radius-er);
        t = length(p-ro);
        er = radius/t;

        if(er < candidate_error){
            candidate_t = t;
            candidate_error = er;
        }
    }
    if(t <= FAR || candidate_error <= PIXELR){
        t = candidate_t;
    }
    return t;
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 q = -1.0+2.0*uv;
    q.x *= resolution.x/resolution.y;
    
    vec3 ro = vec3(10.0*cos(time*0.1), 3.5+sin(time*0.05), 12.0*sin(time*0.1));
    vec3 rt = vec3(0.0, 2.5, 0.0);
    
    //vec3 ro = vec3(0.0, 2.0, time*0.5);
    //vec3 rt = vec3(0.0, 1.0, ro.z+8.0);
    
    vec3 z = normalize(rt-ro);
    vec3 x = normalize(cross(z, vec3(0.0, 1.0, 0.0)));
    vec3 y = normalize(cross(x, z));
    vec3 rd = normalize(mat3(x, y, z)*vec3(q, radians(90.0)));
    
    vec3 ld = (ro-rt)/distance(ro, rt);
    vec3 ld2 = (rt-vec3(0.0, -2.0, -8.0))/distance(vec3(0.0, -2.0, -8.0), rt);
    
    vec3 lcol = vec3(0.6, 0.6, 0.55);
    vec3 lcol2 = vec3(0.7, 0.7, 0.6);  
    vec3 col = FOG_COLOR;
    
    float t = march(ro, rd);
    vec3 p = rd*t+ro;
    
    if(t <= FAR){
        col = colorify(ld, p, lcol); +
            colorify(ld2, p, lcol2);
    }
    
    vec3 fg = fog(col, p, ro, rd, ld, lcol) +
        fog(col, p, ro, rd, ld2, lcol2);
    col = fg*0.5;
    
    col = pow(col, 1.0/vec3(2.2));
    
    glFragColor = vec4(col ,1.0);
}
