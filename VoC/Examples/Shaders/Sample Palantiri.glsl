#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wlf3Rs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat3 eyeMat = mat3(1.);

struct Sphere{ vec3 origin; float rad; };
struct Plane{ vec3 origin; vec3 normal; };
struct Ray{ vec3 origin, dir; };
struct HitRecord{ float t; vec3 p; vec3 normal; };
struct FingerParams{ vec4 a, b, c, d, e, quat, lengths; };

mat3 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, 0, s),
        vec3(0, 1, 0),
        vec3(-s, 0, c)
    );
}
    
bool sphere_hit(const in Sphere sphere, const in Ray inray, inout HitRecord rec) {
    vec3 oc = inray.origin - sphere.origin;
    float a = dot(inray.dir, inray.dir);
    float b = dot(oc, inray.dir);
    float c = dot(oc, oc) - sphere.rad*sphere.rad;
    float discriminant = b*b - a*c;
    if (discriminant >= 0.) {
        float temp = (-b - sqrt(discriminant))/a;
        
        rec.t = temp;
        rec.p = inray.origin + inray.dir * rec.t;
        rec.normal = (rec.p - sphere.origin) / sphere.rad;
        return true;
    }
    return false;
}

bool plane_hit(in Ray inray, in Plane plane, out HitRecord rec) {
    float denom = dot(plane.normal, inray.dir);
    if (denom > 1e-6) {
        vec3 p0l0 = plane.origin - inray.origin;
        float t = dot(p0l0, plane.normal) / denom;
        
        rec.t = t;
        rec.p = inray.origin + inray.dir * rec.t;
        rec.normal = -plane.normal;
        return true;
    }
    return false;
}

vec3 rayDirection(float fieldOfView, vec2 size) {
    vec2 xy = gl_FragCoord.xy - size / 2.;
    float z = size.y / tan(radians(fieldOfView) / 2.);
    return normalize(vec3(xy, -z));
}

mat4 viewMatrix(vec3 eye, vec3 center, vec3 up) {
    vec3 f = normalize(center - eye),
         s = normalize(cross(f, up)),
         u = cross(s, f);
    return mat4(vec4(s, 0.), vec4(u, 0.), vec4(-f, 0.), vec4(vec3(0.), 1.));
}

vec2 hash(vec2 p){
    p = mod(p, 4.); 
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

vec3 getVoronoi(vec2 x, float time){
    vec2 n = floor(x),
         f = fract(x),
         mr;
    float md=5.;
    for( int j=-1; j<=1; j++ ){
        for( int i=-1; i<=1; i++ ){
            vec2 g=vec2(float(i),float(j));
            vec2 o=0.5+0.5*sin(time + 6.2831*hash(n+g));
            vec2 r=g+o-f;
            float d=dot(r,r);
            if( d<md ) {md=d;mr=r;}
        }
    }
    return vec3(md,mr);
}

float hash(vec3 p){
    p  = fract( p*0.3183099+.1 );
    p *= 17.0;
    return fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
}

float noise(vec2 n) {
    const vec2 d = vec2(0.0, 1.0);
    vec2 b = floor(n);
    vec2 f = smoothstep(vec2(0.0), vec2(1.0), fract(n));
    return mix(mix(hash(b).x, hash(b + d.yx).x, f.x), mix(hash(b + d.xy).x, hash(b + d.yy).x, f.x), f.y);
}

float noise( in vec3 x ){
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    return mix(mix(mix( hash(p+vec3(0,0,0)), 
                        hash(p+vec3(1,0,0)),f.x),
                   mix( hash(p+vec3(0,1,0)), 
                        hash(p+vec3(1,1,0)),f.x),f.y),
               mix(mix( hash(p+vec3(0,0,1)), 
                        hash(p+vec3(1,0,1)),f.x),
                   mix( hash(p+vec3(0,1,1)), 
                        hash(p+vec3(1,1,1)),f.x),f.y),f.z);
}

const mat3 m = mat3( 0.00,  0.80,  0.60,
                    -0.80,  0.36, -0.48,
                    -0.60, -0.48,  0.64 );

float fbm(vec3 q){
    float f  = 0.5000*noise( q ); q = m*q*2.01;
          f += 0.2500*noise( q ); q = m*q*2.02;
          f += 0.1250*noise( q ); q = m*q*2.03;
          f += 0.0625*noise( q ); q = m*q*2.01;
    
    return f;
}

float OFFSET = .5, RATIO = 5., CRACK_depth = 3., CRACK_zebra_scale = 1.,
      CRACK_zebra_amp = .67, CRACK_profile = 1., CRACK_slope = 50., CRACK_width = .0;
vec3 hash3( uvec3 x ) {
#   define scramble  x = ( (x>>8U) ^ x.yzx ) * 1103515245U // GLIB-C const
    scramble; scramble; scramble; 
    return vec3(x) / float(0xffffffffU) + 1e-30;
}
#define hash22(p)  fract( 18.5453 * sin( p * mat2(127.1,311.7,269.5,183.3)) )
#define disp(p) ( -OFFSET + (1.+2.*OFFSET) * hash22(p) )

vec3 voronoiB( vec2 u ){
    vec2 iu = floor(u), C, P;
    float m = 1e9,d;
    for( int k=0; k < 9; k++ ) {
        vec2  p = iu + vec2(k%3-1,k/3-1),
              o = disp(p),
                r = p - u + o;
        d = dot(r,r);
        if( d < m ) m = d, C = p-iu, P = r;
    }
    m = 1e9;
    for( int k=0; k < 25; k++ ) {
        vec2 p = iu+C + vec2(k%5-2,k/5-2),
             o = disp(p),
             r = p-u + o;

        if( dot(P-r,P-r)>1e-5 )
        m = min( m, .5*dot( (P+r), normalize(r-P) ) );
    }
    return vec3( m, P+u );
}

#define rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
int MOD = 1;

#define hash21(p) fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453123)
float noise2(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p); f = f*f*(3.-2.*f);

    float v= mix( mix(hash21(i+vec2(0,0)),hash21(i+vec2(1,0)),f.x),
                  mix(hash21(i+vec2(0,1)),hash21(i+vec2(1,1)),f.x), f.y);
    return   MOD==0 ? v
           : MOD==1 ? 2.*v-1.
           : MOD==2 ? abs(2.*v-1.)
                    : 1.-abs(2.*v-1.);
}

#define noise22(p) vec2(noise2(p),noise2(p+17.7))
vec2 fbm22(vec2 p) {
    vec2 v = vec2(0);
    float a = .5;
    mat2 R = rot(.37);

    for (int i = 0; i < 6; i++, p*=2.,a/=2.) 
        p *= R,
        v += a * noise22(p);

    return v;
}

vec3 marble( vec2 U ){
    vec3 O;
    //U *= 4./resolution.y;
    vec2 I = floor(U/2.); 
    vec3 H0;
    
    for(float i=0.; i<CRACK_depth ; i++) {
        vec2  V =  U / vec2(RATIO,1),
              D = CRACK_zebra_amp * fbm22(U/CRACK_zebra_scale) * CRACK_zebra_scale;
        vec3  H = voronoiB( V + D ); if (i==0.) H0=H;
        float d = H.x;                                // distance to cracks
        d = min( 1., CRACK_slope * pow(max(0.,d-CRACK_width),CRACK_profile) );
        O += vec3(1.-d) / exp2(i);
        U *= 1.5 * rot(.37);
    }
    return O;
}

float cld(vec3 p, float time){
    float ang = atan(p.x, p.z);
    float f = getVoronoi(vec2(ang + p.y * 2., p.y - time * 2.) * 4./6.2831, time * .1).x;
    f = smoothstep(.1, .15, f);
    f *= smoothstep(.25, .5, fbm(p * 6. * rotateY(p.y * 2.) - vec3(0., time * 5., 0.)));
    return f;
}

vec2 polarMap(vec2 uv, float inner) {
    float px = atan(uv.y, uv.x) / 6.283 + .5;
    float py = (length(uv) * (1.0 + inner * .75) - inner) * 2.0;
    
    return vec2(px, py);
}

float fire(vec2 n) {
    return noise(n) + noise(n * 2.1) * .6 + noise(n * 5.4) * .42;
}

float shade(vec2 uv, float t) {
    float q = fire(uv - t * .013) / 2.0;
    vec2 r = vec2(fire(uv + q / 2.0 + t - uv.x - uv.y), fire(uv + q - t));
    return pow((r.y + r.y) * max(.0, uv.y) + .1, 4.0);
}

vec3 color(float grad, float power) {
    float m2 = .125;
    grad =sqrt( grad);
    vec3 color = vec3(1.0 / (pow(vec3(0.5, 0.0, .1) + 2.61, vec3(2.0))));
    vec3 color2 = color;
    grad = pow(grad, power);
    color = vec3( 1., 1. - grad * .9, 1.  - grad * 1.4) / grad;
    return color / (m2 + max(vec3(0), color));
}

vec3 eyeClr( vec2 uv, float t ) {
    vec2 muv = polarMap(uv, 2.5);
    muv.y = abs(muv.y);
    muv.x *= 35.;
    vec3 outer = clamp(color(shade(muv, t), 1.5 + step(.85, length(uv)) * 5.), 0., 1.);
    
    float pupil = pow(max(0., cos(uv.y * 3.14)), .75) * .1;
    pupil = smoothstep(pupil, pupil + .05, abs(uv.x));
    
    muv = polarMap(uv * vec2(2.5, 1.), .5);
    muv.x *= 15.;
    vec3 inner = clamp(color(shade(muv, t) - (1. - pupil) * 20., 4.), 0., 1.);
    return clamp(inner+outer, 0., 1.);
}

vec3 floorClr(vec3 pos, vec3 nor, vec3 rd, bool reflectEye ){
    vec3 albedo = pow( marble(pos.xz), vec3( 2.2 ) );
    float roughness = .7 - clamp( 0.5 - dot( albedo, albedo ), 0.05, 0.95 );
    
    vec3 lColor = vec3(0.);
    vec3 reflected = reflect(rd, nor);
    HitRecord rec;
    if(reflectEye && plane_hit(Ray(pos, reflected), Plane(vec3(0.), normalize(-pos)), rec)
       && distance(rec.p, vec3(0.)) < 3.){
       lColor = eyeClr((rec.p * eyeMat).xy, time) * (1. - roughness);
    }
    float cloud = 1.;
    if(sphere_hit(Sphere(vec3(0.), 1.), Ray(pos, normalize(vec3(0.) - pos)), rec))
        cloud = 1. - pow(cld(rec.p, time), .5);
    return clamp(1. - length(pos.xz) * .15, 0., 1.) * cloud * (albedo + lColor);
}

vec3 handClr( vec3 pos, vec3 nor, vec3 rd ){
    vec3 albedo        = clamp(vec3(dot(nor, rd)), 0., 1.);
    albedo *= smoothstep(1.8, 1.6, length(pos));
    HitRecord rec;
    if(sphere_hit(Sphere(vec3(0.), 1.), Ray(pos, normalize(vec3(0.) - pos)), rec))
        albedo *= 1. - pow(cld(rec.p, time), .5);
    return pow( albedo, vec3( 1.0 / 2.2 ) );
}

const float epsilon = 0.01;
const float pi = 3.14159265359;
const float halfpi = 1.57079632679;
const float twopi = 6.28318530718;

float saturate(float f){
    return clamp(f, 0.0, 1.0);
}

vec4 RotationToQuaternion(vec3 axis, float angle){
    axis = normalize(axis);
    float half_angle = angle * halfpi / 180.0;
    vec2 s = sin(vec2(half_angle, half_angle + halfpi));
    return vec4(axis * s.x, s.y);
}

vec3 Rotate(vec3 pos, vec4 quaternion){
    return pos + 2.0 * cross(quaternion.xyz, cross(quaternion.xyz, pos) + quaternion.w * pos);
}

//Distance Field function by iq :
//http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdSphere( vec3 p, float s ){
  return length(p)-s;
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r1, float r2, float m){
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - mix(r1, r2, clamp(length(pa) / m, 0.0, 1.0));
}

float box(vec3 pos, vec3 size){
    return length(max(abs(pos) - size, 0.0));
}

float smin(float a, float b, float k){
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

//taken from shane's desert canyon, originaly a modification of the smin function by iq
//https://www.shadertoy.com/view/Xs33Df
float smax(float a, float b, float s)
{   
    float h = clamp( 0.5 + 0.5*(a-b)/s, 0., 1.);
    return mix(b, a, h) + h*(1.0-h)*s;
}

float finger(vec3 pos, FingerParams fp)
{ 
    pos = Rotate(pos, fp.quat);
    
    float s1 = sdCapsule(pos, fp.a.xyz, fp.b.xyz, fp.a.w, fp.b.w, fp.lengths.x);
    float s2 = sdCapsule(pos, fp.b.xyz, fp.c.xyz, fp.b.w, fp.c.w, fp.lengths.y);
    float s3 = sdCapsule(pos, fp.c.xyz, fp.d.xyz, fp.c.w, fp.d.w, fp.lengths.z);
    float s4 = sdCapsule(pos, fp.d.xyz, fp.e.xyz, fp.d.w, fp.e.w, fp.lengths.w);
        
    return smin(smin(smin(s1, s2, 0.1), s3, 0.075), s4, 0.05);
}
  
#define f1A vec4(0,0,0,0.1)
#define f1B vec4(0,0,3,0.425)
#define f1C vec4(0.07961927,-0.3662486,3.796193,0.34)
#define f1D vec4(0.1336378,-0.9874623,4.336379,0.306)
#define f1E vec4(0.1589203,-1.714333,4.589203,0.29)
#define f1Quat vec4(-0.01375867,-0.1100694,0.06879336,0.9914449)
#define f1Lengths vec4(3,0.88,0.8250002,0.7699998)

#define f2A vec4(0,0,0,0.1)
#define f2B vec4(0,0,3,0.46875)
#define f2C vec4(0,-0.4651021,3.930204,0.375)
#define f2D vec4(0,-1.154531,4.619634,0.3375)
#define f2E vec4(0,-2.007883,4.93569,0.25)
#define f2Quat vec4(-0.002759293,-0.02207434,0.01379647,0.9996573)
#define f2Lengths vec4(3,1.04,0.9750001,0.91)

#define f3A vec4(0,0,0,0.1)
#define f3B vec4(0,0,3,0.4125)
#define f3C vec4(0,-0.4090538,3.77915,0.33)
#define f3D vec4(0,-1.006468,4.348116,0.297)
#define f3E vec4(0,-1.726023,4.622232,0.22)
#define f3Quat vec4(0.009187022,0.07349618,-0.04593511,0.9961947)
#define f3Lengths vec4(3,0.8800001,0.8250002,0.77)

#define f4A vec4(0.2,-0.5,0.4,0.9)
#define f4B vec4(0.2,-0.5,2.7,0.375)
#define f4C vec4(0.01168381,-0.7981673,3.327721,0.3)
#define f4D vec4(-0.1317746,-1.252452,3.805915,0.27)
#define f4E vec4(-0.2189538,-1.804587,4.096512,0.2)
#define f4Quat vec4(0.05904933,0.2361973,-0.2952467,0.9238795)
#define f4Lengths vec4(2.3,0.7199999,0.675,0.63)

#define f5A vec4(-0.1,0,0,1.25)
#define f5B vec4(-0.1,0,1,0.64)
#define f5C vec4(-0.1,-0.3469815,1.630875,0.44)
#define f5D vec4(-0.1,-0.846441,2.08493,0.36)
#define f5E vec4(-0.1,-1.419972,2.345625,0.28)
#define f5Quat vec4(0.112371,-0.7491399,0.5993119,0.2588191)
#define f5Lengths vec4(1,0.72,0.6750001,0.6299999)

#define quat0 vec4(0.7071068, 0.0, 0.0, 0.7071068) //RotationToQuaternion(vec3(1.0, 0.0, 0.0), 90.0)
#define quat1 vec4(0.3, 0.0, 0.0, 0.3) //RotationToQuaternion(vec3(1.0, 0.0, 0.0), 40.0)

vec2 distfunc(vec3 pos){ 
    vec3 rpos = pos;
    rpos += vec3(-.35, -1.25, 1.5);
    rpos *= 3.;
    float arm = sdCapsule(rpos * vec3(1.0, 1.2, 1.0), vec3(-0.2, 0.0, 0.0), vec3(0.0, 3.0, -3.5), 0.7, 1.5, 5.0);
    rpos = Rotate(rpos, quat1);
    vec3 p1 = rpos;
    vec3 p2 = rpos + vec3(0.4, -0.1, 0.0); 
    vec3 p3 = rpos + vec3(0.8, 0.0, 0.0);  
    vec3 p4 = rpos + vec3(1.0, 0.1, 0.0); 
    vec3 p5 = rpos + vec3(-0.3, 0.6, -0.7);

    FingerParams fingerParams1;
    fingerParams1.a = f1A;
    fingerParams1.b = f1B;
    fingerParams1.c = f1C;
    fingerParams1.d = f1D;
    fingerParams1.e = f1E;
    fingerParams1.quat = f1Quat;
    fingerParams1.lengths = f1Lengths;
        
    float f1 = finger(p1, fingerParams1);
    
    FingerParams fingerParams2;
    fingerParams2.a = f2A;
    fingerParams2.b = f2B;
    fingerParams2.c = f2C;
    fingerParams2.d = f2D;
    fingerParams2.e = f2E;
    fingerParams2.quat = f2Quat;
    fingerParams2.lengths = f2Lengths;
    
    float f2 = finger(p2, fingerParams2);
    
    FingerParams fingerParams3;
    fingerParams3.a = f3A;
    fingerParams3.b = f3B;
    fingerParams3.c = f3C;
    fingerParams3.d = f3D;
    fingerParams3.e = f3E;
    fingerParams3.quat = f3Quat;
    fingerParams3.lengths = f3Lengths;
    
    float f3 = finger(p3, fingerParams3);
        
    FingerParams fingerParams4;
    fingerParams4.a = f4A;
    fingerParams4.b = f4B;
    fingerParams4.c = f4C;
    fingerParams4.d = f4D;
    fingerParams4.e = f4E;
    fingerParams4.quat = f4Quat;
    fingerParams4.lengths = f4Lengths;
    
    float f4 = finger(p4, fingerParams4);
    
    FingerParams fingerParams5;
    fingerParams5.a = f5A;
    fingerParams5.b = f5B;
    fingerParams5.c = f5C;
    fingerParams5.d = f5D;
    fingerParams5.e = f5E;
    fingerParams5.quat = f5Quat;
    fingerParams5.lengths = f5Lengths;
    
    float f5 = finger(p5, fingerParams5);
    float fingers = min(min(min(f1, f2), f3), f4);
    vec3 mainPos = rpos * vec3(1.0, 1.4, 1.0);
    float main = sdCapsule(mainPos, vec3(0.0, 0.0, 0.0), vec3(0.15, -0.5, 2.25), 0.5, 1.0, 2.25);
    main = smin(main, sdCapsule(mainPos, vec3(-0.5, 0.0, 1.0), vec3(-1.0, -0.25, 2.25), 0.5, 1.0, 2.5), 0.5);
    main = smin(main, sdSphere(rpos + vec3(-0.2, 0.7, -0.3), 0.7), 0.1);
    float hand = smin(smin(smin(main, fingers, 0.2), f5, 0.9), arm, 0.5);
    float d = 0.0;//textureLod(iChannel2, (pos.xy - pos.z*0.2) * vec2(0.6, 0.4) + vec2(0.1, 0.0), 0.0).x;
    hand += d * 0.135;
    return vec2(hand / 3., 0.5);
}

vec4 marchHand(vec3 rayDir, vec3 cameraOrigin){
    const int maxItter = 100;
    const float maxDist = 30.0;
    
    float totalDist = 0.0;
    vec3 pos = cameraOrigin;
    vec2 dist = vec2(epsilon, 1.0);
    float accum = 0.0;
    
    for(int i = 0; i < maxItter; i++){
           dist = distfunc(pos);
        
        totalDist += dist.x; 
        pos += dist.x * rayDir;
        accum += smoothstep(2.0, 0.0, dist.y);
        
        if(dist.x < epsilon || totalDist > maxDist)
        {
            break;
        }
    }
    
    return vec4(dist.x, totalDist, saturate(accum / 100.0), dist.y);
}

vec3 calculateNormals(vec3 pos){
    vec2 eps = vec2(0.0, epsilon);
    vec3 n = normalize(vec3(
    distfunc(pos + eps.yxx).x - distfunc(pos - eps.yxx).x,
    distfunc(pos + eps.xyx).x - distfunc(pos - eps.xyx).x,
    distfunc(pos + eps.xxy).x - distfunc(pos - eps.xxy).x));
    return n;
}

vec3 makeColor(in Ray inray){
    HitRecord rec;
    vec3 clr = vec3(0.);
    float minDst = 100000.;
    if(plane_hit(inray, Plane(vec3(0., -1., 0.), vec3(0., -1., 0.)), rec)){
        clr = floorClr( rec.p, vec3(0., 1., 0.), inray.dir, true );
        minDst = rec.t;
    }
    
    vec3 sphereCntr = vec3(0.);
    if(plane_hit(inray, Plane(sphereCntr, normalize(sphereCntr - inray.origin)), rec)
       && distance(rec.p, vec3(0.)) < 1. && rec.t < minDst){
        clr = eyeClr((rec.p * eyeMat).xy, time);
        minDst = rec.t;
    }
    
    if(sphere_hit(Sphere(sphereCntr, 1.), inray, rec) && rec.t < minDst){
        clr = mix(clr, vec3(0.), cld(rec.p, time));
        vec3 rr = reflect(inray.dir, rec.normal);
        if(rr.y < 0. && plane_hit(Ray(rec.p, rr), Plane(vec3(0., -1., 0.), vec3(0., -1., 0.)), rec))
            clr += .5 * floorClr( rec.p, vec3(0., 1., 0.), inray.dir, false );

        vec4 dist = marchHand(rr, rec.p);
        if(dist.x < epsilon){
            vec3 pos = rec.p + dist.y * rr;
            vec3 nrm = calculateNormals(pos);
            clr += .5 * handClr(pos, nrm, normalize(-pos));
        }
        minDst = rec.t;
    }
    
    vec4 dist = marchHand(inray.dir, inray.origin);
    if(dist.x < epsilon && dist.y < minDst){
        vec3 pos = inray.origin + dist.y * inray.dir;
        vec3 nrm = calculateNormals(pos);
        
        clr = handClr(pos, nrm, normalize(-pos));
    }
    
    return clr;
}

vec3 trace(vec2 gl_FragCoord, vec2 res){
    vec3 viewDir = rayDirection(60., res.xy);
    float angle = time*.5;// + mouse*resolution.xy.x/resolution.x * 6.283;
    vec3 origin = vec3(5. * sin(angle), (sin(angle) + 1.) * 1., 5. * cos(angle));
    eyeMat *= rotateY(-atan(origin.x, origin.z));
    mat4 viewToWorld = viewMatrix(origin, vec3(0.), vec3(0., 1., 0.));
    vec3 dir = (viewToWorld * vec4(viewDir, 1.0)).xyz;
    return makeColor(Ray(origin, dir));
}

void main(void) {
    vec2 uv = (2.*gl_FragCoord.xy - resolution.xy) / resolution.y;
    
    vec3 col = trace(gl_FragCoord.xy, resolution.xy);
    glFragColor = vec4(col, 1.);
}
