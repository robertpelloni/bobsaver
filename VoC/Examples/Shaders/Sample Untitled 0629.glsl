#version 420

// original https://www.shadertoy.com/view/7sXGD2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 50
#define MAX_DIST 80.
#define MIN_HIT 0.1
float map(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}
vec3 rotation(vec3 point, vec3 axis, float angle){ // https://www.shadertoy.com/view/Wtl3zN
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    mat4 rot= mat4(oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,0.0,0.0,1.0);
    return (rot*vec4(point,1.)).xyz;
}
mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}
// https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float dot2( in vec2 v ) { return dot(v,v); }
float dot2( in vec3 v ) { return dot(v,v); }
float ndot( in vec2 a, in vec2 b ) { return a.x*b.x - a.y*b.y; }

float sdOctahedron( vec3 p, float s)
{
  p = abs(p);
  return (p.x+p.y+p.z-s)*0.57735027;
}
float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}
float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}
vec3 opRep( in vec3 p, in vec3 c)
{
    vec3 q = mod(p+0.5*c,c)-0.5*c;
    return q;
}

vec2 random2(vec2 st){
    st = vec2( dot(st,vec2(127.1,311.7)),
              dot(st,vec2(269.5,183.3)) );
    return -1.0 + 2.0*fract(sin(st)*43758.5453123);
}
// Gradient Noise by Inigo Quilez - iq/2013
// https://www.shadertoy.com/view/XdXGW8
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( dot( random2(i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ),
                     dot( random2(i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( random2(i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ),
                     dot( random2(i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
}
float mod289(float x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 mod289(vec4 x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 perm(vec4 x){return mod289(((x * 34.0) + 1.0) * x);}

float noise3(vec3 p){
    vec3 a = floor(p);
    vec3 d = p - a;
    d = d * d * (3.0 - 2.0 * d);

    vec4 b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 k1 = perm(b.xyxy);
    vec4 k2 = perm(k1.xyxy + b.zzww);

    vec4 c = k2 + a.zzzz;
    vec4 k3 = perm(c);
    vec4 k4 = perm(c + 1.0);

    vec4 o1 = fract(k3 * (1.0 / 41.0));
    vec4 o2 = fract(k4 * (1.0 / 41.0));

    vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
}
// fog by inigo quilez
vec3 applyFog( in vec3  rgb,       // original color of the pixel
               in float distance ) // camera to point distance
{
    float b = 0.02;
    float fogAmount = 1.0 - exp( -distance*b );
    vec3  fogColor  = vec3(0.2);
    return mix( rgb, fogColor, fogAmount );
}
float getDist(vec3 p) {
    float dist = MAX_DIST; 
    float node = sdOctahedron( opRep( p-vec3(0., 0., 0.), vec3(10.)), 2.5 );
    dist = min( dist, node);
    
   
    
    vec3 pXpos = opRep( (p-vec3(5.,0.,0.)), vec3(10.));
    vec3 pYpos = opRep( (p-vec3(0.,5.,0.)), vec3(10.));
    vec3 pZpos = opRep( (p-vec3(0.,0.,5.)), vec3(10.));
    
    pXpos.yz *= rotate2d(p.x*0.5);
    pYpos.xz *= rotate2d(p.y*0.5);
    pZpos.xy *= rotate2d(p.z*0.5);
    
    float pipeX = sdBox( pXpos , vec3(4,0.5,0.5) );
    dist = min( dist, pipeX );
    float pipeY = sdBox( pYpos, vec3(0.5,4.,0.5) );
    dist = min( dist, pipeY );
    float pipeZ = sdBox( pZpos, vec3(0.5,0.5,4.) );
    dist = min( dist, pipeZ );
    
    return dist;
}
vec3 getNormal(vec3 p) {
    vec2 e = vec2(0.01, 0.);
    float d = getDist(p);
    vec3 n = d-vec3(getDist(p-e.xyy), getDist(p-e.yxy), getDist(p-e.yyx));
    return normalize(n);
}
float rayMarch(vec3 ro, vec3 rd) {

    float rayDist = 0.;
    for(int step = 0; step < MAX_STEPS; step++) {
        vec3 pos = ro + rd*rayDist;
        float distanceHit = getDist(pos);
        rayDist += distanceHit;
        if(distanceHit < MIN_HIT || abs(rayDist) > MAX_DIST) break;   
    }
    return rayDist;
}
vec3 getLight(vec3 p, vec3 sun) {
    
    vec3 n = getNormal(p);
    float lighting = dot(n, normalize(sun-p));
    lighting = clamp(lighting, 0., 1.);
    
    float d = rayMarch(p+n*MIN_HIT*1.1, normalize(sun-p));
    if(d < length(sun- p)) {
        lighting = lighting * 0.5;
    }
    

    float noiseVal = (noise3((mod(p+50., 100.))*10.)+0.5)*0.5+1.;
    vec3 brown = vec3(.4,.3,0.);
    
    return lighting*brown*noiseVal;
}
vec3 cameraPath(float t) {
    float x = sin(t*1.)*5.;
    float y = cos(t*1.)*5.;
    float z = t/3.1415926*20.+5.;
    return vec3(x,y,z);
}
// https://www.shadertoy.com/view/WlKBDw thank you!!
mat3 lookAt(in vec3 pos, in vec3 target) {
    vec3 f = normalize(target - pos);         // Forward
    vec3 r = normalize(vec3(-f.z, 0.0, f.x)); // Right
    vec3 u = cross(r, f);                     // Up
    return mat3(r, u, f);
}

void main(void)
{
    float zoom = map(mouse.y*resolution.xy.y/resolution.y,0.,1.,1.7, 30.);
    vec2 uv =  ( gl_FragCoord.xy - .5*resolution.xy ) / resolution.y;
    
    vec3 col = vec3(0.);
    
    
    vec3 rayOrigin = cameraPath(time);
    vec3 cameraPx = vec3(uv.x, uv.y, 1.);
    vec3 rayDir = normalize(cameraPx * lookAt(cameraPath(time), cameraPath(time+.5)));
    rayDir.y *= -1.;
    
    vec3 sun = vec3(0., 0., 0.);
    sun = rayOrigin;
    
    
    float d = rayMarch(rayOrigin, rayDir);
    if(d < MAX_DIST) {
        vec3 p = rayOrigin+rayDir*d;

        vec3 l = getLight(p, sun);
        col = l;
    }
    col = applyFog(col, d);
    // gamma correction
    col = vec3(col.x*col.x, col.y*col.y, col.z*col.z);
    glFragColor = vec4(col*2.,1.);
} 

